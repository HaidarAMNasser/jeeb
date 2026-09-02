import {
  Controller,
  Post,
  Body,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { DistanceService } from './distance.service';
import {
  CalculateDistanceDto,
  CalculateDeliveryCostDto,
} from './dto/calculate-distance.dto';
import { DISTANCE_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(DISTANCE_ROUTES.BASE)
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class DistanceController {
  constructor(private readonly distanceService: DistanceService) {}

  @Post(DISTANCE_ROUTES.CALCULATE)
  async calculateDistance(@Body() dto: CalculateDistanceDto) {
    const result = await this.distanceService.calculateDistanceWithTip(
      dto.source,
      dto.destination,
    );
    return {
      success: true,
      data: result,
    };
  }

  @Post(DISTANCE_ROUTES.CALCULATE_DELIVERY_COST)
  async calculateDeliveryCost(@Body() dto: CalculateDeliveryCostDto) {
    const result = await this.distanceService.calculateDeliveryCostWithProducts(
      dto.merchantId,
      dto.destination,
      dto.products,
    );
    return {
      success: true,
      data: result,
    };
  }
}
