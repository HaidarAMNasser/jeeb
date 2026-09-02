import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  UseGuards,
  ParseIntPipe,
  Patch,
  Delete,
  Query,
} from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

import { UpdateReviewDto } from './dto/update-review.dto';
import { REVIEWS_ROUTES } from '../../common/constants/api-routes.constants';
import { Public } from '../../common/decorators/public.decorator';

@Controller(REVIEWS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @Roles(UserRole.CUSTOMER)
  create(
    @Body() createReviewDto: CreateReviewDto,
    @CurrentUser() user: UserPayload,
  ) {
    return this.reviewsService.create(createReviewDto, user.id);
  }

  @Get(REVIEWS_ROUTES.BY_DRIVER)
  @Public()
  findByDriver(
    @Param('driverId', ParseIntPipe) driverId: number,
    @Query() query: PaginationQueryDto,
  ) {
    return this.reviewsService.findAllByDriver(driverId, query);
  }

  @Get(REVIEWS_ROUTES.BY_MERCHANT)
  @Public()
  findByMerchant(
    @Param('merchantId', ParseIntPipe) merchantId: number,
    @Query() query: PaginationQueryDto,
  ) {
    return this.reviewsService.findAllPublicByMerchant(merchantId, query);
  }

  // --- Admin, Merchant, and Customer Endpoints ---

  @Get()
  @Roles(UserRole.ADMIN, UserRole.MERCHANT)
  findAll(
    @Query() query: PaginationQueryDto,
    @CurrentUser() user: UserPayload,
  ) {
    if (user.role === UserRole.MERCHANT) {
      return this.reviewsService.findAllForMerchant(user.id, query);
    }
    return this.reviewsService.findAll(query);
  }

  @Get(REVIEWS_ROUTES.GET_ONE)
  @Roles(UserRole.ADMIN, UserRole.MERCHANT, UserRole.CUSTOMER)
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: UserPayload,
  ) {
    if (user.role === UserRole.MERCHANT) {
      return this.reviewsService.findOneForMerchant(id, user.id);
    } else if (user.role === UserRole.CUSTOMER) {
      return this.reviewsService.findOneForCustomer(id, user.id);
    }
    return this.reviewsService.findOne(id);
  }

  @Patch(REVIEWS_ROUTES.UPDATE)
  @Roles(UserRole.ADMIN, UserRole.CUSTOMER)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateReviewDto: UpdateReviewDto,
    @CurrentUser() user: UserPayload,
  ) {
    if (user.role === UserRole.CUSTOMER) {
      return this.reviewsService.updateForCustomer(
        id,
        updateReviewDto,
        user.id,
      );
    }
    return this.reviewsService.update(id, updateReviewDto);
  }

  @Delete(REVIEWS_ROUTES.DELETE)
  @Roles(UserRole.ADMIN, UserRole.CUSTOMER)
  remove(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: UserPayload,
  ) {
    if (user.role === UserRole.CUSTOMER) {
      return this.reviewsService.removeForCustomer(id, user.id);
    }
    return this.reviewsService.remove(id);
  }

  @Get(REVIEWS_ROUTES.BY_PRODUCT)
  @Public()
  findByProduct(
    @Param('productId', ParseIntPipe) productId: number,
    @Query() query: PaginationQueryDto,
  ) {
    return this.reviewsService.findByProduct(productId, query);
  }
}
