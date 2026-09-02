import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { ToggleFavoriteDto } from './dto/toggle-favorite.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { AllowGuest } from '../../common/decorators/allow-guest.decorator';
import { FAVORITES_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(`${FAVORITES_ROUTES.BASE}`)
@UseGuards(AuthGuard)
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Post(`${FAVORITES_ROUTES.TOGGLE}`)
  @AllowGuest()
  async toggle(@Request() req, @Body() dto: ToggleFavoriteDto) {
    return this.favoritesService.toggleBulk(req.user.id, dto);
  }

  @Get()
  async findAll(@Request() req, @Query() query: PaginationQueryDto) {
    return this.favoritesService.findAllPaginated(req.user.id, query);
  }
}
