import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { CartController } from '../../../../src/modules/cart/cart.controller';
import { CartService } from '../../../../src/modules/cart/cart.service';
import { CreateCartDto } from '../../../../src/modules/cart/dto/create-cart.dto';
import { UpdateCartActionsDto } from '../../../../src/modules/cart/dto/update-cart.dto';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { UserRole } from '../../../../src/common/enums/user-role.enum';

describe('CartController', () => {
  let controller: CartController;
  let cartService: jest.Mocked<CartService>;

  const mockCart = { id: 1, customerId: 1, items: [], offers: [] };
  const mockUser = { id: 1, role: UserRole.CUSTOMER } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CartController],
      providers: [
        {
          provide: CartService,
          useValue: {
            getCart: jest.fn(),
            createCart: jest.fn(),
            updateCart: jest.fn(),
          },
        },
        { provide: JwtService, useValue: { signAsync: jest.fn(), decode: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn() } },
        Reflector,
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .compile();

    controller = module.get<CartController>(CartController);
    cartService = module.get(CartService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getCart (GET /cart)', () => {
    it('should return cart when exists', async () => {
      cartService.getCart.mockResolvedValue(mockCart as any);

      const result = await controller.getCart(mockUser);

      expect(cartService.getCart).toHaveBeenCalledWith(1);
      expect(result.statusCode).toBe(200);
      expect(result.data).toEqual(mockCart);
    });

    it('should return empty cart message when no cart', async () => {
      cartService.getCart.mockResolvedValue(null);

      const result = await controller.getCart(mockUser);

      expect(result.message).toBe('Cart is empty');
      expect(result.data).toBeNull();
    });
  });

  describe('createCart (POST /cart)', () => {
    it('should delegate to cartService.createCart', async () => {
      const dto: CreateCartDto = { merchantId: 1, items: [], offers: [] };
      cartService.createCart.mockResolvedValue(mockCart as any);

      const result = await controller.createCart(dto, mockUser);

      expect(cartService.createCart).toHaveBeenCalledWith(1, dto);
      expect(result.statusCode).toBe(201);
    });
  });

  describe('updateCart (PATCH /cart)', () => {
    it('should delegate to cartService.updateCart', async () => {
      const dto: UpdateCartActionsDto = { add: [], update: [], remove: [] };
      cartService.updateCart.mockResolvedValue(mockCart as any);

      const result = await controller.updateCart(dto, mockUser);

      expect(cartService.updateCart).toHaveBeenCalledWith(1, dto);
      expect(result.statusCode).toBe(200);
    });
  });
});
