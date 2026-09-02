import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { GlobalSearchService } from './global-search.service';
import { GlobalSearchQueryDto } from './dto/global-search-query.dto';
import { GLOBAL_SEARCH_ROUTES } from '../../common/constants/api-routes.constants';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Global Search')
@Controller(GLOBAL_SEARCH_ROUTES.BASE)
export class GlobalSearchController {
  constructor(private readonly globalSearchService: GlobalSearchService) {}

  @Public()
  @Get()
  @ApiOperation({
    summary: 'البحث الشامل في التطبيق (تجار، منتجات، عروض، أقسام)',
  })
  @ApiResponse({ status: 200, description: 'Return search results' })
  async search(@Query() query: GlobalSearchQueryDto) {
    return this.globalSearchService.searchAll(query);
  }
}
