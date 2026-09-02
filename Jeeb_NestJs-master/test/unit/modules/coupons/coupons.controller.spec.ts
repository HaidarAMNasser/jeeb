import { Test, TestingModule } from '@nestjs/testing';
import { CouponsController } from '../../../../src/modules/coupons/coupons.controller';
import { CouponsService } from '../../../../src/modules/coupons/coupons.service';

describe('CouponsController', () => {
  let controller: CouponsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CouponsController],
      providers: [
        {
          provide: CouponsService,
          useValue: {
            create: jest.fn(),
            validateCoupon: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<CouponsController>(CouponsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
