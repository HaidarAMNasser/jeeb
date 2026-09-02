import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { CountriesService } from './countries.service';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { COUNTRIES_ROUTES } from '../../common/constants/api-routes.constants';
import { Public } from '../../common/decorators/public.decorator';

@Controller(COUNTRIES_ROUTES.BASE)
export class CountriesController {
  constructor(private readonly countriesService: CountriesService) {}

  @Get()
  @Public()
  findAll(@Query() query: PaginationQueryDto) {
    return this.countriesService.findAll(query);
  }

  @Get(COUNTRIES_ROUTES.GET_ONE)
  @Public()
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.countriesService.findOne(id);
  }
}
