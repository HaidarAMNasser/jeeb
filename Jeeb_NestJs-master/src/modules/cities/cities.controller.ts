import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { CitiesService } from './cities.service';
import { GetCitiesQueryDto } from './dto/get-cities-query.dto';
import { CITIES_ROUTES } from '../../common/constants/api-routes.constants';
import { Public } from '../../common/decorators/public.decorator';

@Controller(CITIES_ROUTES.BASE)
export class CitiesController {
  constructor(private readonly citiesService: CitiesService) {}

  @Get()
  @Public()
  findAll(@Query() query: GetCitiesQueryDto) {
    return this.citiesService.findAll(query, query.countryId);
  }

  @Get(CITIES_ROUTES.GET_ONE)
  @Public()
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.citiesService.findOne(id);
  }
}
