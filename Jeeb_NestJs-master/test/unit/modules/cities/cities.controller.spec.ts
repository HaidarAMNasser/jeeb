import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { GetCitiesQueryDto } from '../../../../src/modules/cities/dto/get-cities-query.dto';
import { CitiesController } from '../../../../src/modules/cities/cities.controller';
import { CitiesService } from '../../../../src/modules/cities/cities.service';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';

describe('CitiesController', () => {
  let controller: CitiesController;
  let citiesService: jest.Mocked<CitiesService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CitiesController],
      providers: [
        {
          provide: CitiesService,
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

    controller = module.get<CitiesController>(CitiesController);
    citiesService = module.get(CitiesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should delegate with query and countryId', async () => {
      const query: GetCitiesQueryDto = { page: 1, limit: 10, countryId: 1 };
      citiesService.findAll.mockResolvedValue({ data: [], total: 0, page: 1, limit: 10 } as any);

      await controller.findAll(query);

      expect(citiesService.findAll).toHaveBeenCalledWith(query, 1);
    });
  });

  describe('findOne', () => {
    it('should delegate to service', async () => {
      const expected = { id: 1, name: 'Damascus' };
      citiesService.findOne.mockResolvedValue(expected as any);

      const result = await controller.findOne(1);

      expect(citiesService.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(expected);
    });
  });
});
