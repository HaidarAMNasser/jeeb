import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { AreasController } from '../../../../src/modules/areas/areas.controller';
import { AreasService } from '../../../../src/modules/areas/areas.service';
import { CreateAreaDto } from '../../../../src/modules/areas/dto/create-area.dto';
import { UpdateAreaDto } from '../../../../src/modules/areas/dto/update-area.dto';
import { GetAreasQueryDto } from '../../../../src/modules/areas/dto/get-areas-query.dto';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Area } from '../../../../src/database/entities/area.entity';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';

describe('AreasController', () => {
  let controller: AreasController;
  let areasService: jest.Mocked<AreasService>;

  const mockArea = { id: 1, name: 'Downtown', price: 5000, description: 'test' } as Area;
  const mockUser = { id: 1, role: UserRole.ADMIN } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AreasController],
      providers: [
        {
          provide: AreasService,
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

    controller = module.get<AreasController>(AreasController);
    areasService = module.get(AreasService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create (POST /areas)', () => {
    it('should call service.create with dto and role', async () => {
      const dto: CreateAreaDto = { name: 'New Area', price: 3000 };
      areasService.create.mockResolvedValue(mockArea);

      const result = await controller.create(dto, mockUser);

      expect(areasService.create).toHaveBeenCalledWith(dto, UserRole.ADMIN);
      expect(result).toEqual(mockArea);
    });
  });

  describe('findAll (GET /areas)', () => {
    it('should call service.findAll with query', async () => {
      const query: GetAreasQueryDto = { page: 1, limit: 10 };
      const paginatedResult = { data: [mockArea], total: 1, page: 1, limit: 10 };
      areasService.findAll.mockResolvedValue(paginatedResult);

      const result = await controller.findAll(query);

      expect(areasService.findAll).toHaveBeenCalledWith(query);
      expect(result).toEqual(paginatedResult);
    });

    it('should pass empty query when no filters provided', async () => {
      const query = {} as GetAreasQueryDto;
      const paginatedResult = { data: [], total: 0, page: 1, limit: 10 };
      areasService.findAll.mockResolvedValue(paginatedResult);

      const result = await controller.findAll(query);

      expect(areasService.findAll).toHaveBeenCalledWith(query);
      expect(result).toEqual(paginatedResult);
    });
  });

  describe('findOne (GET /areas/:id)', () => {
    it('should call service.findOne with parsed id', async () => {
      areasService.findOne.mockResolvedValue(mockArea);

      const result = await controller.findOne(1);

      expect(areasService.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockArea);
    });
  });

  describe('update (PATCH /areas/:id)', () => {
    it('should call service.update with id, dto, and role', async () => {
      const dto: UpdateAreaDto = { name: 'Updated' };
      areasService.update.mockResolvedValue(mockArea);

      const result = await controller.update(1, dto, mockUser);

      expect(areasService.update).toHaveBeenCalledWith(1, dto, UserRole.ADMIN);
      expect(result).toEqual(mockArea);
    });
  });

  describe('remove (DELETE /areas/:id)', () => {
    it('should call service.remove with id and role', async () => {
      areasService.remove.mockResolvedValue({ message: 'Area deleted successfully' });

      const result = await controller.remove(1, mockUser);

      expect(areasService.remove).toHaveBeenCalledWith(1, UserRole.ADMIN);
      expect(result).toEqual({ message: 'Area deleted successfully' });
    });
  });
});
