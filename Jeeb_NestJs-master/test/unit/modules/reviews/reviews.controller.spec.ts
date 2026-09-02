import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { ReviewsController } from '../../../../src/modules/reviews/reviews.controller';
import { ReviewsService } from '../../../../src/modules/reviews/reviews.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';

describe('ReviewsController', () => {
  let controller: ReviewsController;
  let reviewsService: jest.Mocked<ReviewsService>;

  const mockUser = (role: UserRole) => ({ id: 1, role });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReviewsController],
      providers: [
        {
          provide: ReviewsService,
          useValue: {
            create: jest.fn(),
            findAllByDriver: jest.fn(),
            findAllPublicByMerchant: jest.fn(),
            findAll: jest.fn(),
            findOne: jest.fn(),
            findOneForMerchant: jest.fn(),
            findOneForCustomer: jest.fn(),
            update: jest.fn(),
            updateForCustomer: jest.fn(),
            remove: jest.fn(),
            removeForCustomer: jest.fn(),
            findAllForMerchant: jest.fn(),
            findByProduct: jest.fn(),
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

    controller = module.get<ReviewsController>(ReviewsController);
    reviewsService = module.get(ReviewsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create (POST /reviews)', () => {
    it('should delegate to service with dto and user id', async () => {
      const dto = { entityType: 'product', entityId: 1, rating: 5, comment: 'Great' };
      const expected = { id: 1, ...dto };
      reviewsService.create.mockResolvedValue(expected as any);

      const result = await controller.create(dto as any, mockUser(UserRole.CUSTOMER));

      expect(reviewsService.create).toHaveBeenCalledWith(dto, 1);
      expect(result).toEqual(expected);
    });
  });

  describe('findByDriver (GET /reviews/driver/:driverId)', () => {
    it('should delegate to service', async () => {
      const query = { page: 1, limit: 10 };
      reviewsService.findAllByDriver.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findByDriver(5, query);

      expect(reviewsService.findAllByDriver).toHaveBeenCalledWith(5, query);
    });
  });

  describe('findByMerchant (GET /reviews/merchant/:merchantId)', () => {
    it('should delegate to service', async () => {
      const query = { page: 1, limit: 10 };
      reviewsService.findAllPublicByMerchant.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findByMerchant(3, query);

      expect(reviewsService.findAllPublicByMerchant).toHaveBeenCalledWith(3, query);
    });
  });

  describe('findAll (GET /reviews)', () => {
    it('should call findAll when user is admin', async () => {
      const query = { page: 1, limit: 10 };
      reviewsService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query, mockUser(UserRole.ADMIN));

      expect(reviewsService.findAll).toHaveBeenCalledWith(query);
      expect(reviewsService.findAllForMerchant).not.toHaveBeenCalled();
    });

    it('should call findAllForMerchant when user is merchant', async () => {
      const query = { page: 1, limit: 10 };
      reviewsService.findAllForMerchant.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query, mockUser(UserRole.MERCHANT));

      expect(reviewsService.findAllForMerchant).toHaveBeenCalledWith(1, query);
    });
  });

  describe('findOne (GET /reviews/:id)', () => {
    it('should call findOne for admin', async () => {
      reviewsService.findOne.mockResolvedValue({ id: 1 } as any);

      await controller.findOne(1, mockUser(UserRole.ADMIN));

      expect(reviewsService.findOne).toHaveBeenCalledWith(1);
    });

    it('should call findOneForMerchant for merchant', async () => {
      reviewsService.findOneForMerchant.mockResolvedValue({ id: 1 } as any);

      await controller.findOne(1, mockUser(UserRole.MERCHANT));

      expect(reviewsService.findOneForMerchant).toHaveBeenCalledWith(1, 1);
    });

    it('should call findOneForCustomer for customer', async () => {
      reviewsService.findOneForCustomer.mockResolvedValue({ id: 1 } as any);

      await controller.findOne(1, mockUser(UserRole.CUSTOMER));

      expect(reviewsService.findOneForCustomer).toHaveBeenCalledWith(1, 1);
    });
  });

  describe('update (PATCH /reviews/:id)', () => {
    it('should call updateForCustomer for customer', async () => {
      const dto = { rating: 4 };
      reviewsService.updateForCustomer.mockResolvedValue({ id: 1 } as any);

      await controller.update(1, dto as any, mockUser(UserRole.CUSTOMER));

      expect(reviewsService.updateForCustomer).toHaveBeenCalledWith(1, dto, 1);
    });

    it('should call update for admin', async () => {
      const dto = { rating: 4 };
      reviewsService.update.mockResolvedValue({ id: 1 } as any);

      await controller.update(1, dto as any, mockUser(UserRole.ADMIN));

      expect(reviewsService.update).toHaveBeenCalledWith(1, dto);
    });
  });

  describe('remove (DELETE /reviews/:id)', () => {
    it('should call removeForCustomer for customer', async () => {
      reviewsService.removeForCustomer.mockResolvedValue({ id: 1 } as any);

      await controller.remove(1, mockUser(UserRole.CUSTOMER));

      expect(reviewsService.removeForCustomer).toHaveBeenCalledWith(1, 1);
    });

    it('should call remove for admin', async () => {
      reviewsService.remove.mockResolvedValue({ id: 1 } as any);

      await controller.remove(1, mockUser(UserRole.ADMIN));

      expect(reviewsService.remove).toHaveBeenCalledWith(1);
    });
  });

  describe('findByProduct (GET /reviews/product/:productId)', () => {
    it('should delegate to service', async () => {
      const query = { page: 1, limit: 10 };
      reviewsService.findByProduct.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findByProduct(1, query);

      expect(reviewsService.findByProduct).toHaveBeenCalledWith(1, query);
    });
  });
});
