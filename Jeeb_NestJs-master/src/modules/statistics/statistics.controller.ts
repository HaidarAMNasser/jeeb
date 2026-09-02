import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { StatisticsService } from './statistics.service';
import { MerchantStatsQueryDto } from './dto/merchant-stats-query.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { STATISTICS_ROUTES } from '../../common/constants/api-routes.constants';

@ApiTags('Statistics')
@ApiBearerAuth()
@Controller(STATISTICS_ROUTES.BASE)
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get(STATISTICS_ROUTES.MERCHANTS)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Get merchant statistics (Admin only)' })
  @ApiResponse({
    status: 200,
    description: 'Merchant statistics retrieved successfully',
  })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 10 })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'burger',
  })
  @ApiQuery({
    name: 'from',
    required: false,
    type: String,
    example: '2026-01-01',
  })
  @ApiQuery({
    name: 'to',
    required: false,
    type: String,
    example: '2026-06-08',
  })
  @ApiQuery({ name: 'merchantId', required: false, type: Number, example: 27 })
  async getMerchantStats(@Query() query: MerchantStatsQueryDto) {
    return this.statisticsService.getMerchantStats(query);
  }
}
