import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Favorite } from '../../database/entities/favorite.entity';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { ToggleFavoriteDto } from './dto/toggle-favorite.dto';
import { FavoriteEntityType } from '../../common/enums/favorite-entity-type.enum';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { StorageService } from '../../common/storage/storage.service';

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoritesRepository: Repository<Favorite>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    private readonly storageService: StorageService,
  ) {}

  async toggleBulk(
    userId: number,
    dto: ToggleFavoriteDto,
  ): Promise<{
    products: {
      id: number;
      name: string;
      price: number;
      category: string | null;
    }[];
  }> {
    const addedProductIds: number[] = [];

    if (dto.products?.length) {
      for (const id of dto.products) {
        const isFavorite = await this.toggleSingle(
          userId,
          id,
          FavoriteEntityType.PRODUCT,
        );
        if (isFavorite) {
          addedProductIds.push(id);
        }
      }
    }

    let products: {
      id: number;
      name: string;
      price: number;
      category: string | null;
    }[] = [];

    if (addedProductIds.length) {
      const entities = await this.productRepository.find({
        where: { id: In(addedProductIds) },
        relations: ['category'],
      });
      products = entities.map((p) => ({
        id: p.id,
        name: p.name,
        price: p.price,
        category: p.category ? (p.category as any).name : null,
      }));
    }

    return { products };
  }

  private async toggleSingle(
    userId: number,
    entityId: number,
    entityType: FavoriteEntityType,
  ): Promise<boolean> {
    if (entityType === FavoriteEntityType.PRODUCT) {
      const exists = await this.productRepository.findOne({
        where: { id: entityId },
      });
      if (!exists)
        throw new NotFoundException(`Product with ID ${entityId} not found`);
    }

    const existingFavorite = await this.favoritesRepository.findOne({
      where: { userId, entityType, entityId },
    });

    if (existingFavorite) {
      await this.favoritesRepository.remove(existingFavorite);
      return false;
    } else {
      const favorite = this.favoritesRepository.create({
        userId,
        entityType,
        entityId,
      });
      await this.favoritesRepository.save(favorite);
      return true;
    }
  }

  async findAll(userId: number): Promise<{
    products: {
      id: number;
      name: string;
      price: number;
      category: string | null;
    }[];
  }> {
    const q = this.favoritesRepository
      .createQueryBuilder('favorite')
      .where('favorite.userId = :userId', { userId });

    const favorites = await q.getMany();

    if (favorites.length === 0) {
      return { products: [] };
    }

    const productIds = favorites
      .filter((f) => f.entityType === FavoriteEntityType.PRODUCT)
      .map((f) => f.entityId);

    let products: Product[] = [];

    if (productIds.length) {
      products = await this.productRepository.find({
        where: { id: In(productIds) },
        relations: ['category'],
      });
    }

    const productsList = products.map((p) => ({
      id: p.id,
      name: p.name,
      price: p.price,
      category: p.category ? (p.category as any).name : null,
    }));

    return { products: productsList };
  }

  async findAllPaginated(
    userId: number,
    query: PaginationQueryDto,
  ): Promise<{
    data: {
      products: {
        id: number;
        name: string;
        price: number;
        category: string | null;
        images: {
          id: number;
          url: string;
          mobileUrl: string | null;
          thumbnailUrl: string | null;
          isMain: boolean;
        }[];
      }[];
    }[];
    total: number;
    page: number;
    limit: number;
  }> {
    const favorites = await this.favoritesRepository.find({
      where: { userId },
    });

    const productIds = favorites
      .filter((f) => f.entityType === FavoriteEntityType.PRODUCT)
      .map((f) => f.entityId);

    let products: Product[] = [];
    if (productIds.length) {
      products = await this.productRepository.find({
        where: { id: In(productIds) },
        relations: ['category'],
      });
    }

    const images = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.PRODUCT,
        entityId: In(productIds),
      },
      order: {
        isMain: 'DESC',
        displayOrder: 'ASC',
      },
    });

    const imageMap = new Map<number, typeof images>();
    for (const img of images) {
      if (!imageMap.has(img.entityId)) {
        imageMap.set(img.entityId, []);
      }
      imageMap.get(img.entityId)!.push(img);
    }

    const productsList = products.map((p) => ({
      id: p.id,
      name: p.name,
      price: p.price,
      category: p.category ? (p.category as any).name : null,
      images: (imageMap.get(p.id) || []).map((img) => ({
        id: img.id,
        url: this.storageService.resolveUrl(img.url) || img.url,
        mobileUrl: this.storageService.resolveUrl(img.mobileUrl),
        thumbnailUrl: this.storageService.resolveUrl(img.thumbnailUrl),
        isMain: img.isMain,
      })),
    }));

    const page = Number(query?.page) || 1;
    const limit = Number(query?.limit) || 10;
    const start = (page - 1) * limit;
    const end = start + limit;

    const productsPage = productsList.slice(start, end);
    const dataObj = { products: productsPage };
    const total = productsList.length;

    return { data: [dataObj], total, page, limit } as any;
  }
}
