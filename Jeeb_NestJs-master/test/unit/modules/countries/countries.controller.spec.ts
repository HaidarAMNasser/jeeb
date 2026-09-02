import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { CountriesController } from '../../../../src/modules/countries/countries.controller';
import { CountriesService } from '../../../../src/modules/countries/countries.service';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';

describe('CountriesController', () => {
  let controller: CountriesController;
  let countriesService: jest.Mocked<CountriesService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CountriesController],
      providers: [
        {
          provide: CountriesService,
          useValue: {
            findAll: jest.fn(),
            findOne: jest.fn(),
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

    controller = module.get<CountriesController>(CountriesController);
    countriesService = module.get(CountriesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should delegate to service', async () => {
      const query = { page: 1, limit: 10 };
      countriesService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query);

      expect(countriesService.findAll).toHaveBeenCalledWith(query);
    });
  });

  describe('findOne', () => {
    it('should delegate to service', async () => {
      const expected = { id: 1, name: 'Syria' };
      countriesService.findOne.mockResolvedValue(expected as any);

      const result = await controller.findOne(1);

      expect(countriesService.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(expected);
    });
  });
});
