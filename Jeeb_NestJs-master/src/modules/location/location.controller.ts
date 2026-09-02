import {
  Controller,
  Post,
  Body,
  Request,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { LocationService } from './location.service';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { LOCATION_ROUTES } from '../../common/constants/api-routes.constants';

// Placeholder guard - normally you'd use JwtAuthGuard
// import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller(LOCATION_ROUTES.BASE)
export class LocationController {
  constructor(private readonly locationService: LocationService) {}

  @Get(LOCATION_ROUTES.COUNTRIES)
  async getCountries(@Query() query: PaginationQueryDto) {
    return this.locationService.findAllCountries(query);
  }

  @Get(LOCATION_ROUTES.CITIES)
  async getCities(
    @Param('countryId') countryId: number,
    @Query() query: PaginationQueryDto,
  ) {
    return this.locationService.findCitiesByCountry(countryId, query);
  }

  @Post(LOCATION_ROUTES.UPDATE)
  // @UseGuards(JwtAuthGuard)
  async updateLocation(
    @Body() body: { lat: number; lng: number; driverId: number }, // In real app, get driverId from Request (JWT)
  ) {
    // For demo purposes, we accept driverId in body.
    // Secure implementation: const driverId = req.user.id;
    await this.locationService.updateDriverLocation(
      body.driverId,
      body.lat,
      body.lng,
    );
    return { success: true };
  }

  @Get(LOCATION_ROUTES.DRIVER_LOCATION)
  async getLocation(@Param('driverId') driverId: number) {
    return this.locationService.getDriverLocation(driverId);
  }
}
