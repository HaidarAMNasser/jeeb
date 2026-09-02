import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { FavoritesController } from '../../../../src/modules/favorites/favorites.controller';
import { FavoritesService } from '../../../../src/modules/favorites/favorites.service';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';

describe('FavoritesController', () => {
  let controller: FavoritesController;
  let favoritesService: jest.Mocked<FavoritesService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FavoritesController],
      providers: [
        {
          provide: FavoritesService,
          useValue: {
            toggleBulk: jest.fn(),
            findAllPaginated: jest.fn(),
          },
        },
        { provide: JwtService, useValue: { signAsync: jest.fn(), decode: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn() } },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .compile();

    controller = module.get<FavoritesController>(FavoritesController);
    favoritesService = module.get(FavoritesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('toggle (POST /favorites/toggle)', () => {
    it('should delegate to service with user id and dto', async () => {
      const dto = { products: [1, 2] };
      const req = { user: { id: 1 } };
      const expected = { products: [{ id: 1, name: 'Product', price: 10, category: 'Cat' }] };
      favoritesService.toggleBulk.mockResolvedValue(expected);

      const result = await controller.toggle(req, dto);

      expect(favoritesService.toggleBulk).toHaveBeenCalledWith(1, dto);
      expect(result).toEqual(expected);
    });
  });

  describe('findAll (GET /favorites)', () => {
    it('should delegate to service with user id and query', async () => {
      const req = { user: { id: 1 } };
      const query = { page: 1, limit: 10 };
      const expected = { data: [], total: 0, page: 1, limit: 10 };
      favoritesService.findAllPaginated.mockResolvedValue(expected as any);

      const result = await controller.findAll(req, query);

      expect(favoritesService.findAllPaginated).toHaveBeenCalledWith(1, query);
      expect(result).toEqual(expected);
    });
  });
});
