import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { Offer } from '../../../database/entities/offer.entity';
import { Image } from '../../../database/entities/image.entity';
import { User } from '../../../database/entities/user.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { ImageEntityType } from '../../../common/enums';
import { UserRole } from '../../../common/enums/user-role.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { PaginatedResult } from '../../../common/interfaces/paginated-result.interface';
import { NotificationsService } from '../../notifications/notifications.service';
import { SettingsService } from '../../settings/settings.service';
import { OrderQueryService } from './order-query.service';
import { OrderActionsService } from './order-actions.service';
import { GoogleDirectionsService } from '../../distance/google-directions.service';
import { FirebaseService } from '../../firebase/firebase.service';
import {
  OrderResponseMapper,
  OrderResponse,
} from '../mappers/order-response.mapper';
import { StorageService } from '../../../common/storage/storage.service';

@Injectable()
export class OrderManagementService {
  private readonly logger = new Logger(OrderManagementService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Offer)
    private readonly offerRepo: Repository<Offer>,
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepo: Repository<DeliveryAssignment>,
    private readonly orderQueryService: OrderQueryService,
    private readonly orderActionsService: OrderActionsService,
    private readonly notificationsService: NotificationsService,
    private readonly settingsService: SettingsService,
    private readonly storageService: StorageService,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly firebaseService: FirebaseService,
  ) {}

  async findAll(
    query: {
      page?: number;
      limit?: number;
      search?: string;
      categoryId?: number;
      status?: OrderStatus | OrderStatus[];
      statuses?: OrderStatus | OrderStatus[];
    },
    userId: number,
    role: UserRole,
    status?: OrderStatus | OrderStatus[],
  ): Promise<PaginatedResult<OrderResponse>> {
    return this.orderQueryService.findAll(query, userId, role, status);
  }

  async findOne(
    id: number,
    userId: number,
    role: UserRole,
  ): Promise<OrderResponse> {
    const timeoutSetting = await this.settingsService.getSettingByKey(
      'driverRequestTimeoutSeconds',
    );
    const driverTimeoutMs = (Number(timeoutSetting?.value) || 180) * 1000;

    const order = await this.orderRepo.findOne({
      where: { id },
      relations: [
        'owner',
        'owner.merchant',
        'customer',
        'items',
        'offers',
        'deliveryAssignments',
        'deliveryAssignments.delivery',
        'paymentReceipts',
        'paymentReceipts.image',
      ],
    });

    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    const productIds =
      order.items
        ?.map((i) => i.productId)
        .filter((id): id is number => id !== null && id !== undefined) || [];
    const offerIds =
      order.offers
        ?.map((o) => o.id)
        .filter((id): id is number => id !== undefined) || [];

    const [products, offers, productImages, offerImages] = await Promise.all([
      productIds.length > 0
        ? this.productRepo.find({ where: { id: In(productIds) } })
        : Promise.resolve([]),
      offerIds.length > 0
        ? this.offerRepo.find({
            where: { id: In(offerIds) },
            relations: ['offerProducts', 'offerProducts.product'],
          })
        : Promise.resolve([]),
      productIds.length > 0
        ? this.imageRepo.find({
            where: {
              entityType: ImageEntityType.PRODUCT,
              entityId: In(productIds),
            },
            order: { isMain: 'DESC', displayOrder: 'ASC' },
          })
        : Promise.resolve([]),
      offerIds.length > 0
        ? this.imageRepo.find({
            where: {
              entityType: ImageEntityType.OFFER,
              entityId: In(offerIds),
            },
            order: { isMain: 'DESC', displayOrder: 'ASC' },
          })
        : Promise.resolve([]),
    ]);

    const productsMap = new Map(products.map((p) => [p.id, p]));
    const offersMap = new Map(offers.map((o) => [o.id, o]));
    const productImagesMap = new Map<number, Image[]>();
    const offerImagesMap = new Map<number, Image[]>();

    for (const img of productImages) {
      if (!productImagesMap.has(img.entityId)) {
        productImagesMap.set(img.entityId, []);
      }
      productImagesMap.get(img.entityId)!.push(img);
    }

    for (const img of offerImages) {
      if (!offerImagesMap.has(img.entityId)) {
        offerImagesMap.set(img.entityId, []);
      }
      offerImagesMap.get(img.entityId)!.push(img);
    }

    const enrichedOffers = offers.map((offer) => {
      const offerItems =
        order.items?.filter((item) => item.offerId === offer.id) || [];

      const products = (offer.offerProducts || [])
        .filter((op) => op.isActive && op.product)
        .map((op) => {
          const orderItem = offerItems.find(
            (i) => i.productId === op.productId,
          );
          const product = op.product;
          const images = product ? productImagesMap.get(product.id) || [] : [];

          return {
            id: op.id,
            productId: op.productId,
            product: product
              ? {
                  id: product.id,
                  merchantId: product.merchantId,
                  categoryId: product.categoryId,
                  category: product.category,
                  name: product.name,
                  shortDescription: product.shortDescription,
                  description: product.description,
                  personCount: product.personCount,
                  price: product.price,
                  discount: product.discount,
                  discountType: product.discountType,
                  isAvailable: product.isAvailable,
                  hasStock: product.hasStock,
                  stockQuantity: product.stockQuantity,
                  isExternal: product.isExternal,
                  externalProvider: product.externalProvider,
                  externalId: product.externalId,
                  externalMetadata: product.externalMetadata,
                  commissionRate: 0,
                  commissionConfirmed: product.commissionConfirmed,
                  images: images.map((img) => ({
                    id: img.id,
                    url: this.storageService.resolveUrl(img.url) || img.url,
                    mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
                    thumbnailUrl: this.storageService.resolveUrl(
                      img.thumbnailUrl,
                    ),
                    isMain: img.isMain,
                  })),
                  createdAt: product.createdAt,
                  updatedAt: product.updatedAt,
                }
              : null,
            quantity: op.quantity || 1,
            originalUnitPrice: product?.price || 0,
            discount: product?.discount || 0,
            discountType: product?.discountType || null,
            unitPrice: orderItem?.unitPrice || product?.price || 0,
            totalPrice: orderItem?.totalPrice || 0,
            commissionRate: orderItem?.commissionRate || 0,
            commissionAmount: 0,
            productDiscountValue: orderItem?.productDiscountValue || 0,
          };
        });

      const totalQuantity = offerItems.reduce(
        (sum, item) => sum + item.quantity,
        0,
      );

      const productInternalQuantity = products.reduce(
        (sum, p) => sum + (p.quantity || 1),
        0,
      );

      const subtotal = products.reduce(
        (sum, p) => sum + (p.originalUnitPrice || 0) * (p.quantity || 1),
        0,
      );

      const productDiscount = products.reduce(
        (sum, p) => sum + (p.productDiscountValue || 0) * (p.quantity || 1),
        0,
      );

      const subtotalAfterProductDiscount = products.reduce(
        (sum, p) => sum + (p.unitPrice || 0) * (p.quantity || 1),
        0,
      );

      const subtotalWithOfferQuantity = subtotal * totalQuantity;
      const subtotalAfterProductDiscountWithQuantity =
        subtotalAfterProductDiscount * totalQuantity;
      const productDiscountWithQuantity = productDiscount * totalQuantity;

      let offerDiscountAmount = 0;
      if (offer.discountValue && offer.discountType) {
        if (offer.discountType === 'PERCENTAGE') {
          offerDiscountAmount = Math.floor(
            (subtotalAfterProductDiscountWithQuantity * offer.discountValue) /
              100,
          );
        } else {
          offerDiscountAmount = offer.discountValue * totalQuantity;
        }
      }

      const totalCommissionAmount = 0;

      const total = Math.max(
        0,
        subtotalAfterProductDiscountWithQuantity - offerDiscountAmount,
      );

      const totalProductDiscountValue = products.reduce(
        (sum, p) =>
          sum +
          (p.productDiscountValue || 0) * (p.quantity || 1) * totalQuantity,
        0,
      );

      const offerCommissionRate =
        products.length > 0 ? products[0].commissionRate || 0 : 0;

      return {
        id: offer.id,
        name: offer.name,
        description: offer.description,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        isActive: offer.isActive,
        merchantId: offer.merchantId,
        createdAt: offer.createdAt,
        updatedAt: offer.updatedAt,
        products,
        totalQuantity,
        productInternalQuantity,
        subtotal: subtotalWithOfferQuantity,
        productDiscount: productDiscountWithQuantity,
        offerDiscount: offerDiscountAmount,
        total,
        commissionRate: offerCommissionRate,
        totalCommissionAmount: 0,
        totalProductDiscountValue,
        images: (offerImagesMap.get(offer.id) || []).map((img) => ({
          id: img.id,
          url: this.storageService.resolveUrl(img.url) || img.url,
          mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
          thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl),
          isMain: img.isMain,
        })),
      };
    });

    const enrichedItems = (order.items || [])
      .filter((item) => !item.offerId)
      .map((item) => {
        const product = item.productId ? productsMap.get(item.productId) : null;
        const productImages = item.productId
          ? productImagesMap.get(item.productId) || []
          : [];

        return {
          id: item.id,
          productId: item.productId,
          product: product
            ? {
                id: product.id,
                merchantId: product.merchantId,
                categoryId: product.categoryId,
                category: product.category,
                name: product.name,
                shortDescription: product.shortDescription,
                description: product.description,
                personCount: product.personCount,
                price: product.price,
                discount: product.discount,
                discountType: product.discountType,
                isAvailable: product.isAvailable,
                hasStock: product.hasStock,
                stockQuantity: product.stockQuantity,
                isExternal: product.isExternal,
                externalProvider: product.externalProvider,
                externalId: product.externalId,
                externalMetadata: product.externalMetadata,
                commissionRate: 0,
                commissionConfirmed: product.commissionConfirmed,
                images: productImages.map((img) => ({
                  id: img.id,
                  url: this.storageService.resolveUrl(img.url) || img.url,
                  mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
                  thumbnailUrl: this.storageService.resolveUrl(
                    img.thumbnailUrl,
                  ),
                  isMain: img.isMain,
                })),
                createdAt: product.createdAt,
                updatedAt: product.updatedAt,
              }
            : null,
          originalUnitPrice: item.originalUnitPrice,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          commissionRate: 0,
          commissionAmount: 0,
          totalCommissionAmount: 0,
          productDiscountValue: item.productDiscountValue,
          totalProductDiscountValue: item.productDiscountValue * item.quantity,
          totalPrice: item.totalPrice,
        };
      });

    const itemsTotal =
      order.items?.reduce((sum, item) => sum + (item.totalPrice || 0), 0) || 0;

    const offersTotal =
      enrichedOffers?.reduce((sum, offer) => sum + (offer.total || 0), 0) || 0;

    const subtotal = itemsTotal + offersTotal;

    const productDiscountTotal =
      order.items?.reduce(
        (sum, item) => sum + (item.productDiscountValue || 0) * item.quantity,
        0,
      ) || 0;

    const priceBeforeDiscount =
      order.items?.reduce(
        (sum, item) => sum + (item.originalUnitPrice || 0) * item.quantity,
        0,
      ) || 0;

    const itemsTotalCommission = 0;

    const offersTotalCommission = 0;

    const totalCommissionAmount = 0;

    const calculatedTotalAmount =
      order.totalAmount ||
      subtotal + (order.deliveryFee || 0) + (order.platformCommission || 0);

    const simplifiedCustomer = order.customer
      ? {
          id: order.customer.id,
          firstName: order.customer.firstName,
          lastName: order.customer.lastName,
          phone: order.customer.phone,
          email: order.customer.email,
          address: order.customer.address,
        }
      : null;

    const simplifiedOwner = order.owner
      ? {
          id: order.owner.id,
          firstName: order.owner.firstName,
          lastName: order.owner.lastName,
          phone:
            role === UserRole.ADMIN
              ? order.owner.phone
              : order.owner.merchant?.hidePhoneNumber === true
                ? undefined
                : order.owner.phone,
          email: order.owner.email,
          address: order.owner.address,
          restaurantName: order.owner.merchant?.restaurantName || null,
          location: order.owner.location,
        }
      : null;

    // Find delivery information
    let deliveryId: number | null = null;
    let delivery: any = null;
    let remainingTime: any = null;

    if (order.deliveryAssignments && order.deliveryAssignments.length > 0) {
      // For assigned orders, find the accepted assignment
      const acceptedAssignment = order.deliveryAssignments.find(
        (a) =>
          a.status === DeliveryStatus.ACCEPTED ||
          a.status === DeliveryStatus.PICKED ||
          a.status === DeliveryStatus.COMPLETED ||
          a.status === DeliveryStatus.ASSIGNED,
      );

      if (acceptedAssignment) {
        deliveryId = acceptedAssignment.deliveryId;
        delivery = OrderResponseMapper.mapSimplifiedUser(
          acceptedAssignment.delivery,
        );
      }

      // For SEARCHING orders and DELIVERY role, calculate remaining time
      if (
        order.status === OrderStatus.SEARCHING &&
        role === UserRole.DELIVERY &&
        userId
      ) {
        const currentDriverAssignment = order.deliveryAssignments.find(
          (a) => a.deliveryId === userId,
        );

        if (currentDriverAssignment) {
          const timeoutMs = driverTimeoutMs;
          const assignedAt = new Date(
            currentDriverAssignment.assignedAt,
          ).getTime();
          const now = Date.now();
          const elapsed = now - assignedAt;
          const remaining = timeoutMs - elapsed;

          if (remaining > 0) {
            remainingTime =
              OrderResponseMapper.getRemainingTimeObject(remaining);
          } else {
            remainingTime = { text: 'انتهى الوقت', minutes: 0, seconds: 0 };
          }
        }
      }
    }

    const response: any = {
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      phone: order.phone,
      customer: simplifiedCustomer,
      ownerId: order.ownerId ?? null,
      owner: simplifiedOwner,
      paymentMethod: order.paymentMethod,
      status: OrderResponseMapper.getVisibleStatus(order.status, role),
      deliveryDeadline: order.deliveryDeadline ?? null,
      deliveryCoordinates: order.deliveryCoordinates,
      finalLocation: order.finalLocation,
      items: enrichedItems,
      offers: enrichedOffers,
      itemsTotal,
      offersTotal,
      subtotal,
      priceBeforeDiscount: priceBeforeDiscount,
      discountAmount: order.discountAmount || 0,
      priceAfterProductDiscount: subtotal,
      productDiscount: productDiscountTotal,
      offerDiscount:
        enrichedOffers && enrichedOffers.length > 0
          ? (order.discountAmount || 0) - productDiscountTotal
          : 0,
      tipAmount: order.tipAmount || 0,
      platformCommission: order.platformCommission || 0,
      ownerRevenue: order.ownerRevenue || 0,
      deliveryFee: order.deliveryFee || 0,
      totalAmount: order.totalAmount || 0,
      totalCommissionAmount: 0,
      currencyCode: order.currencyCode,
      mealPreparationTime: order.mealPreparationTime,
      deliveryTime: order.deliveryTime,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      deliveryId,
      delivery,
      ...((role === UserRole.ADMIN || role === UserRole.DELIVERY) &&
        order.paymentReceipts &&
        order.paymentReceipts.length > 0 && {
          receipts: order.paymentReceipts.map((receipt) => ({
            id: receipt.id,
            imageId: receipt.imageId,
            url:
              this.storageService.resolveUrl(receipt.image?.url) ||
              receipt.image?.url,
            thumbnailUrl:
              this.storageService.resolveUrl(receipt.image?.thumbnailUrl) ||
              receipt.image?.thumbnailUrl,
            mobileUrl:
              this.storageService.resolveUrl(receipt.image?.mobileUrl) ||
              receipt.image?.mobileUrl,
          })),
        }),
    };

    if (remainingTime) {
      response.remainingTime = remainingTime;
    }

    if (
      order.status !== OrderStatus.DELIVERED &&
      order.status !== OrderStatus.PAID &&
      order.status !== OrderStatus.COMPLETE
    ) {
      if (order.owner?.location && order.deliveryCoordinates) {
        try {
          const merchantCoord = {
            lat: order.owner.location.lat,
            lng: order.owner.location.lng,
          };
          const customerCoord = {
            lat: order.deliveryCoordinates.latitude,
            lng: order.deliveryCoordinates.longitude,
          };

          const customerRoute =
            await this.googleDirectionsService.getRouteDetails(
              merchantCoord,
              customerCoord,
            );

          const estimatedRoute: any = {
            merchantToCustomer: {
              distance: customerRoute.distanceMeters,
              time:
                customerRoute.durationInTrafficSeconds ||
                customerRoute.durationSeconds,
            },
          };

          if (
            deliveryId &&
            order.status !== OrderStatus.PENDING &&
            order.status !== OrderStatus.CONFIRMED &&
            order.status !== OrderStatus.SEARCHING
          ) {
            const driverLocations =
              await this.firebaseService.getAllDriverLocations();
            const driverFbData = driverLocations.get(deliveryId);

            if (driverFbData?.currentLat && driverFbData?.currentLng) {
              const driverCoord = {
                lat: driverFbData.currentLat,
                lng: driverFbData.currentLng,
              };

              const driverToMerchantRoute =
                await this.googleDirectionsService.getRouteDetails(
                  driverCoord,
                  merchantCoord,
                );

              estimatedRoute.driverToMerchant = {
                distance: driverToMerchantRoute.distanceMeters,
                time:
                  driverToMerchantRoute.durationInTrafficSeconds ||
                  driverToMerchantRoute.durationSeconds,
              };

              if (
                order.status === OrderStatus.PICKED_UP ||
                order.status === OrderStatus.ON_THE_WAY
              ) {
                const driverToCustomerRoute =
                  await this.googleDirectionsService.getRouteDetails(
                    driverCoord,
                    customerCoord,
                  );

                estimatedRoute.driverToCustomer = {
                  distance: driverToCustomerRoute.distanceMeters,
                  time:
                    driverToCustomerRoute.durationInTrafficSeconds ||
                    driverToCustomerRoute.durationSeconds,
                };
              }
            }
          }

          response.estimatedRoute = estimatedRoute;
        } catch (error) {
          this.logger.error(`Failed to calculate estimatedRoute: ${error}`);
        }
      }
    }

    return response;
  }

  async confirmOrder(
    orderId: number,
    userId: number,
    role: UserRole,
  ): Promise<Order> {
    return this.orderActionsService.confirmOrder(orderId, userId, role);
  }

  async rejectOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    return this.orderActionsService.rejectOrder(orderId, userId, role, reason);
  }

  async updateOrderStatus(
    orderId: number,
    newStatus: OrderStatus,
    userId: number,
    role: UserRole,
    reason?: string,
    finalLocation?: { lat: number; lng: number },
    mealPreparationTime?: number,
    deliveryTime?: number,
  ): Promise<Order> {
    return this.orderActionsService.updateOrderStatus(
      orderId,
      newStatus,
      userId,
      role,
      reason,
      finalLocation,
      mealPreparationTime,
      deliveryTime,
    );
  }

  async cancelOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    return this.orderActionsService.cancelOrder(orderId, userId, role, reason);
  }
}
