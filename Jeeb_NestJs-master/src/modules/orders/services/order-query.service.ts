import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder, In } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { Offer } from '../../../database/entities/offer.entity';
import { Image } from '../../../database/entities/image.entity';
import { ImageEntityType } from '../../../common/enums';
import { UserRole } from '../../../common/enums/user-role.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { PaginatedResult } from '../../../common/interfaces/paginated-result.interface';
import { Brackets } from 'typeorm';
import { SearchService, CaseSensitivity } from '../../../common/search';
import { OrderAccessValidator } from '../validators/order-access.validator';
import { SettingsService } from '../../settings/settings.service';
import { GoogleDirectionsService } from '../../distance/google-directions.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { StorageService } from '../../../common/storage/storage.service';
import {
  OrderResponseMapper,
  OrderResponse,
} from '../mappers/order-response.mapper';

@Injectable()
export class OrderQueryService {
  private readonly logger = new Logger(OrderQueryService.name);

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
    private readonly orderAccessValidator: OrderAccessValidator,
    private readonly searchService: SearchService,
    private readonly settingsService: SettingsService,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly firebaseService: FirebaseService,
    private readonly storageService: StorageService,
  ) {}

  async findAll(
    query: {
      page?: number;
      limit?: number;
      search?: string;
      categoryId?: number;
      status?: OrderStatus | OrderStatus[];
      statuses?: OrderStatus | OrderStatus[];
      merchantId?: number;
      startDate?: string;
      endDate?: string;
    },
    userId: number,
    role: UserRole,
    status?: OrderStatus | OrderStatus[],
  ): Promise<PaginatedResult<OrderResponse>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;
    const skip = (page - 1) * limit;

    const timeoutSetting = await this.settingsService.getSettingByKey(
      'driverRequestTimeoutSeconds',
    );
    const driverTimeoutMs = (Number(timeoutSetting?.value) || 180) * 1000;

    const applyFilters = async (qb: SelectQueryBuilder<Order>, forCount = false) => {
      if (!forCount) {
        qb.leftJoinAndSelect('order.area', 'area')
          .leftJoinAndSelect('order.owner', 'owner')
          .leftJoinAndSelect('owner.merchant', 'merchant')
          .leftJoinAndSelect('order.customer', 'customer')
          .leftJoinAndSelect('order.items', 'items')
          .leftJoinAndSelect('items.product', 'itemsProduct')
          .leftJoinAndSelect('itemsProduct.category', 'itemsProductCategory')
          .leftJoinAndSelect('order.offers', 'offers')
          .leftJoinAndSelect('order.deliveryAssignments', 'assignment')
          .leftJoinAndSelect('assignment.delivery', 'assignmentDelivery')
          .leftJoinAndSelect('offers.offerProducts', 'offerProducts')
          .leftJoinAndSelect('offerProducts.product', 'offerProduct')
          .leftJoinAndSelect('order.paymentReceipts', 'paymentReceipts')
          .leftJoinAndSelect('paymentReceipts.image', 'paymentReceiptImage');
      } else {
        qb.leftJoin('order.owner', 'owner')
          .leftJoin('owner.merchant', 'merchant')
          .leftJoin('order.customer', 'customer')
          .leftJoin('order.deliveryAssignments', 'assignment');
      }

      qb.withDeleted();
      await this.orderAccessValidator.applyRoleBasedFiltering(qb, role, userId);

      const effectiveStatus = status || query.status || query.statuses;
      if (effectiveStatus) {
        if (
          (role === UserRole.CUSTOMER || role === UserRole.MERCHANT) &&
          (effectiveStatus === OrderStatus.PAID ||
            effectiveStatus === OrderStatus.COMPLETE)
        ) {
          throw new BadRequestException({
            statusCode: 400,
            message:
              'You cannot filter by PAID or COMPLETE status. These orders are shown as DELIVERED.',
            error: 'ERROR_4122',
            timestamp: new Date().toISOString(),
            path: '',
          });
        }

        let statusesToFilter: string[] | string = effectiveStatus;
        if (
          (role === UserRole.CUSTOMER || role === UserRole.MERCHANT) &&
          effectiveStatus === OrderStatus.DELIVERED
        ) {
          statusesToFilter = [
            OrderStatus.DELIVERED,
            OrderStatus.PAID,
            OrderStatus.COMPLETE,
          ];
        }

        if (Array.isArray(statusesToFilter)) {
          qb.andWhere('order.status IN (:...statuses)', {
            statuses: statusesToFilter,
          });
        } else {
          qb.andWhere('order.status = :status', {
            status: statusesToFilter,
          });
        }
      }

      if (query.search) {
        const searchResult = this.searchService.buildSearchConditions(
          [
            'CAST(order.id AS TEXT)',
            'customer.firstName',
            'customer.lastName',
            'merchant.restaurantName',
          ],
          query.search,
          CaseSensitivity.INSENSITIVE,
        );

        qb.andWhere(
          new Brackets((qb2) => {
            qb2.where(searchResult.condition, {
              [searchResult.paramName]: searchResult.paramValue,
            });
          }),
        );
      }

      if (query.merchantId) {
        qb.andWhere('order.ownerId = :merchantId', {
          merchantId: query.merchantId,
        });
      }

      if (query.startDate) {
        qb.andWhere('order.createdAt >= :startDate', {
          startDate: query.startDate,
        });
      }

      if (query.endDate) {
        qb.andWhere('order.createdAt <= :endDate', {
          endDate: query.endDate,
        });
      }
    };

    // Get total count with minimal joins
    const countQb = this.orderRepo.createQueryBuilder('order');
    await applyFilters(countQb, true);
    const total = await countQb.getCount();

    if (total === 0) {
      return {
        data: [],
        total: 0,
        page,
        limit,
        totalPages: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      };
    }

    // Get paginated order IDs
    const idQb = this.orderRepo.createQueryBuilder('order');
    await applyFilters(idQb, true);
    idQb.select('DISTINCT order.id, order.createdAt').offset(skip).limit(limit).orderBy('order.createdAt', 'DESC');
    const idRows = await idQb.getRawMany();
    const ids = idRows.map((r: any) => r.id ?? r.order_id);

    // Load full order data for the selected IDs
    const data = await this.orderRepo.find({
      where: { id: In(ids) },
      relations: [
        'area',
        'owner',
        'owner.merchant',
        'customer',
        'items',
        'items.product',
        'items.product.category',
        'offers',
        'offers.offerProducts',
        'offers.offerProducts.product',
        'deliveryAssignments',
        'deliveryAssignments.delivery',
        'paymentReceipts',
        'paymentReceipts.image',
      ],
      withDeleted: true,
    });

    // Preserve the original pagination order
    const idOrder = new Map(ids.map((id, index) => [id, index]));
    data.sort((a, b) => (idOrder.get(a.id) ?? 0) - (idOrder.get(b.id) ?? 0));

    const offerProductImagesMap = await this.loadOfferProductImages(data);
    const itemProductImagesMap = await this.loadProductImagesForItems(data);

    const reorderedData = await Promise.all(
      data.map((order) =>
        this.mapOrderWithOffers(
          order,
          offerProductImagesMap,
          itemProductImagesMap,
          userId,
          role,
          driverTimeoutMs,
        ),
      ),
    );

    const totalPages = Math.ceil(total / limit);

    return {
      data: reorderedData,
      total,
      page,
      limit,
      totalPages,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    };
  }

  async findOne(
    id: number,
    userId: number,
    role: UserRole,
  ): Promise<OrderResponse> {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: [
        'area',
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
      throw new Error(`Order with ID ${id} not found`);
    }

    const accessResult = this.orderAccessValidator.validateOrderAccess(order, {
      role,
      userId,
    });

    if (!accessResult.canAccess) {
      throw new Error(accessResult.reason);
    }

    const { products, offers, productImagesMap, offerImagesMap } =
      await this.loadOrderData(order);

    return this.mapOrderWithOffers(
      order,
      productImagesMap,
      new Map(),
      userId,
      role,
    );
  }

  private async loadProductImagesForItems(
    orders: Order[],
  ): Promise<Map<number, Image[]>> {
    const allProductIds = new Set<number>();

    for (const order of orders) {
      if (order.items) {
        for (const item of order.items) {
          if (item.productId) {
            allProductIds.add(item.productId);
          }
        }
      }
    }

    if (allProductIds.size === 0) {
      return new Map();
    }

    const productImages = await this.imageRepo.find({
      where: {
        entityType: ImageEntityType.PRODUCT,
        entityId: In([...allProductIds]),
      },
      order: { isMain: 'DESC', displayOrder: 'ASC' },
    });

    const productImagesMap = new Map<number, Image[]>();
    for (const img of productImages) {
      if (!productImagesMap.has(img.entityId)) {
        productImagesMap.set(img.entityId, []);
      }
      productImagesMap.get(img.entityId)!.push(img);
    }

    return productImagesMap;
  }

  private async loadOfferProductImages(
    orders: Order[],
  ): Promise<Map<number, Image[]>> {
    const allOfferProductIds = new Set<number>();

    for (const order of orders) {
      if (order.offers) {
        for (const offer of order.offers) {
          if (offer.offerProducts) {
            for (const op of offer.offerProducts) {
              if (op.productId) {
                allOfferProductIds.add(op.productId);
              }
            }
          }
        }
      }
    }

    if (allOfferProductIds.size === 0) {
      return new Map();
    }

    const productImages = await this.imageRepo.find({
      where: {
        entityType: ImageEntityType.PRODUCT,
        entityId: In([...allOfferProductIds]),
      },
      order: { isMain: 'DESC', displayOrder: 'ASC' },
    });

    const productImagesMap = new Map<number, Image[]>();
    for (const img of productImages) {
      if (!productImagesMap.has(img.entityId)) {
        productImagesMap.set(img.entityId, []);
      }
      productImagesMap.get(img.entityId)!.push(img);
    }

    return productImagesMap;
  }

  private async mapOrderWithOffers(
    order: Order,
    productImagesMap: Map<number, Image[]>,
    itemProductImagesMap: Map<number, Image[]>,
    userId?: number,
    role?: UserRole,
    driverTimeoutMs?: number,
  ): Promise<OrderResponse> {
    // Find delivery information
    let deliveryId: number | null = null;
    let delivery: any = null;
    let remainingTime: any = null;
    let tempEstimatedRoute: {
      driverToMerchant?: { distance: number; time: number };
      merchantToCustomer?: { distance: number; time: number };
      driverToCustomer?: { distance: number; time: number };
    } | null = null;

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

        // Calculate estimated route for ALL roles when there's a delivery assigned
        try {
          // Get driver location from Firebase (for all roles)
          const driverLocations =
            await this.firebaseService.getAllDriverLocations();
          const driverFbData = driverLocations.get(deliveryId);
          const hasDriverLocation =
            driverFbData?.currentLat && driverFbData?.currentLng;
          const hasMerchantLocation = !!order.owner?.location;
          const hasCustomerLocation = !!order.deliveryCoordinates;

          if (hasMerchantLocation && hasCustomerLocation && order.owner) {
            const merchantCoord = {
              lat: order.owner.location!.lat,
              lng: order.owner.location!.lng,
            };
            const customerCoord = {
              lat: order.deliveryCoordinates.latitude,
              lng: order.deliveryCoordinates.longitude,
            };

            // Calculate route from driver to merchant (if driver location available)
            if (hasDriverLocation) {
              const driverCoord = {
                lat: driverFbData.currentLat,
                lng: driverFbData.currentLng,
              };

              // driver to merchant route
              const merchantRoute =
                await this.googleDirectionsService.getRouteDetails(
                  driverCoord,
                  merchantCoord,
                );

              // driver to customer direct route
              const driverToCustomerRoute =
                await this.googleDirectionsService.getRouteDetails(
                  driverCoord,
                  customerCoord,
                );

              tempEstimatedRoute = {
                driverToMerchant: {
                  distance: merchantRoute.distanceMeters,
                  time:
                    merchantRoute.durationInTrafficSeconds ||
                    merchantRoute.durationSeconds,
                },
                driverToCustomer: {
                  distance: driverToCustomerRoute.distanceMeters,
                  time:
                    driverToCustomerRoute.durationInTrafficSeconds ||
                    driverToCustomerRoute.durationSeconds,
                },
              };
            }

            // Calculate route from merchant to customer
            const customerRoute =
              await this.googleDirectionsService.getRouteDetails(
                merchantCoord,
                customerCoord,
              );

            if (!tempEstimatedRoute) {
              tempEstimatedRoute = {};
            }
            tempEstimatedRoute.merchantToCustomer = {
              distance: customerRoute.distanceMeters,
              time:
                customerRoute.durationInTrafficSeconds ||
                customerRoute.durationSeconds,
            };
          }
        } catch (error) {
          this.logger.error(`Failed to calculate route: ${error}`);
        }
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
          const timeoutMs = driverTimeoutMs || 180 * 1000;
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

    const priceBeforeDiscount =
      order.items?.reduce(
        (sum, item) => sum + item.originalUnitPrice * item.quantity,
        0,
      ) || 0;

    const offers = OrderResponseMapper.enrichOffersWithTotals(
      order.offers || [],
      order.items || [],
      productImagesMap,
    );

    const directItems = (order.items || []).filter((item) => !item.offerId);

    const itemsTotal =
      directItems?.reduce((sum, item) => sum + (item.totalPrice || 0), 0) || 0;

    const offersTotal =
      offers?.reduce((sum, offer) => sum + (offer.total || 0), 0) || 0;

    const subtotal = itemsTotal + offersTotal;

    const itemsTotalCommission = 0;
    const offersTotalCommission = 0;
    const totalCommissionAmount = 0;
    const calculatedTotalAmount =
      order.totalAmount ||
      subtotal + (order.deliveryFee || 0) + (order.platformCommission || 0);

    const isAssignedForDelivery =
      order.status === OrderStatus.ASSIGNED && role === UserRole.DELIVERY;

    const response: any = {
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      phone: order.phone,
      customer: order.customer
        ? {
            id: order.customer.id,
            firstName: order.customer.firstName,
            lastName: order.customer.lastName,
            phone: order.customer.phone,
            ...(isAssignedForDelivery && {
              email: order.customer.email,
              address: order.customer.address,
            }),
          }
        : null,
      areaId: order.areaId ?? null,
      area: order.area
        ? {
            id: order.area.id,
            name: order.area.name,
            price: order.area.price,
            description: order.area.description,
          }
        : null,
      ownerId: order.ownerId ?? null,
      owner: order.owner
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
        : null,
      paymentMethod: order.paymentMethod,
      status: OrderResponseMapper.getVisibleStatus(order.status, role),
      deliveryDeadline: order.deliveryDeadline,
      deliveryCoordinates: order.deliveryCoordinates,
      finalLocation: order.finalLocation,
      items: order.items
        ? order.items
            .filter((item) => !item.offerId)
            .map((item) => {
              const productImages = item.productId
                ? itemProductImagesMap.get(item.productId) || []
                : [];
              return {
                id: item.id,
                productId: item.productId,
                originalUnitPrice: item.originalUnitPrice,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                commissionRate: 0,
                commissionAmount: 0,
                totalCommissionAmount: 0,
                productDiscountValue: item.productDiscountValue,
                totalProductDiscountValue:
                  item.productDiscountValue * item.quantity,
                totalPrice: item.totalPrice,
                product:
                  item.productId && item.product
                    ? {
                        id: item.product.id,
                        ...(isAssignedForDelivery && {
                          merchantId: item.product.merchantId,
                          categoryId: item.product.categoryId,
                          category: item.product.category,
                          shortDescription: item.product.shortDescription,
                          description: item.product.description,
                          personCount: item.product.personCount,
                          price: item.product.price,
                          discount: item.product.discount,
                          discountType: item.product.discountType,
                          isAvailable: item.product.isAvailable,
                          hasStock: item.product.hasStock,
                          stockQuantity: item.product.stockQuantity,
                          isExternal: item.product.isExternal,
                          externalProvider: item.product.externalProvider,
                          externalId: item.product.externalId,
                          externalMetadata: item.product.externalMetadata,
                          commissionRate: 0,
                          commissionConfirmed: item.product.commissionConfirmed,
                          createdAt: item.product.createdAt,
                          updatedAt: item.product.updatedAt,
                        }),
                        name: item.product.name,
                        images: productImages.map((img) => ({
                          id: img.id,
                          url:
                            this.storageService.resolveUrl(img.url) || img.url,
                          mobileUrl: this.storageService.resolveUrl(
                            img.mobileUrl,
                          ),
                          thumbnailUrl: this.storageService.resolveUrl(
                            img.thumbnailUrl,
                          ),
                          isMain: img.isMain,
                        })),
                      }
                    : null,
              };
            })
        : [],
      offers,
      itemsTotal,
      offersTotal,
      subtotal,
      priceBeforeDiscount,
      discountAmount: order.discountAmount || 0,
      priceAfterProductDiscount: subtotal,
      productDiscount: priceBeforeDiscount - itemsTotal,
      offerDiscount: 0,
      tipAmount: order.tipAmount || 0,
      platformCommission: order.platformCommission || 0,
      ownerRevenue: order.ownerRevenue || 0,
      deliveryFee: order.deliveryFee || 0,
      totalAmount: order.totalAmount || 0,
      totalCommissionAmount: 0,
      currencyCode: order.currencyCode,
      mealPreparationTime: order.mealPreparationTime,
      deliveryTime: order.deliveryTime,
      deliveryId,
      delivery,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      ...((role === UserRole.ADMIN || role === UserRole.DELIVERY) &&
        (order as any).paymentReceipts &&
        (order as any).paymentReceipts.length > 0 && {
          receipts: (order as any).paymentReceipts.map((receipt: any) => {
            const img = receipt.image || receipt.paymentReceiptImage;
            return {
              id: receipt.id,
              imageId: receipt.imageId,
              url: this.storageService.resolveUrl(img?.url) || img?.url,
              thumbnailUrl:
                this.storageService.resolveUrl(img?.thumbnailUrl) ||
                img?.thumbnailUrl,
              mobileUrl:
                this.storageService.resolveUrl(img?.mobileUrl) ||
                img?.mobileUrl,
            };
          }),
        }),
    };

    if (remainingTime) {
      response.remainingTime = remainingTime;
    }

    if (tempEstimatedRoute) {
      const orderStatus = order.status;
      const hideForDeliveredStatuses = [
        OrderStatus.DELIVERED,
        OrderStatus.PAID,
        OrderStatus.COMPLETE,
      ];

      if (hideForDeliveredStatuses.includes(orderStatus)) {
        // Don't show estimatedRoute for DELIVERED, PAID, COMPLETE
      } else if (
        orderStatus === OrderStatus.PENDING ||
        orderStatus === OrderStatus.CONFIRMED ||
        orderStatus === OrderStatus.SEARCHING
      ) {
        // Show only merchantToCustomer
        response.estimatedRoute = {
          merchantToCustomer: tempEstimatedRoute.merchantToCustomer,
        };
      } else if (
        orderStatus === OrderStatus.ASSIGNED ||
        orderStatus === OrderStatus.READY_FOR_PICKUP
      ) {
        // Show driverToMerchant + merchantToCustomer
        response.estimatedRoute = {
          driverToMerchant: tempEstimatedRoute.driverToMerchant,
          merchantToCustomer: tempEstimatedRoute.merchantToCustomer,
        };
      } else {
        // Show all routes (PICKED_UP, ON_THE_WAY)
        response.estimatedRoute = tempEstimatedRoute;
      }
    }

    return response;
  }

  private async loadOrderData(order: Order): Promise<{
    products: Product[];
    offers: Offer[];
    productImagesMap: Map<number, Image[]>;
    offerImagesMap: Map<number, Image[]>;
  }> {
    const productIds = [
      ...new Set(order.items?.map((i) => i.productId).filter(Boolean) || []),
    ];
    const offerIds = order.offers?.map((o) => o.id) || [];

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

    const productImagesMap = new Map<number, Image[]>();
    for (const img of productImages) {
      if (!productImagesMap.has(img.entityId)) {
        productImagesMap.set(img.entityId, []);
      }
      productImagesMap.get(img.entityId)!.push(img);
    }

    const offerImagesMap = new Map<number, Image[]>();
    for (const img of offerImages) {
      if (!offerImagesMap.has(img.entityId)) {
        offerImagesMap.set(img.entityId, []);
      }
      offerImagesMap.get(img.entityId)!.push(img);
    }

    return { products, offers, productImagesMap, offerImagesMap };
  }
}
