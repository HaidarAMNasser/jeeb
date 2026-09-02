import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, QueryRunner, In } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { Offer } from '../../../database/entities/offer.entity';
import {
  Invoice,
  InvoiceType,
} from '../../../database/entities/invoice.entity';
import { CreateOrderDto } from '../dto/create-order.dto';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { CouponsService } from '../../coupons/coupons.service';
import { DiscountType } from '../../../common/enums/discount-type.enum';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  OrderCalculationResult,
  FinalAmountsResult,
  OrderData,
  OrderItemDto,
  DeliveryCoordinates,
  SimpleOfferDto,
  OfferData,
} from '../interfaces/order-creation.interfaces';

const ORDER_TIMEOUT_MINUTES = 120;
const DELIVERY_DEADLINE_MINUTES = 45;
const DEFAULT_CURRENCY = 'SAR';
const DEFAULT_EXCHANGE_RATE = 1;
const DEFAULT_TAX = 0;

interface OrderPreview {
  ownerId: number;
  itemsCount?: number;
  deliveryCoordinates?: DeliveryCoordinates;
}

@Injectable()
export class OrderCreationService {
  private readonly logger = new Logger(OrderCreationService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Offer)
    private readonly offerRepo: Repository<Offer>,
    @InjectRepository(Invoice)
    private readonly invoiceRepo: Repository<Invoice>,
    private readonly couponsService: CouponsService,
    private readonly dataSource: DataSource,
    @InjectQueue('orders') private readonly ordersQueue: Queue,
  ) {}

  async create(
    createOrderDto: CreateOrderDto,
    userId: number,
  ): Promise<{
    order: Order;
    priceBeforeDiscount: number;
    priceAfterProductDiscount: number;
  }> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    let orderData: OrderData | undefined;
    let calculationResult: OrderCalculationResult;
    try {
      orderData = this.extractOrderData(createOrderDto);

      // Validate and process order components
      // Validate owner exists
      const validationResult = await this.validateProductsAndCalculate(
        orderData.items,
        orderData.ownerId,
        orderData.offers,
      );

      const finalAmounts = this.calculateFinalAmounts(
        createOrderDto,
        validationResult.subtotal,
        validationResult.productLevelDiscountTotal,
        validationResult.offerDiscountTotal,
      );

      this.validateDeliveryCoordinates(orderData.deliveryCoordinates);

      // Create and save order
      const order = this.buildOrderEntity(
        createOrderDto,
        userId,
        finalAmounts.total,
        finalAmounts.totalDiscount,
        finalAmounts.deliveryFee,
        orderData.deliveryCoordinates,
      );

      const savedOrder = await queryRunner.manager.save(order);

      // Save order items and deduct stock
      await this.saveOrderItemsAndDeductStock(
        queryRunner,
        validationResult.orderItems,
        savedOrder,
      );

      await this.createInvoice(queryRunner, savedOrder, finalAmounts.total);

      await queryRunner.commitTransaction();
      await this.scheduleOrderTimeout(savedOrder.id);

      const priceBeforeDiscount = validationResult.subtotal;
      const priceAfterProductDiscount =
        validationResult.subtotal - validationResult.productLevelDiscountTotal;

      return {
        order: savedOrder,
        priceBeforeDiscount,
        priceAfterProductDiscount,
      };
    } catch (error) {
      let orderPreview: OrderPreview | undefined;
      if (orderData) {
        orderPreview = {
          ownerId: orderData.ownerId,
          itemsCount: orderData.items?.length,
          deliveryCoordinates: orderData.deliveryCoordinates,
        };
      }
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      const errorStack = error instanceof Error ? error.stack : undefined;

      this.logger.error('Order creation failed', {
        error: errorStack || errorMessage,
        orderPreview,
      });

      await queryRunner.rollbackTransaction();

      if (
        error instanceof BadRequestException ||
        error instanceof NotFoundException ||
        error instanceof ForbiddenException
      ) {
        throw error;
      }

      this.logger.error(
        'Order creation failed due to unexpected error',
        error instanceof Error ? error.stack : String(error),
      );
      throw new BadRequestException(
        'Unable to create order due to an internal error',
      );
    } finally {
      await queryRunner.release();
    }
  }

  // Helper methods for cleaner code organization
  private extractOrderData(createOrderDto: CreateOrderDto): OrderData {
    const { items, ownerId, deliveryCoordinates, offers } = createOrderDto;
    return { items, ownerId, deliveryCoordinates, offers };
  }

  private buildOrderEntity(
    createOrderDto: CreateOrderDto,
    userId: number,
    total: number,
    totalDiscount: number,
    deliveryFee: number,
    deliveryCoordinates: DeliveryCoordinates,
  ): Order {
    return this.orderRepo.create({
      customerId: userId,
      ownerId: createOrderDto.ownerId,
      customerName: createOrderDto.customerName || null,
      phone: createOrderDto.phone || null,
      status: OrderStatus.PENDING,
      paymentMethod: createOrderDto.paymentMethod,
      totalAmount: total,
      discountAmount: totalDiscount,
      deliveryFee,
      tipAmount: Math.round(createOrderDto.tipAmount || 0),
      deliveryDeadline: new Date(
        Date.now() + DELIVERY_DEADLINE_MINUTES * 60 * 1000,
      ),
      deliveryCoordinates,
      currencyCode: DEFAULT_CURRENCY,
      exchangeRate: DEFAULT_EXCHANGE_RATE,
    });
  }

  private async validateProductsAndCalculate(
    items: OrderItemDto[] | undefined,
    ownerId: number,
    offers?: SimpleOfferDto[],
  ): Promise<{
    orderItems: OrderItem[];
    subtotal: number;
    productLevelDiscountTotal: number;
    offerDiscountTotal: number;
    offersData: OfferData[];
  }> {
    let subtotal = 0;
    let productLevelDiscountTotal = 0;
    let offerDiscountTotal = 0;
    const orderItems: OrderItem[] = [];
    const offersData: OfferData[] = [];

    // Process offers
    for (const offerInput of offers || []) {
      const offer = await this.offerRepo.findOne({
        where: { id: offerInput.offerId },
        relations: ['offerProducts', 'offerProducts.product'],
      });

      if (!offer) {
        throw new NotFoundException(
          `Offer with id ${offerInput.offerId} not found`,
        );
      }

      if (!offer.isActive) {
        throw new BadRequestException(`Offer ${offer.name} is not active`);
      }

      if (offer.merchantId !== ownerId) {
        throw new BadRequestException(
          `Offer ${offer.name} does not belong to merchant ${ownerId}`,
        );
      }

      let offerSubtotal = 0;
      const offerItemsData: any[] = [];

      // Process each product in the offer
      for (const offerProduct of offer.offerProducts || []) {
        const product = offerProduct.product;
        if (!product) continue;

        if (!product.isAvailable) {
          throw new BadRequestException(
            `Product ${product.name} in offer ${offer.name} is not available`,
          );
        }

        const quantity = offerInput.quantity;
        if (product.hasStock) {
          if (
            product.stockQuantity === null ||
            product.stockQuantity < quantity
          ) {
            throw new BadRequestException(
              `Insufficient stock for product ${product.name} in offer ${offer.name}. Available: ${product.stockQuantity ?? 0}, Requested: ${quantity}`,
            );
          }
        }

        const itemTotal = Math.round(product.price * quantity);
        offerSubtotal += itemTotal;

        const orderItem = this.orderItemRepo.create({
          productId: product.id,
          productName: product.name,
          quantity,
          originalUnitPrice: Math.round(product.price),
          unitPrice: Math.round(product.price),
          totalPrice: itemTotal,
          offerId: offer.id,
        });
        orderItems.push(orderItem);

        offerItemsData.push({
          product,
          quantity,
          unitPrice: product.price,
          totalPrice: itemTotal,
        });
      }

      subtotal += offerSubtotal;

      // Calculate offer discount (based on the offer's discountValue)
      let discountAmount = 0;
      if (offer.discountType === DiscountType.PERCENTAGE) {
        discountAmount = Math.floor(
          (offerSubtotal * offer.discountValue) / 100,
        );
      } else if (offer.discountType === DiscountType.FIXED) {
        discountAmount = Math.min(offer.discountValue, offerSubtotal);
      }
      offerDiscountTotal += discountAmount;

      offersData.push({
        offer,
        quantity: offerInput.quantity,
        items: offerItemsData,
        totalPrice: offerSubtotal,
        discountAmount,
      });
    }

    // Process regular items
    for (const item of items || []) {
      const product = await this.productRepo.findOne({
        where: { id: item.productId },
      });

      if (!product) {
        throw new NotFoundException(
          `Product with id ${item.productId} not found`,
        );
      }

      if (product.merchantId !== ownerId) {
        throw new BadRequestException(
          `Product ${product.name} (id: ${item.productId}) does not belong to merchant ${ownerId}`,
        );
      }

      if (!product.isAvailable) {
        throw new BadRequestException(
          `Product ${product.name} is not available`,
        );
      }

      if (product.hasStock) {
        if (
          product.stockQuantity === null ||
          product.stockQuantity < item.quantity
        ) {
          throw new BadRequestException(
            `Insufficient stock for product ${product.name}. Available: ${product.stockQuantity ?? 0}, Requested: ${item.quantity}`,
          );
        }
      }

      const itemPrice = product.price;
      const itemTotal = Math.round(itemPrice * item.quantity);
      subtotal += itemTotal;

      const totalItemDiscount = this.calculateProductDiscount(
        product,
        itemPrice,
        item.quantity,
      );
      productLevelDiscountTotal += totalItemDiscount;

      const orderItem = this.orderItemRepo.create({
        productId: product.id,
        productName: product.name,
        quantity: item.quantity,
        originalUnitPrice: Math.round(product.price),
        unitPrice: Math.round(itemPrice),
        totalPrice: itemTotal,
      });
      orderItems.push(orderItem);
    }

    return {
      orderItems,
      subtotal,
      productLevelDiscountTotal,
      offerDiscountTotal,
      offersData,
    };
  }

  private calculateProductDiscount(
    product: Product,
    itemPrice: number,
    quantity: number,
  ): number {
    let bestItemDiscount = 0;
    if (product.discount && product.discount > 0) {
      let discountValue = 0;
      if (product.discountType === DiscountType.PERCENTAGE) {
        discountValue = (itemPrice * product.discount) / 100;
      } else if (product.discountType === DiscountType.FIXED) {
        discountValue = product.discount;
      }
      bestItemDiscount = Math.min(discountValue, itemPrice);
    }

    return bestItemDiscount * quantity;
  }

  private calculateFinalAmounts(
    createOrderDto: CreateOrderDto,
    subtotal: number,
    productLevelDiscountTotal: number,
    offerDiscountTotal: number,
  ): FinalAmountsResult {
    const totalDiscount = productLevelDiscountTotal + offerDiscountTotal;
    const deliveryFee = 0;
    const tax = DEFAULT_TAX;
    const total = Math.round(
      subtotal -
        productLevelDiscountTotal -
        offerDiscountTotal +
        deliveryFee +
        tax,
    );

    return { total, totalDiscount, deliveryFee };
  }

  private validateDeliveryCoordinates(
    deliveryCoordinates: DeliveryCoordinates,
  ): void {
    if (
      !deliveryCoordinates ||
      deliveryCoordinates.latitude == null ||
      deliveryCoordinates.longitude == null
    ) {
      throw new BadRequestException(
        'Delivery coordinates are required: latitude and longitude must be provided',
      );
    }
  }

  private async saveOrderItemsAndDeductStock(
    queryRunner: QueryRunner,
    orderItems: OrderItem[],
    savedOrder: Order,
  ): Promise<void> {
    for (const item of orderItems) {
      item.orderId = savedOrder.id;
      await queryRunner.manager.save(item);

      // Deduct stock from product
      await queryRunner.manager.decrement(
        Product,
        { id: item.productId },
        'stockQuantity',
        item.quantity,
      );
    }
  }

  private async createInvoice(
    queryRunner: QueryRunner,
    savedOrder: Order,
    total: number,
  ): Promise<void> {
    const invoice = this.invoiceRepo.create({
      orderId: savedOrder.id,
      amount: total,
      status: 'PENDING',
      type: InvoiceType.CUSTOMER,
    });
    await queryRunner.manager.save(invoice);
  }

  private async scheduleOrderTimeout(orderId: number): Promise<void> {
    try {
      await this.ordersQueue.add(
        'order-timeout',
        { orderId },
        {
          delay: ORDER_TIMEOUT_MINUTES * 60 * 1000,
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 2000,
          },
        },
      );
    } catch (error) {
      this.logger.error(
        `Failed to schedule timeout for order ${orderId}`,
        error instanceof Error ? error.stack : error,
      );
    }
  }
}
