import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { OffersController } from '../../../../src/modules/offers/offers.controller';
import { OffersService } from '../../../../src/modules/offers/offers.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';

describe('OffersController', () => {
  let controller: OffersController;
  let offersService: jest.Mocked<OffersService>;

  const mockOffer = { id: 1, name: 'Test Offer', merchantId: 1 };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OffersController],
      providers: [
        {
          provide: OffersService,
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

    controller = module.get<OffersController>(OffersController);
    offersService = module.get(OffersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create (POST /offers)', () => {
    it('should delegate with dto, user id, and role', async () => {
      const dto = { name: 'New Offer', discountType: 'percentage', discountValue: 10, products: [{ productId: 1, quantity: 1 }] } as any;
      const user = { id: 1, role: UserRole.MERCHANT };
      offersService.create.mockResolvedValue(mockOffer as any);

      const result = await controller.create(dto, user);

      expect(offersService.create).toHaveBeenCalledWith(dto, 1, UserRole.MERCHANT);
      expect(result).toEqual(mockOffer);
    });
  });

  describe('findAll (GET /offers)', () => {
    it('should delegate with query and user', async () => {
      const query = { page: 1, limit: 10 };
      const user = { id: 1, role: UserRole.ADMIN };
      offersService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query as any, user);

      expect(offersService.findAll).toHaveBeenCalledWith(query, 1, UserRole.ADMIN);
    });
  });

  describe('findOne (GET /offers/:id)', () => {
    it('should delegate with id', async () => {
      offersService.findOne.mockResolvedValue(mockOffer as any);

      const result = await controller.findOne('1');

      expect(offersService.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockOffer);
    });
  });

  describe('update (PATCH /offers/:id)', () => {
    it('should delegate with id, dto, user id, and role', async () => {
      const dto = { name: 'Updated' };
      const user = { id: 1, role: UserRole.ADMIN };
      offersService.update.mockResolvedValue(mockOffer as any);

      const result = await controller.update('1', dto as any, user);

      expect(offersService.update).toHaveBeenCalledWith(1, dto, 1, UserRole.ADMIN);
      expect(result).toEqual(mockOffer);
    });
  });

  describe('remove (DELETE /offers/:id)', () => {
    it('should delegate with id, user id, and role', async () => {
      const user = { id: 1, role: UserRole.ADMIN };
      offersService.remove.mockResolvedValue(undefined);

      await controller.remove('1', user);

      expect(offersService.remove).toHaveBeenCalledWith(1, 1, UserRole.ADMIN);
    });
  });
});
