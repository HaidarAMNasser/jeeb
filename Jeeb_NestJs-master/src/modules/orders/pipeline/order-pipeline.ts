import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { Offer } from '../../../database/entities/offer.entity';
import { User } from '../../../database/entities/user.entity';
import {
  Invoice,
  InvoiceType,
} from '../../../database/entities/invoice.entity';
import { CreateOrderDto } from '../dto/create-order.dto';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { CouponsService } from '../../coupons/coupons.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { SettingsService } from '../../settings/settings.service';
import { Area } from '../../../database/entities/area.entity';
import { DiscountType } from '../../../common/enums/discount-type.enum';
import {
  OrderPipelineContext,
  OrderPipelineResult,
  OrderPipelineStage,
} from './order-pipeline.interfaces';
import {
  ErrorCodes,
  getErrorMessage,
} from '../../../common/constants/error-codes';

const ORDER_TIMEOUT_MINUTES = 120;
const DELIVERY_DEADLINE_MINUTES = 45;
const DEFAULT_CURRENCY = 'SAR';
const DEFAULT_EXCHANGE_RATE = 1;
const DEFAULT_TAX = 0;
const DEFAULT_DELIVERY_TIP_PER_KM = 500;
const DEFAULT_DELIVERY_COMMISSION_RATE = 10.0;

