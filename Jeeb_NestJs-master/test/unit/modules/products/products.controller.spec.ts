import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { ProductsController } from '../../../../src/modules/products/products.controller';
import { ProductsService } from '../../../../src/modules/products/products.service';
import { CreateProductDto } from '../../../../src/modules/products/dto/create-product.dto';
import { UpdateProductDto } from '../../../../src/modules/products/dto/update-product.dto';
import { GetProductsQueryDto } from '../../../../src/modules/products/dto/get-products-query.dto';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Product } from '../../../../src/database/entities/product.entity';

describe('ProductsController', () => {
  let controller: ProductsController;
  let productsService: jest.Mocked<ProductsService>;

  const mockProduct = { id: 1, name: 'Test Product', price: 100 } as Product;
  const mockUser = { id: 1, role: UserRole.MERCHANT } as any;
  const mockReq = { query: {} } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProductsController],
      providers: [
        {
          provide: ProductsService,
          useValue: {
            create: jest.fn(),
            findAll: jest.fn(),
            findOne: jest.fn(),
            update: jest.fn(),
            remove: jest.fn(),
            deleteImage: jest.fn(),
          },
        },
        { provide: JwtService, useValue: { signAsync: jest.fn(), decode: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn() } },
        Reflector,
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .compile();

    controller = module.get<ProductsController>(ProductsController);
    productsService = module.get(ProductsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create (POST /products)', () => {
    it('should call service.create with dto, files, userId, and role', async () => {
      const dto: CreateProductDto = { name: 'New', price: 100 } as any;
      const files = [{ filename: 'img.jpg' }] as Express.Multer.File[];
      productsService.create.mockResolvedValue(mockProduct);

      const result = await controller.create(dto, files, mockUser);

      expect(productsService.create).toHaveBeenCalledWith(dto, files, 1, UserRole.MERCHANT);
      expect(result).toEqual(mockProduct);
    });
  });

  describe('findAll (GET /products)', () => {
    it('should call service.findAll with query, userId, and role', async () => {
      const query: GetProductsQueryDto = { page: 1, limit: 10 };
      const paginatedResult = { data: [mockProduct], total: 1, page: 1, limit: 10 };
      productsService.findAll.mockResolvedValue(paginatedResult);

      const result = await controller.findAll(query, mockUser, mockReq);

      expect(productsService.findAll).toHaveBeenCalledWith(query, 1, UserRole.MERCHANT);
      expect(result).toEqual(paginatedResult);
    });

    it('should fallback merchantId from req.query', async () => {
      const query: GetProductsQueryDto = { page: 1, limit: 10 };
      const req = { query: { merchantId: '5' } };
      productsService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 });

      await controller.findAll(query, mockUser, req);

      expect(query.merchantId).toBe(5);
    });
  });

  describe('findOne (GET /products/:id)', () => {
    it('should call service.findOne with id, userId, and role', async () => {
      productsService.findOne.mockResolvedValue(mockProduct);

      const result = await controller.findOne('1', mockUser);

      expect(productsService.findOne).toHaveBeenCalledWith(1, 1, UserRole.MERCHANT);
      expect(result).toEqual(mockProduct);
    });
  });

  describe('update (PATCH /products/:id)', () => {
    it('should call service.update with id, dto, files, userId, and role', async () => {
      const dto: UpdateProductDto = { name: 'Updated' };
      const files = [] as Express.Multer.File[];
      productsService.update.mockResolvedValue(mockProduct);

      const result = await controller.update('1', dto, files, mockUser);

      expect(productsService.update).toHaveBeenCalledWith(1, dto, files, 1, UserRole.MERCHANT);
      expect(result).toEqual(mockProduct);
    });
  });

  describe('remove (DELETE /products/:id)', () => {
    it('should call service.remove with id, userId, and role', async () => {
      productsService.remove.mockResolvedValue({ message: 'Product deleted successfully' });

      const result = await controller.remove('1', mockUser);

      expect(productsService.remove).toHaveBeenCalledWith(1, 1, UserRole.MERCHANT);
      expect(result).toEqual({ message: 'Product deleted successfully' });
    });
  });
});
