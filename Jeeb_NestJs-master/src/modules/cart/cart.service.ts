import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';
import type Redis from 'ioredis';
import { Cart } from '../../database/entities/cart.entity';
import { CartItem } from '../../database/entities/cart-item.entity';
import { CartOffer } from '../../database/entities/cart-offer.entity';
import { Product } from '../../database/entities/product.entity';
import { Offer } from '../../database/entities/offer.entity';
import { User } from '../../database/entities/user.entity';
import { Merchant } from '../../database/entities/merchant.entity';
import { Image } from '../../database/entities/image.entity';
import { ImageEntityType } from '../../common/enums';
import { DiscountType } from '../../common/enums';
import { StorageService } from '../../common/storage/storage.service';
import {
  CreateCartDto,
  CartItemDto,
  CartOfferDto,
} from './dto/create-cart.dto';
import {
  UpdateCartActionsDto,
  CartItemInputDto,
  CartOfferInputDto,
} from './dto/update-cart.dto';
import {
  CartResponseDto,
  CartItemResponseDto,
  CartOfferResponseDto,
  CartSummaryDto,
  ProductInfoDto,
  OfferProductInfoDto,
} from './dto/cart-response.dto';

@Injectable()
export class CartService {
  constructor(
    @InjectRepository(Cart)
    private readonly cartRepo: Repository<Cart>,
    @InjectRepository(CartItem)
    private readonly cartItemRepo: Repository<CartItem>,
    @InjectRepository(CartOffer)
    private readonly cartOfferRepo: Repository<CartOffer>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Offer)
    private readonly offerRepo: Repository<Offer>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Merchant)
    private readonly merchantRepo: Repository<Merchant>,
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    private readonly dataSource: DataSource,
    private readonly storageService: StorageService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  private guestCartKey(customerId: number): string {
    return `guest:cart:${customerId}`;
  }
  private readonly GUEST_TTL = 5 * 24 * 60 * 60;

  async getCart(customerId: number, isGuest = false): Promise<CartResponseDto | null> {
    if (isGuest) {
      const raw = await this.redis.get(this.guestCartKey(customerId));
      if (!raw) return null;
      const stored = JSON.parse(raw);
      return this.buildGuestCartResponse(customerId, stored);
    }
    const cart = await this.cartRepo.findOne({
      where: { customerId },
      relations: [
        'customer',
        'merchant',
        'items',
        'items.product',
        'offers',
        'offers.offer',
        'offers.offer.offerProducts',
        'offers.offer.offerProducts.product',
      ],
    });

    if (!cart) {
      return null;
    }

    return this.buildCartResponse(cart);
  }

  async createCart(
    customerId: number,
    dto: CreateCartDto,
    isGuest = false,
  ): Promise<CartResponseDto> {
    if (isGuest) {
      let merchantId: number | null = null;
      if (dto.items?.length) {
        const ids = dto.items.map((i) => i.productId);
        const products = await this.productRepo.find({ where: { id: In(ids) } });
        for (const item of dto.items) {
          const p = products.find((x) => x.id === item.productId);
          if (!p) throw new NotFoundException(`Product with id ${item.productId} not found`);
          if (!p.isAvailable) throw new BadRequestException(`Product ${p.name} is not available`);
          if (!merchantId) merchantId = p.merchantId;
          else if (p.merchantId !== merchantId) throw new BadRequestException('All items must be from the same merchant');
        }
      }
      if (dto.offers?.length) {
        const ids = dto.offers.map((o) => o.offerId);
        const offers = await this.offerRepo.find({ where: { id: In(ids) }, relations: ['offerProducts', 'offerProducts.product'] });
        for (const o of dto.offers) {
          const offer = offers.find((x) => x.id === o.offerId);
          if (!offer) throw new NotFoundException(`Offer with id ${o.offerId} not found`);
          if (!offer.isActive) throw new BadRequestException(`Offer ${offer.name} is not active`);
          if (!merchantId) merchantId = offer.merchantId;
          else if (offer.merchantId !== merchantId) throw new BadRequestException('All items must be from the same merchant');
        }
      }
      const stored = { items: dto.items || [], offers: dto.offers || [], merchantId };
      await this.redis.set(this.guestCartKey(customerId), JSON.stringify(stored), 'EX', this.GUEST_TTL);
      return this.buildGuestCartResponse(customerId, stored);
    }
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      let cart = await this.cartRepo.findOne({
        where: { customerId },
        relations: ['items', 'offers'],
      });

      if (cart) {
        await queryRunner.manager.remove(cart.items);
        await queryRunner.manager.remove(cart.offers);
      } else {
        cart = this.cartRepo.create({ customerId });
        await queryRunner.manager.save(cart);
      }

      let merchantId: number | null = null;

      if (dto.items && dto.items.length > 0) {
        const productIds = dto.items.map((i) => i.productId);
        const products = await this.productRepo.find({
          where: { id: In(productIds) },
        });

        for (const item of dto.items) {
          const product = products.find((p) => p.id === item.productId);
          if (!product) {
            throw new NotFoundException(
              `Product with id ${item.productId} not found`,
            );
          }

          if (!product.isAvailable) {
            throw new BadRequestException(
              `Product ${product.name} is not available`,
            );
          }

          if (!merchantId) {
            merchantId = product.merchantId;
          } else if (product.merchantId !== merchantId) {
            throw new BadRequestException(
              'All items must be from the same merchant',
            );
          }

          const cartItem = this.cartItemRepo.create({
            cartId: cart.id,
            productId: product.id,
            quantity: item.quantity,
          });
          await queryRunner.manager.save(cartItem);
        }
      }

      if (dto.offers && dto.offers.length > 0) {
        const offerIds = dto.offers.map((o) => o.offerId);
        const offers = await this.offerRepo.find({
          where: { id: In(offerIds) },
          relations: ['offerProducts', 'offerProducts.product'],
        });

        for (const offerInput of dto.offers) {
          const offer = offers.find((o) => o.id === offerInput.offerId);
          if (!offer) {
            throw new NotFoundException(
              `Offer with id ${offerInput.offerId} not found`,
            );
          }

          if (!offer.isActive) {
            throw new BadRequestException(`Offer ${offer.name} is not active`);
          }

          for (const offerProduct of offer.offerProducts || []) {
            if (offerProduct.product && !offerProduct.product.isAvailable) {
              throw new BadRequestException(
                `Product ${offerProduct.product.name} in offer ${offer.name} is not available`,
              );
            }
          }

          if (!merchantId) {
            merchantId = offer.merchantId;
          } else if (offer.merchantId !== merchantId) {
            throw new BadRequestException(
              'All items must be from the same merchant',
            );
          }

          const cartOffer = this.cartOfferRepo.create({
            cartId: cart.id,
            offerId: offer.id,
            quantity: offerInput.quantity,
          });
          await queryRunner.manager.save(cartOffer);
        }
      }

      cart.merchantId = merchantId;
      await queryRunner.manager.save(cart);

      await queryRunner.commitTransaction();

      const result = await this.getCart(customerId);
      return result!;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async updateCart(
    customerId: number,
    dto: UpdateCartActionsDto,
    isGuest = false,
  ): Promise<CartResponseDto> {
    if (isGuest) {
      const raw = await this.redis.get(this.guestCartKey(customerId));
      if (!raw) throw new NotFoundException('Cart not found');
      const stored: any = JSON.parse(raw);
      if (dto.add) {
        if (dto.add.items) {
          for (const it of dto.add.items) {
            const existing = stored.items.find((x: any) => x.productId === it.productId);
            if (existing) existing.quantity += it.quantity;
            else stored.items.push({ productId: it.productId, quantity: it.quantity });
          }
        }
        if (dto.add.offers) {
          for (const it of dto.add.offers) {
            const existing = stored.offers.find((x: any) => x.offerId === it.offerId);
            if (existing) existing.quantity += it.quantity;
            else stored.offers.push({ offerId: it.offerId, quantity: it.quantity });
          }
        }
      }
      if (dto.update) {
        for (const it of dto.update.items || []) {
          const ex = stored.items.find((x: any) => x.productId === it.productId);
          if (ex) ex.quantity = it.quantity;
        }
        for (const it of dto.update.offers || []) {
          const ex = stored.offers.find((x: any) => x.offerId === it.offerId);
          if (ex) ex.quantity = it.quantity;
        }
      }
      if (dto.remove) {
        if (dto.remove.items) stored.items = stored.items.filter((x: any) => !dto.remove!.items!.includes(x.productId));
        if (dto.remove.offers) stored.offers = stored.offers.filter((x: any) => !dto.remove!.offers!.includes(x.offerId));
      }
      await this.redis.set(this.guestCartKey(customerId), JSON.stringify(stored), 'EX', this.GUEST_TTL);
      return this.buildGuestCartResponse(customerId, stored);
    }
    const cart = await this.cartRepo.findOne({
      where: { customerId },
      relations: ['items', 'offers', 'items.product', 'offers.offer'],
    });

    if (!cart) {
      throw new NotFoundException('Cart not found');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      if (dto.add) {
        await this.addToCart(queryRunner, cart, dto.add);
      }

      if (dto.update) {
        await this.updateCartItems(queryRunner, cart, dto.update);
      }

      if (dto.remove) {
        await this.removeFromCart(queryRunner, cart, dto.remove);
      }

      await queryRunner.commitTransaction();

      const result = await this.getCart(customerId);
      return result!;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async clearCart(customerId: number, isGuest = false): Promise<void> {
    if (isGuest) {
      await this.redis.del(this.guestCartKey(customerId));
      return;
    }
    const cart = await this.cartRepo.findOne({
      where: { customerId },
    });

    if (!cart) {
      throw new NotFoundException('Cart not found');
    }

    await this.cartRepo.remove(cart);
  }

  private async addToCart(
    queryRunner: any,
    cart: Cart,
    dto: { items?: CartItemInputDto[]; offers?: CartOfferInputDto[] },
  ): Promise<void> {
    let merchantId = cart.merchantId;

    if (dto.items && dto.items.length > 0) {
      const productIds = dto.items.map((i) => i.productId);
      const products = await this.productRepo.find({
        where: { id: In(productIds) },
      });

      for (const item of dto.items) {
        const product = products.find((p) => p.id === item.productId);
        if (!product) {
          throw new NotFoundException(
            `Product with id ${item.productId} not found`,
          );
        }

        if (!product.isAvailable) {
          throw new BadRequestException(
            `Product ${product.name} is not available`,
          );
        }

        if (!merchantId) {
          merchantId = product.merchantId;
        } else if (product.merchantId !== merchantId) {
          throw new BadRequestException(
            'All items must be from the same merchant',
          );
        }

        const existingItem = cart.items.find(
          (i) => i.productId === item.productId,
        );
        if (existingItem) {
          existingItem.quantity += item.quantity;
          await queryRunner.manager.save(existingItem);
        } else {
          const cartItem = this.cartItemRepo.create({
            cartId: cart.id,
            productId: product.id,
            quantity: item.quantity,
          });
          await queryRunner.manager.save(cartItem);
        }
      }
    }

    if (dto.offers && dto.offers.length > 0) {
      const offerIds = dto.offers.map((o) => o.offerId);
      const offers = await this.offerRepo.find({
        where: { id: In(offerIds) },
        relations: ['offerProducts', 'offerProducts.product'],
      });

      for (const offerInput of dto.offers) {
        const offer = offers.find((o) => o.id === offerInput.offerId);
        if (!offer) {
          throw new NotFoundException(
            `Offer with id ${offerInput.offerId} not found`,
          );
        }

        if (!offer.isActive) {
          throw new BadRequestException(`Offer ${offer.name} is not active`);
        }

        if (!merchantId) {
          merchantId = offer.merchantId;
        } else if (offer.merchantId !== merchantId) {
          throw new BadRequestException(
            'All items must be from the same merchant',
          );
        }

        const existingOffer = cart.offers.find(
          (o) => o.offerId === offerInput.offerId,
        );
        if (existingOffer) {
          existingOffer.quantity += offerInput.quantity;
          await queryRunner.manager.save(existingOffer);
        } else {
          const cartOffer = this.cartOfferRepo.create({
            cartId: cart.id,
            offerId: offer.id,
            quantity: offerInput.quantity,
          });
          await queryRunner.manager.save(cartOffer);
        }
      }
    }

    if (merchantId && cart.merchantId !== merchantId) {
      cart.merchantId = merchantId;
      await queryRunner.manager.save(cart);
    }
  }

  private async updateCartItems(
    queryRunner: any,
    cart: Cart,
    dto: { items?: CartItemInputDto[]; offers?: CartOfferInputDto[] },
  ): Promise<void> {
    if (dto.items && dto.items.length > 0) {
      for (const item of dto.items) {
        const existingItem = cart.items.find(
          (i) => i.productId === item.productId,
        );
        if (existingItem) {
          existingItem.quantity = item.quantity;
          await queryRunner.manager.save(existingItem);
        }
      }
    }

    if (dto.offers && dto.offers.length > 0) {
      for (const offerInput of dto.offers) {
        const existingOffer = cart.offers.find(
          (o) => o.offerId === offerInput.offerId,
        );
        if (existingOffer) {
          existingOffer.quantity = offerInput.quantity;
          await queryRunner.manager.save(existingOffer);
        }
      }
    }
  }

  private async removeFromCart(
    queryRunner: any,
    cart: Cart,
    dto: { items?: number[]; offers?: number[] },
  ): Promise<void> {
    if (dto.items && dto.items.length > 0) {
      for (const productId of dto.items) {
        const item = cart.items.find((i) => i.productId === productId);
        if (item) {
          await queryRunner.manager.remove(item);
        }
      }
    }

    if (dto.offers && dto.offers.length > 0) {
      for (const offerId of dto.offers) {
        const offer = cart.offers.find((o) => o.offerId === offerId);
        if (offer) {
          await queryRunner.manager.remove(offer);
        }
      }
    }

    const updatedCart = await this.cartRepo.findOne({
      where: { id: cart.id },
      relations: ['items', 'offers'],
    });

    if (
      updatedCart &&
      updatedCart.items.length === 0 &&
      updatedCart.offers.length === 0
    ) {
      updatedCart.merchantId = null;
      await queryRunner.manager.save(updatedCart);
    }
  }

  private async buildCartResponse(cart: Cart): Promise<CartResponseDto> {
    let itemsSubtotal = 0;
    let offersSubtotal = 0;
    let totalDiscount = 0;

    const allProductIds: number[] = [];
    const allOfferIds: number[] = [];

    for (const item of cart.items || []) {
      if (item.productId) allProductIds.push(item.productId);
    }
    for (const cartOffer of cart.offers || []) {
      if (cartOffer.offerId) allOfferIds.push(cartOffer.offerId);
    }

    const [productImages, offerImages] = await Promise.all([
      allProductIds.length > 0
        ? this.imageRepo.find({
            where: {
              entityType: ImageEntityType.PRODUCT,
              entityId: In(allProductIds),
            },
            order: { isMain: 'DESC', displayOrder: 'ASC' },
          })
        : Promise.resolve([]),
      allOfferIds.length > 0
        ? this.imageRepo.find({
            where: {
              entityType: ImageEntityType.OFFER,
              entityId: In(allOfferIds),
            },
            order: { isMain: 'DESC', displayOrder: 'ASC' },
          })
        : Promise.resolve([]),
    ]);

    const productImagesMap = new Map<number, any[]>();
    const offerImagesMap = new Map<number, any[]>();

    for (const img of productImages) {
      if (!productImagesMap.has(img.entityId)) {
        productImagesMap.set(img.entityId, []);
      }
      productImagesMap.get(img.entityId)!.push({
        id: img.id,
        url: this.storageService.resolveUrl(img.url),
        mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
        thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl),
        isMain: img.isMain,
      });
    }

    for (const img of offerImages) {
      if (!offerImagesMap.has(img.entityId)) {
        offerImagesMap.set(img.entityId, []);
      }
      offerImagesMap.get(img.entityId)!.push({
        id: img.id,
        url: this.storageService.resolveUrl(img.url),
        mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
        thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl),
        isMain: img.isMain,
      });
    }

    const cartItems: CartItemResponseDto[] = [];
    for (const item of cart.items || []) {
      const product = item.product;
      const unitPrice = product?.price || 0;
      const totalPrice = unitPrice * item.quantity;
      itemsSubtotal += totalPrice;

      if (product) {
        const images = productImagesMap.get(product.id) || [];

        cartItems.push({
          id: item.id,
          product: {
            id: product.id,
            name: product.name,
            shortDescription: product.shortDescription,
            description: product.description,
            personCount: product.personCount,
            price: unitPrice,
            discount: product.discount,
            discountType: product.discountType,
            isAvailable: product.isAvailable,
            hasStock: product.hasStock,
            stockQuantity: product.stockQuantity,
            images,
          },
          quantity: item.quantity,
          unitPrice,
          totalPrice,
          createdAt: item.createdAt,
        });
      }
    }

    const cartOffers: CartOfferResponseDto[] = [];
    for (const cartOffer of cart.offers || []) {
      const offer = cartOffer.offer;
      if (!offer) continue;

      let offerSubtotal = 0;
      const offerProductsData: OfferProductInfoDto[] = [];

      for (const offerProduct of offer.offerProducts || []) {
        if (!offerProduct.product) continue;
        const productPrice = offerProduct.product.price;
        offerSubtotal += productPrice * cartOffer.quantity;

        const productImages =
          productImagesMap.get(offerProduct.product.id) || [];

        offerProductsData.push({
          id: offerProduct.product.id,
          name: offerProduct.product.name,
          price: productPrice,
          shortDescription: offerProduct.product.shortDescription,
          discount: offerProduct.product.discount,
          discountType: offerProduct.product.discountType,
          isAvailable: offerProduct.product.isAvailable,
          hasStock: offerProduct.product.hasStock,
          stockQuantity: offerProduct.product.stockQuantity,
          images: productImages,
        });
      }

      offersSubtotal += offerSubtotal;

      let discount = 0;
      if (offer.discountType === DiscountType.PERCENTAGE) {
        discount = Math.floor((offerSubtotal * offer.discountValue) / 100);
      } else if (offer.discountType === DiscountType.FIXED) {
        discount = Math.min(offer.discountValue, offerSubtotal);
      }
      totalDiscount += discount;

      const offerImages = offerImagesMap.get(offer.id) || [];

      cartOffers.push({
        id: cartOffer.id,
        offer: {
          id: offer.id,
          name: offer.name,
          description: offer.description,
          discountType: offer.discountType,
          discountValue: offer.discountValue,
          isActive: offer.isActive,
          images: offerImages,
          products: offerProductsData,
        },
        quantity: cartOffer.quantity,
        subtotal: offerSubtotal,
        discount,
        createdAt: cartOffer.createdAt,
      });
    }

    const totalSubtotal = itemsSubtotal + offersSubtotal;
    const finalTotal = totalSubtotal - totalDiscount;
    const platformCommission = Math.round(finalTotal * 0.1);
    const merchantRevenue = finalTotal - platformCommission;

    let merchantInfo: any = null;
    if (cart.merchantId) {
      const merchant = await this.merchantRepo.findOne({
        where: { userId: cart.merchantId },
        relations: ['user'],
      });
      if (merchant) {
        merchantInfo = {
          id: merchant.userId,
          restaurantName: merchant.restaurantName,
          phone: merchant.user?.phone || null,
          address: merchant.user?.address || null,
        };
      }
    }

    return {
      id: cart.id,
      customer: {
        id: cart.customer?.id || cart.customerId,
        firstName: cart.customer?.firstName || '',
        lastName: cart.customer?.lastName || '',
        phone: cart.customer?.phone || null,
      },
      merchant: merchantInfo,
      items: cartItems,
      offers: cartOffers,
      summary: {
        itemsSubtotal,
        offersSubtotal,
        totalSubtotal,
        totalDiscount,
        finalTotal,
        platformCommission,
        merchantRevenue,
      },
    };
  }

  private async buildGuestCartResponse(customerId: number, stored: any): Promise<CartResponseDto> {
    const items: any[] = stored.items || [];
    const offers: any[] = stored.offers || [];
    const productIds = items.map((i: any) => i.productId);
    const offerIds = offers.map((o: any) => o.offerId);
    const [products, offerEntities, productImages, offerImages] = await Promise.all([
      productIds.length ? this.productRepo.find({ where: { id: In(productIds) } }) : Promise.resolve([] as Product[]),
      offerIds.length ? this.offerRepo.find({ where: { id: In(offerIds) }, relations: ['offerProducts', 'offerProducts.product'] }) : Promise.resolve([] as Offer[]),
      productIds.length ? this.imageRepo.find({ where: { entityType: ImageEntityType.PRODUCT, entityId: In(productIds) }, order: { isMain: 'DESC', displayOrder: 'ASC' } }) : Promise.resolve([]),
      offerIds.length ? this.imageRepo.find({ where: { entityType: ImageEntityType.OFFER, entityId: In(offerIds) }, order: { isMain: 'DESC', displayOrder: 'ASC' } }) : Promise.resolve([]),
    ]);

    const productImagesMap = new Map<number, any[]>();
    for (const img of productImages as any[]) {
      if (!productImagesMap.has(img.entityId)) productImagesMap.set(img.entityId, []);
      productImagesMap.get(img.entityId)!.push({ id: img.id, url: this.storageService.resolveUrl(img.url), mobileUrl: this.storageService.resolveUrl(img.mobileUrl), thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl), isMain: img.isMain });
    }
    const offerImagesMap = new Map<number, any[]>();
    for (const img of offerImages as any[]) {
      if (!offerImagesMap.has(img.entityId)) offerImagesMap.set(img.entityId, []);
      offerImagesMap.get(img.entityId)!.push({ id: img.id, url: this.storageService.resolveUrl(img.url), mobileUrl: this.storageService.resolveUrl(img.mobileUrl), thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl), isMain: img.isMain });
    }

    let itemsSubtotal = 0;
    const cartItems: any[] = [];
    for (const it of items) {
      const p = (products as Product[]).find((x) => x.id === it.productId);
      if (!p) continue;
      const unitPrice = (p as any).price || 0;
      const totalPrice = unitPrice * it.quantity;
      itemsSubtotal += totalPrice;
      cartItems.push({
        id: it.productId,
        product: {
          id: p.id,
          name: (p as any).name,
          shortDescription: (p as any).shortDescription,
          description: (p as any).description,
          personCount: (p as any).personCount,
          price: unitPrice,
          discount: (p as any).discount,
          discountType: (p as any).discountType,
          isAvailable: (p as any).isAvailable,
          hasStock: (p as any).hasStock,
          stockQuantity: (p as any).stockQuantity,
          images: productImagesMap.get(p.id) || [],
        },
        quantity: it.quantity,
        unitPrice,
        totalPrice,
        createdAt: new Date(),
      });
    }

    let offersSubtotal = 0;
    let totalDiscount = 0;
    const cartOffers: any[] = [];
    for (const co of offers) {
      const offer = (offerEntities as Offer[]).find((x) => x.id === co.offerId);
      if (!offer) continue;
      let subtotal = 0;
      const prods: any[] = [];
      for (const op of (offer as any).offerProducts || []) {
        if (!op.product) continue;
        const pp = unitPriceFor(op.product);
        subtotal += pp * co.quantity;
        prods.push({ id: op.product.id, name: op.product.name, price: pp, shortDescription: op.product.shortDescription, discount: op.product.discount, discountType: op.product.discountType, isAvailable: op.product.isAvailable, hasStock: op.product.hasStock, stockQuantity: op.product.stockQuantity, images: productImagesMap.get(op.product.id) || [] });
      }
      offersSubtotal += subtotal;
      let discount = 0;
      if ((offer as any).discountType === DiscountType.PERCENTAGE) discount = Math.floor((subtotal * (offer as any).discountValue) / 100);
      else if ((offer as any).discountType === DiscountType.FIXED) discount = Math.min((offer as any).discountValue, subtotal);
      totalDiscount += discount;
      cartOffers.push({ id: offer.id, offer: { id: offer.id, name: (offer as any).name, description: (offer as any).description, discountType: (offer as any).discountType, discountValue: (offer as any).discountValue, isActive: (offer as any).isActive, images: offerImagesMap.get(offer.id) || [], products: prods }, quantity: co.quantity, subtotal, discount, createdAt: new Date() });
    }
    function unitPriceFor(pr: any) { return pr.price || 0; }

    const totalSubtotal = itemsSubtotal + offersSubtotal;
    const finalTotal = totalSubtotal - totalDiscount;
    let merchantInfo: any = null;
    const mid = stored.merchantId;
    if (mid) {
      const m = await this.merchantRepo.findOne({ where: { userId: mid }, relations: ['user'] });
      if (m) merchantInfo = { id: m.userId, restaurantName: m.restaurantName, phone: m.user?.phone || null, address: m.user?.address || null };
    }
    return {
      id: customerId,
      customer: { id: customerId, firstName: 'Guest', lastName: 'User', phone: null },
      merchant: merchantInfo,
      items: cartItems,
      offers: cartOffers,
      summary: { itemsSubtotal, offersSubtotal, totalSubtotal, totalDiscount, finalTotal, platformCommission: Math.round(finalTotal * 0.1), merchantRevenue: finalTotal - Math.round(finalTotal * 0.1) },
    } as any;
  }
}
