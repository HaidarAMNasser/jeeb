import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { UsersController } from '../../../../src/modules/users/users.controller';
import { UsersService } from '../../../../src/modules/users/users.service';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { CreateCustomerDto } from '../../../../src/modules/users/dto/create-customer.dto';
import { CreateMerchantDto } from '../../../../src/modules/users/dto/create-merchant.dto';
import { CreateDeliveryDto } from '../../../../src/modules/users/dto/create-delivery.dto';
import { UpdateCustomerDto } from '../../../../src/modules/users/dto/update-customer.dto';
import { UpdateMerchantDto } from '../../../../src/modules/users/dto/update-merchant.dto';
import { UpdateDeliveryDto } from '../../../../src/modules/users/dto/update-delivery.dto';
import { CustomerFilterDto } from '../../../../src/modules/users/dto/customer-filter.dto';
import { MerchantFilterDto } from '../../../../src/modules/users/dto/merchant-filter.dto';
import { DeliveryFilterDto } from '../../../../src/modules/users/dto/delivery-filter.dto';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';
import { User } from '../../../../src/database/entities/user.entity';

describe('UsersController', () => {
  let controller: UsersController;
  let usersService: jest.Mocked<UsersService>;
  let merchantsService: jest.Mocked<MerchantsService>;
  let storageService: jest.Mocked<StorageService>;

  const mockUser = { id: 1, email: 'test@test.com', role: 'CUSTOMER' } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: {
            findAllCustomers: jest.fn(),
            findAllMerchants: jest.fn(),
            findAllDeliveries: jest.fn(),
            findOneByIdWithRelations: jest.fn(),
            createCustomer: jest.fn(),
            createMerchant: jest.fn(),
            createDelivery: jest.fn(),
            updateCustomer: jest.fn(),
            updateMerchant: jest.fn(),
            updateDelivery: jest.fn(),
            softDelete: jest.fn(),
            hardDelete: jest.fn(),
            toggleMerchantOpen: jest.fn(),
          },
        },
        {
          provide: MerchantsService,
          useValue: {
            findByUserId: jest.fn(),
            deleteMerchant: jest.fn(),
          },
        },
        {
          provide: StorageService,
          useValue: { resolveUrl: jest.fn() },
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

    controller = module.get<UsersController>(UsersController);
    usersService = module.get(UsersService);
    merchantsService = module.get(MerchantsService);
    storageService = module.get(StorageService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Customers', () => {
    it('findAllCustomers should delegate to service', async () => {
      const query: CustomerFilterDto = { page: 1, limit: 10 };
      const result = { data: [mockUser], total: 1, page: 1, limit: 10 };
      usersService.findAllCustomers.mockResolvedValue(result);

      expect(await controller.findAllCustomers(query)).toEqual(result);
      expect(usersService.findAllCustomers).toHaveBeenCalledWith(query);
    });

    it('findOneCustomer should delegate to service', async () => {
      usersService.findOneByIdWithRelations.mockResolvedValue(mockUser);

      expect(await controller.findOneCustomer(1)).toBe(mockUser);
      expect(usersService.findOneByIdWithRelations).toHaveBeenCalledWith(1);
    });

    it('createCustomer should delegate to service', async () => {
      const dto: CreateCustomerDto = { email: 'a@b.com', password: '123456', firstName: 'A', lastName: 'B', phone: '+963' };
      usersService.createCustomer.mockResolvedValue(mockUser);

      expect(await controller.createCustomer(dto)).toBe(mockUser);
      expect(usersService.createCustomer).toHaveBeenCalledWith(dto);
    });

    it('updateCustomer should delegate to service', async () => {
      const dto: UpdateCustomerDto = { firstName: 'Updated' };
      usersService.updateCustomer.mockResolvedValue(mockUser);

      expect(await controller.updateCustomer(1, dto)).toBe(mockUser);
      expect(usersService.updateCustomer).toHaveBeenCalledWith(1, dto);
    });

    it('removeCustomer should delegate to service', async () => {
      usersService.softDelete.mockResolvedValue(undefined);

      await controller.removeCustomer(1);
      expect(usersService.softDelete).toHaveBeenCalledWith(1);
    });
  });

  describe('Merchants', () => {
    it('findAllMerchants should delegate to service', async () => {
      const query: MerchantFilterDto = { page: 1, limit: 10 };
      const result = { data: [mockUser], total: 1, page: 1, limit: 10 };
      usersService.findAllMerchants.mockResolvedValue(result);

      expect(await controller.findAllMerchants(query)).toEqual(result);
      expect(usersService.findAllMerchants).toHaveBeenCalledWith(query);
    });

    it('findOneMerchant should use merchantsService first', async () => {
      const merchantResponse = { user: mockUser, restaurantName: 'Test' };
      merchantsService.findByUserId.mockResolvedValue(merchantResponse);
      storageService.resolveUrl.mockReturnValue('http://resolved.url');

      const result = await controller.findOneMerchant(1);

      expect(merchantsService.findByUserId).toHaveBeenCalledWith(1);
      expect(result).toBeDefined();
    });

    it('createMerchant should delegate to service', async () => {
      const dto: CreateMerchantDto = { email: 'm@b.com', password: '123456', firstName: 'M', lastName: 'B', phone: '+963' };
      usersService.createMerchant.mockResolvedValue(mockUser);

      expect(await controller.createMerchant(dto)).toBe(mockUser);
      expect(usersService.createMerchant).toHaveBeenCalledWith(dto);
    });

    it('removeMerchant should delete merchant then hard delete', async () => {
      merchantsService.deleteMerchant.mockResolvedValue(undefined);
      usersService.hardDelete.mockResolvedValue(undefined);

      await controller.removeMerchant(1);

      expect(merchantsService.deleteMerchant).toHaveBeenCalledWith(1);
      expect(usersService.hardDelete).toHaveBeenCalledWith(1);
    });
  });

  describe('Deliveries', () => {
    it('findAllDeliveries should delegate to service', async () => {
      const query: DeliveryFilterDto = { page: 1, limit: 10 };
      const result = { data: [mockUser], total: 1, page: 1, limit: 10 };
      usersService.findAllDeliveries.mockResolvedValue(result);

      expect(await controller.findAllDeliveries(query)).toEqual(result);
      expect(usersService.findAllDeliveries).toHaveBeenCalledWith(query);
    });

    it('findOneDelivery should delegate to service', async () => {
      usersService.findOneByIdWithRelations.mockResolvedValue(mockUser);

      expect(await controller.findOneDelivery(1)).toBe(mockUser);
      expect(usersService.findOneByIdWithRelations).toHaveBeenCalledWith(1);
    });

    it('createDelivery should delegate to service', async () => {
      const dto: CreateDeliveryDto = { email: 'd@b.com', password: '123456', firstName: 'D', lastName: 'B', phone: '+963' };
      usersService.createDelivery.mockResolvedValue(mockUser);

      expect(await controller.createDelivery(dto)).toBe(mockUser);
      expect(usersService.createDelivery).toHaveBeenCalledWith(dto);
    });

    it('updateDelivery should delegate to service', async () => {
      const dto: UpdateDeliveryDto = { firstName: 'Updated' };
      usersService.updateDelivery.mockResolvedValue(mockUser);

      expect(await controller.updateDelivery(1, dto)).toBe(mockUser);
      expect(usersService.updateDelivery).toHaveBeenCalledWith(1, dto);
    });

    it('removeDelivery should hard delete', async () => {
      usersService.hardDelete.mockResolvedValue(undefined);

      await controller.removeDelivery(1);
      expect(usersService.hardDelete).toHaveBeenCalledWith(1);
    });
  });

  describe('toggleMerchantOpen', () => {
    it('should delegate to service', async () => {
      usersService.toggleMerchantOpen.mockResolvedValue(mockUser);

      expect(await controller.toggleMerchantOpen(1)).toBe(mockUser);
      expect(usersService.toggleMerchantOpen).toHaveBeenCalledWith(1);
    });
  });
});
