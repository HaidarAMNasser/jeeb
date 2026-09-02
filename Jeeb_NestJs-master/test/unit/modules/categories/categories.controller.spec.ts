import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { CategoriesController } from '../../../../src/modules/categories/categories.controller';
import { CategoriesService } from '../../../../src/modules/categories/categories.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';

describe('CategoriesController', () => {
  let controller: CategoriesController;
  let categoriesService: jest.Mocked<CategoriesService>;

  const mockCategory = { id: 1, name: 'Test Category' };
  const mockUser = { id: 1, role: UserRole.ADMIN };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CategoriesController],
      providers: [
        {
          provide: CategoriesService,
          useValue: {
            create: jest.fn(),
            findAll: jest.fn(),
            findOne: jest.fn(),
            update: jest.fn(),
            remove: jest.fn(),
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

    controller = module.get<CategoriesController>(CategoriesController);
    categoriesService = module.get(CategoriesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create (POST /categories)', () => {
    it('should delegate with dto, file, and user', async () => {
      const dto = { name: 'New Category' };
      const file = { buffer: Buffer.from('test') } as Express.Multer.File;
      categoriesService.create.mockResolvedValue(mockCategory as any);

      const result = await controller.create(dto as any, file, mockUser);

      expect(categoriesService.create).toHaveBeenCalledWith(dto, file, 1, UserRole.ADMIN);
      expect(result).toEqual(mockCategory);
    });
  });

  describe('findAll (GET /categories)', () => {
    it('should delegate to service', async () => {
      const query = { page: 1, limit: 10 };
      categoriesService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query as any);

      expect(categoriesService.findAll).toHaveBeenCalledWith(query);
    });
  });

  describe('findOne (GET /categories/:id)', () => {
    it('should delegate to service', async () => {
      categoriesService.findOne.mockResolvedValue(mockCategory as any);

      const result = await controller.findOne('1');

      expect(categoriesService.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockCategory);
    });
  });

  describe('update (PATCH /categories/:id)', () => {
    it('should delegate with id, dto, file, and user', async () => {
      const dto = { name: 'Updated Category' };
      const file = { buffer: Buffer.from('test') } as Express.Multer.File;
      categoriesService.update.mockResolvedValue(mockCategory as any);

      const result = await controller.update('1', dto as any, file, mockUser);

      expect(categoriesService.update).toHaveBeenCalledWith(1, dto, file, 1, UserRole.ADMIN);
      expect(result).toEqual(mockCategory);
    });
  });

  describe('remove (DELETE /categories/:id)', () => {
    it('should delegate to service', async () => {
      categoriesService.remove.mockResolvedValue(undefined);

      await controller.remove('1', mockUser);

      expect(categoriesService.remove).toHaveBeenCalledWith(1, 1, UserRole.ADMIN);
    });
  });
});
