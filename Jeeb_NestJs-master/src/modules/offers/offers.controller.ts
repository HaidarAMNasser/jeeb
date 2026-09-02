import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from '@nestjs/common';
import { OffersService } from './offers.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { UpdateOfferDto } from './dto/update-offer.dto';
import { GetOffersQueryDto } from './dto/get-offers-query.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OFFERS_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(OFFERS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Post()
  @Roles(UserRole.MERCHANT, UserRole.ADMIN)
  create(
    @Body() createOfferDto: CreateOfferDto,
    @CurrentUser() user: UserPayload,
  ) {
    return this.offersService.create(createOfferDto, user.id, user.role);
  }

  @Get()
  findAll(@Query() query: GetOffersQueryDto, @CurrentUser() user: UserPayload) {
    return this.offersService.findAll(query, user.id, user.role);
  }

  @Get(OFFERS_ROUTES.GET_ONE)
  findOne(@Param('id') id: string) {
    return this.offersService.findOne(+id);
  }

  @Patch(OFFERS_ROUTES.UPDATE)
  @Roles(UserRole.MERCHANT, UserRole.ADMIN)
  update(
    @Param('id') id: string,
    @Body() updateOfferDto: UpdateOfferDto,
    @CurrentUser() user: UserPayload,
  ) {
    return this.offersService.update(+id, updateOfferDto, user.id, user.role);
  }

  @Delete(OFFERS_ROUTES.DELETE)
  @Roles(UserRole.MERCHANT, UserRole.ADMIN)
  remove(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return this.offersService.remove(+id, user.id, user.role);
  }
}