@Injectable()
export class OrderPipeline {
  private readonly logger = new Logger(OrderPipeline.name);
  private stages: OrderPipelineStage[] = [];
  private tipPerKilometer: number = DEFAULT_DELIVERY_TIP_PER_KM;
  private deliveryCommissionRate: number = DEFAULT_DELIVERY_COMMISSION_RATE;

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Invoice)
    private readonly invoiceRepo: Repository<Invoice>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly couponsService: CouponsService,
    private readonly settingsService: SettingsService,
    private readonly dataSource: DataSource,
    @InjectQueue('orders') private readonly ordersQueue: Queue,
    private readonly firebaseService: FirebaseService,
  ) {
    this.initializeSettings();
    this.initializeStages();
  }

  private async initializeSettings(): Promise<void> {
    try {
      const tipSetting = await this.settingsService.getSettingByKey(
        'deliveryTipPerKilometer',
      );
      if (tipSetting && tipSetting.value) {
        this.tipPerKilometer = Number(tipSetting.value);
      }

      const commissionSetting = await this.settingsService.getSettingByKey(
        'deliveryCommissionRate',
      );
      if (commissionSetting && commissionSetting.value) {
        this.deliveryCommissionRate = Number(commissionSetting.value);
      } else {
        const productCommissionSetting =
          await this.settingsService.getSettingByKey(
            'defaultProductCommissionRate',
          );
        if (productCommissionSetting && productCommissionSetting.value) {
          this.deliveryCommissionRate = Number(productCommissionSetting.value);
        }
      }

      this.logger.log(
        `Delivery settings loaded: tipPerKilometer=${this.tipPerKilometer}, commissionRate=${this.deliveryCommissionRate}`,
      );
    } catch (error) {
      this.logger.warn('Could not load delivery settings, using defaults');
    }
  }

  private initializeStages(): void {
    this.stages = [
      new ValidationStage(this),
      new ProductValidationStage(this),
      new OfferValidationStage(this),
      new PriceCalculationStage(this),
      new OrderCreationStage(this),
    ];
  }

  async execute(
    createOrderDto: CreateOrderDto,
    userId: number,
  ): Promise<OrderPipelineResult> {
    const context: OrderPipelineContext = {
      userId,
      ownerId: createOrderDto.ownerId,
      items: createOrderDto.items,
      offers: createOrderDto.offers,
      deliveryCoordinates: createOrderDto.deliveryCoordinates,
      paymentMethod: createOrderDto.paymentMethod,
      deliveryFee: 0,
      tipAmount: Math.round(createOrderDto.tipAmount || 0),
      platformCommission: 0,
      cityId: createOrderDto.cityId,
      areaId: createOrderDto.areaId,
      customerName: createOrderDto.customerName,
      phone: createOrderDto.phone,
    };

    for (const stage of this.stages) {
      this.logger.debug(`Executing stage: ${stage.name}`);
      const result = await stage.execute(context);

      if (!result.success) {
        this.logger.warn(`Stage ${stage.name} failed: ${result.error}`);
        return result;
      }

      Object.assign(context, result.data);
    }

    return {
      success: true,
      data: context,
    };
  }

  getProductRepository(): Repository<Product> {
    return this.productRepo;
  }

  getOfferRepository(): Repository<Offer> {
    // We need to import Offer entity and get repository
    // For simplicity, we can get from dataSource
    return this.dataSource.getRepository(Offer);
  }

  getCouponsService(): CouponsService {
    return this.couponsService;
  }

  getOrdersQueue(): Queue {
    return this.ordersQueue;
  }

  async scheduleOrderTimeout(orderId: number): Promise<void> {
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
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  async calculateDeliveryFee(areaId: number): Promise<{
    deliveryFee: number;
    platformCommission: number;
  }> {
    const area = await this.dataSource.getRepository(Area).findOne({
      where: { id: areaId },
    });

    if (!area) {
      throw new NotFoundException(`Area with ID ${areaId} not found`);
    }

    const deliveryFee = Math.round(Number(area.price));
    const platformCommission = Math.round(
      (deliveryFee * this.deliveryCommissionRate) / 100,
    );

    return {
      deliveryFee,
      platformCommission,
    };
  }

  private calculateHaversineDistance(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
  ): number {
    const R = 6371000;
    const dLat = this.toRad(lat2 - lat1);
    const dLng = this.toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  getTipPerKilometer(): number {
    return this.tipPerKilometer;
  }

  getDeliveryCommissionRate(): number {
    return this.deliveryCommissionRate;
  }
}

class ValidationStage implements OrderPipelineStage {
  name = 'Validation';
  constructor(private pipeline: OrderPipeline) {}

  async execute(context: OrderPipelineContext): Promise<OrderPipelineResult> {
    try {
      if (!context.ownerId || context.ownerId <= 0) {
        return {
          success: false,
          error: getErrorMessage('OWNER_ID_REQUIRED'),
          stage: this.name,
        };
      }

      const hasItems = context.items && context.items.length > 0;
      const hasOffers = context.offers && context.offers.length > 0;

      if (!hasItems && !hasOffers) {
        return {
          success: false,
          error: getErrorMessage('EMPTY_ORDER_ITEMS'),
          stage: this.name,
        };
      }

      for (const item of context.items || []) {
        if (!item.productId || item.productId <= 0) {
          return {
            success: false,
            error: getErrorMessage('INVALID_PRODUCT_ID'),
            stage: this.name,
          };
        }
        if (!item.quantity || item.quantity < 1) {
          return {
            success: false,
            error: getErrorMessage('INVALID_QUANTITY'),
            stage: this.name,
          };
        }
      }

      for (const offer of context.offers || []) {
        if (!offer.offerId || offer.offerId <= 0) {
          return {
            success: false,
            error: getErrorMessage('INVALID_OFFER_ID'),
            stage: this.name,
          };
        }
        if (!offer.quantity || offer.quantity < 1) {
          return {
            success: false,
            error: getErrorMessage('INVALID_QUANTITY'),
            stage: this.name,
          };
        }
      }

      if (
        !context.deliveryCoordinates?.latitude ||
        !context.deliveryCoordinates?.longitude
      ) {
        return {
          success: false,
          error: getErrorMessage('INVALID_DELIVERY_COORDINATES'),
          stage: this.name,
        };
      }

      if (!context.paymentMethod) {
        return {
          success: false,
          error: getErrorMessage('PAYMENT_METHOD_REQUIRED'),
          stage: this.name,
        };
      }

      if ((context.tipAmount ?? 0) < 0) {
        return {
          success: false,
          error: getErrorMessage('INVALID_TIP_AMOUNT'),
          stage: this.name,
        };
      }

      if (!context.areaId) {
        return {
          success: false,
          error: 'معرف المنطقة (areaId) مطلوب',
          stage: this.name,
        };
      }

      const deliveryCalculation = await this.pipeline.calculateDeliveryFee(
        context.areaId,
      );

      return {
        success: true,
        data: {
          ...context,
          deliveryFee: deliveryCalculation.deliveryFee,
          platformCommission: deliveryCalculation.platformCommission,
        },
      };
    } catch (error) {
      return {
        success: false,
        error:
          error instanceof Error
            ? error.message
            : ErrorCodes.VALIDATION_ERROR.message,
        stage: this.name,
      };
    }
  }
}

class ProductValidationStage implements OrderPipelineStage {
  name = 'ProductValidation';
  constructor(private pipeline: OrderPipeline) {}

  async execute(context: OrderPipelineContext): Promise<OrderPipelineResult> {
    try {
      if (!context.items || context.items.length === 0) {
        (context as any).validatedProducts = [];
        return { success: true, data: context };
      }

      const productRepo = this.pipeline.getProductRepository();

      const productIds = context.items.map((item) => item.productId);
      const allProducts = await productRepo.find({
        where: { id: In(productIds) },
      });

      const productsMap = new Map(allProducts.map((p) => [p.id, p]));

      for (const item of context.items) {
        const product = productsMap.get(item.productId);

        if (!product) {
          return {
            success: false,
            error: getErrorMessage(
              'PRODUCT_NOT_FOUND',
              `المنتج غير موجود (معرف: ${item.productId})`,
            ),
            stage: this.name,
          };
        }

        if (product.merchantId !== context.ownerId) {
          return {
            success: false,
            error: getErrorMessage(
              'PRODUCT_NOT_OWNED_BY_MERCHANT',
              `المنتج "${product.name}" (معرف: ${item.productId}) لا ينتمي لهذا التاجر`,
            ),
            stage: this.name,
          };
        }

        if (!product.isAvailable) {
          return {
            success: false,
            error: getErrorMessage(
              'PRODUCT_NOT_AVAILABLE',
              `المنتج "${product.name}" غير متاح حالياً`,
            ),
            stage: this.name,
          };
        }

        if (product.hasStock) {
          if (
            product.stockQuantity === null ||
            product.stockQuantity < item.quantity
          ) {
            return {
              success: false,
              error: getErrorMessage(
                'INSUFFICIENT_STOCK',
                `الكمية المطلوبة من المنتج "${product.name}" غير متوفرة. المتوفر: ${product.stockQuantity ?? 0}, المطلوب: ${item.quantity}`,
              ),
              stage: this.name,
            };
          }
        }
      }

      const products = context.items.map((item) =>
        productsMap.get(item.productId),
      );
      (context as any).validatedProducts = products;
      return { success: true, data: context };
    } catch (error) {
      return {
        success: false,
        error:
          error instanceof Error
            ? error.message
            : ErrorCodes.VALIDATION_ERROR.message,
        stage: this.name,
      };
    }
  }
}

class OfferValidationStage implements OrderPipelineStage {
  name = 'OfferValidation';
  constructor(private pipeline: OrderPipeline) {}

  async execute(context: OrderPipelineContext): Promise<OrderPipelineResult> {
    try {
      if (!context.offers || context.offers.length === 0) {
        (context as any).validatedOffers = [];
        (context as any).offerDiscountTotal = 0;
        return { success: true, data: context };
      }

      const offerRepo = this.pipeline.getOfferRepository();
      const offerIds = context.offers.map((o) => o.offerId);

      const offers = await offerRepo.find({
        where: { id: In(offerIds) },
        relations: ['offerProducts', 'offerProducts.product'],
      });

      if (offers.length !== offerIds.length) {
        const foundOfferIds = offers.map((o) => o.id);
        const missingOfferIds = offerIds.filter(
          (id) => !foundOfferIds.includes(id),
        );
        return {
          success: false,
          error: getErrorMessage(
            'OFFER_NOT_FOUND',
            `العروض غير موجودة: [${missingOfferIds.join(', ')}]`,
          ),
          stage: this.name,
        };
      }

      for (const offer of offers) {
        if (!offer.isActive) {
          return {
            success: false,
            error: getErrorMessage(
              'OFFER_NOT_ACTIVE',
              `العرض "${offer.name}" غير نشط حالياً`,
            ),
            stage: this.name,
          };
        }
        if (offer.merchantId !== context.ownerId) {
          return {
            success: false,
            error: getErrorMessage(
              'OFFER_NOT_OWNED_BY_MERCHANT',
              `العرض "${offer.name}" لا ينتمي لهذا التاجر`,
            ),
            stage: this.name,
          };
        }
      }

      const validatedOffers: any[] = [];
      for (const offerInput of context.offers) {
        const offer = offers.find((o) => o.id === offerInput.offerId);
        if (!offer) continue;

        const validatedItems: any[] = [];

        for (const offerProduct of offer.offerProducts || []) {
          if (!offerProduct.isActive) continue;

          const product = offerProduct.product;
          if (!product) continue;

          if (product.merchantId !== context.ownerId) {
            return {
              success: false,
              error: getErrorMessage(
                'OFFER_PRODUCT_NOT_OWNED_BY_MERCHANT',
                `المنتج "${product.name}" في العرض "${offer.name}" لا ينتمي لهذا التاجر`,
              ),
              stage: this.name,
            };
          }

          if (!product.isAvailable) {
            return {
              success: false,
              error: getErrorMessage(
                'PRODUCT_NOT_AVAILABLE',
                `المنتج "${product.name}" في العرض "${offer.name}" غير متاح حالياً`,
              ),
              stage: this.name,
            };
          }

          const quantity = offerInput.quantity;
          if (product.hasStock && (product.stockQuantity ?? 0) < quantity) {
            return {
              success: false,
              error: getErrorMessage(
                'INSUFFICIENT_STOCK',
                `الكمية المطلوبة من المنتج "${product.name}" في العرض "${offer.name}" غير متوفرة. المتوفر: ${product.stockQuantity ?? 0}, المطلوب: ${quantity}`,
              ),
              stage: this.name,
            };
          }

          validatedItems.push({
            offerId: offer.id,
            offerProductId: offerProduct.id,
            productId: product.id,
            productName: product.name,
            quantity,
            originalUnitPrice: product.price,
            commissionRate: 0,
            productDiscount: product.discount || 0,
            productDiscountType: product.discountType,
          });
        }

        validatedOffers.push({
          ...offer,
          validatedItems,
        });
      }

      (context as any).validatedOffers = validatedOffers;
      (context as any).offerDiscountTotal = 0;
      return { success: true, data: context };
    } catch (error) {
      return {
        success: false,
        error:
          error instanceof Error
            ? error.message
            : ErrorCodes.VALIDATION_ERROR.message,
        stage: this.name,
      };
    }
  }
}

class PriceCalculationStage implements OrderPipelineStage {
  name = 'PriceCalculation';
  constructor(private pipeline: OrderPipeline) {}

  async execute(context: OrderPipelineContext): Promise<OrderPipelineResult> {
    try {
      const validatedProducts =
        ((context as any).validatedProducts as Product[]) || [];
      const validatedOffers = (context as any).validatedOffers || [];
      const orderItems: any[] = [];
      const calculatedOffers: any[] = [];
      let subtotal = 0;
      let totalQuantity = 0;

      const productsMap = new Map<number, Product>(
        validatedProducts.map((p) => [p.id, p]),
      );

      for (const item of context.items || []) {
        const product = productsMap.get(item.productId);
        if (!product) continue;

        const originalPrice = product.price;
        const productDiscount = product.discount || 0;
        const commissionRate = 0;
        const quantity = item.quantity;

        let productDiscountValue = 0;
        if (productDiscount > 0) {
          if (product.discountType === DiscountType.PERCENTAGE) {
            productDiscountValue = Math.floor(
              (originalPrice * productDiscount) / 100,
            );
          } else {
            productDiscountValue = productDiscount;
          }
        }

        const priceAfterProductDiscount = originalPrice - productDiscountValue;

        const commissionAmount = 0;
        const itemTotal = priceAfterProductDiscount * quantity;

        orderItems.push({
          productId: product.id,
          productName: product.name,
          quantity,
          originalUnitPrice: Math.round(originalPrice),
          unitPrice: Math.round(priceAfterProductDiscount),
          totalPrice: Math.round(itemTotal),
          commissionAmount,
          commissionRate,
          productDiscountValue,
          offerId: null,
        });

        subtotal += itemTotal;
        totalQuantity += quantity;
      }

      for (const offer of validatedOffers) {
        let offerSubtotal = 0;
        let offerTotalQuantity = 0;
        let offerProductDiscountTotal = 0;

        for (const item of offer.validatedItems) {
          const originalPrice = item.originalUnitPrice;
          const productDiscount = item.productDiscount || 0;
          const commissionRate = 0;
          const quantity = item.quantity;

          let productDiscountValue = 0;
          if (productDiscount > 0) {
            if (item.productDiscountType === DiscountType.PERCENTAGE) {
              productDiscountValue = Math.floor(
                (originalPrice * productDiscount) / 100,
              );
            } else {
              productDiscountValue = productDiscount;
            }
          }

          const priceAfterProductDiscount =
            originalPrice - productDiscountValue;

          const commissionAmount = 0;
          const itemTotal = priceAfterProductDiscount * quantity;

          orderItems.push({
            productId: item.productId,
            productName: item.productName,
            quantity,
            originalUnitPrice: Math.round(originalPrice),
            unitPrice: Math.round(priceAfterProductDiscount),
            totalPrice: Math.round(itemTotal),
            commissionAmount,
            commissionRate,
            productDiscountValue,
            offerId: item.offerId,
          });

          offerSubtotal += itemTotal;
          offerTotalQuantity += quantity;
          offerProductDiscountTotal += productDiscountValue * quantity;
          subtotal += itemTotal;
          totalQuantity += quantity;
        }

        let offerDiscountValue = 0;
        if (offer.discountValue && offer.discountType) {
          if (offer.discountType === DiscountType.PERCENTAGE) {
            offerDiscountValue = Math.floor(
              (offerSubtotal * offer.discountValue) / 100,
            );
          } else {
            offerDiscountValue = offer.discountValue;
          }
        }

        calculatedOffers.push({
          offerId: offer.id,
          offerName: offer.name,
          subtotal: offerSubtotal,
          totalQuantity: offerTotalQuantity,
          productDiscountTotal: offerProductDiscountTotal,
          discountValue: offerDiscountValue,
          totalPrice: Math.max(0, offerSubtotal - offerDiscountValue),
        });
      }

      let totalOfferDiscount = 0;
      for (const offer of calculatedOffers) {
        totalOfferDiscount += offer.discountValue;
      }

      const platformCommission = context.platformCommission || 0;
      const totalPrice = Math.max(0, subtotal - totalOfferDiscount);
      const total = Math.round(
        totalPrice +
          context.deliveryFee +
          platformCommission +
          context.tipAmount,
      );

      (context as any).calculatedOrderItems = orderItems;
      (context as any).calculatedOffers = calculatedOffers;

      return {
        success: true,
        data: {
          ...context,
          subtotal: Math.round(subtotal),
          totalQuantity,
          productDiscountTotal: 0,
          totalDiscount: totalOfferDiscount,
          total,
        },
      };
    } catch (error) {
      return {
        success: false,
        error:
          error instanceof Error ? error.message : 'Price calculation failed',
        stage: this.name,
      };
    }
  }
}

class OrderCreationStage implements OrderPipelineStage {
  name = 'OrderCreation';
  constructor(private pipeline: OrderPipeline) {}

  async execute(context: OrderPipelineContext): Promise<OrderPipelineResult> {
    const queryRunner = this.pipeline['dataSource'].createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const data = context as OrderPipelineContext & {
        subtotal: number;
        productDiscountTotal: number;
        totalDiscount: number;
        total: number;
      };

      const calculatedItems = (context as any).calculatedOrderItems || [];
      const calculatedOffers = (context as any).calculatedOffers || [];

      const deliveryFee = context.deliveryFee || 0;
      const platformCommission = context.platformCommission || 0;

      const subtotalAfterDiscount = calculatedItems.reduce(
        (sum: number, item: any) => sum + (item.totalPrice || 0),
        0,
      );

      const productDiscountTotal =
        calculatedItems.reduce(
          (sum: number, item: any) =>
            sum + (item.productDiscountValue || 0) * (item.quantity || 0),
          0,
        ) +
        calculatedOffers.reduce(
          (sum: number, offer: any) => sum + (offer.productDiscountTotal || 0),
          0,
        );

      const offerDiscountTotal = calculatedOffers.reduce(
        (sum: number, offer: any) => sum + (offer.discountValue || 0),
        0,
      );

      const ownerRevenue = Math.round(
        subtotalAfterDiscount - productDiscountTotal - offerDiscountTotal,
      );

      const order = this.pipeline['orderRepo'].create({
        customerId: context.userId,
        ownerId: context.ownerId,
        areaId: context.areaId,
        status: OrderStatus.PENDING,
        paymentMethod: context.paymentMethod as any,
        totalAmount: data.total,
        discountAmount: data.totalDiscount,
        deliveryFee: context.deliveryFee,
        tipAmount: context.tipAmount,
        platformCommission,
        ownerRevenue,
        deliveryDeadline: new Date(
          Date.now() + DELIVERY_DEADLINE_MINUTES * 60 * 1000,
        ),
        deliveryCoordinates: context.deliveryCoordinates,
        currencyCode: DEFAULT_CURRENCY,
        exchangeRate: DEFAULT_EXCHANGE_RATE,
        customerName: context.customerName,
        phone: context.phone,
      });

      const savedOrder = await queryRunner.manager.save(order);

      for (const item of calculatedItems) {
        const orderItem = this.pipeline['orderItemRepo'].create({
          orderId: savedOrder.id,
          productId: item.productId,
          offerId: item.offerId || null,
          productName: item.productName,
          quantity: item.quantity,
          originalUnitPrice: item.originalUnitPrice,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
          commissionRate: 0,
          commissionAmount: 0,
          productDiscountValue: item.productDiscountValue || 0,
        });
        await queryRunner.manager.save(orderItem);

        const product = await this.pipeline['productRepo'].findOne({
          where: { id: item.productId },
        });
        if (product && product.hasStock) {
          await queryRunner.manager.decrement(
            Product,
            { id: item.productId },
            'stockQuantity',
            item.quantity,
          );
        }
      }

      const validatedOffers = (context as any).validatedOffers || [];
      if (validatedOffers.length > 0) {
        const offersToAttach = validatedOffers.map((o: any) => ({
          id: o.id,
        }));
        savedOrder.offers = offersToAttach;
        await queryRunner.manager.save(savedOrder);
      }

      const invoice = this.pipeline['invoiceRepo'].create({
        orderId: savedOrder.id,
        amount: data.total,
        status: 'PENDING',
        type: InvoiceType.CUSTOMER,
      });
      await queryRunner.manager.save(invoice);

      await queryRunner.commitTransaction();

      await this.pipeline.scheduleOrderTimeout(savedOrder.id);

      try {
        const orderWithRelations = await this.pipeline['orderRepo'].findOne({
          where: { id: savedOrder.id },
          relations: ['owner', 'customer', 'deliveryAssignments'],
        });
        if (orderWithRelations) {
          await this.pipeline['firebaseService'].createOrderDocument(
            orderWithRelations,
          );
        }
      } catch (firebaseError) {}

      return {
        success: true,
        data: {
          ...context,
          orderId: savedOrder.id,
        },
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      return {
        success: false,
        error:
          error instanceof Error
            ? error.message
            : ErrorCodes.INTERNAL_SERVER_ERROR.message,
        stage: this.name,
      };
    } finally {
      await queryRunner.release();
    }
  }
}
