import { Controller, Post, Body, Req } from '@nestjs/common';
import { CouponsService } from './coupons.service';
import { Coupon } from '../../database/entities/coupon.entity';
// import { AuthGuard } from '../auth/auth.guard'; // Assuming AuthGuard exists
// import { RolesGuard } from '../auth/roles.guard'; // Assuming RolesGuard exists
// import { Coupon } from '../../database/entities/coupon.entity';
import { COUPONS_ROUTES } from '../../common/constants/api-routes.constants';
// import { AuthGuard } from '../auth/auth.guard'; // Assuming AuthGuard exists

@Controller(COUPONS_ROUTES.BASE)
export class CouponsController {
  constructor(private readonly couponsService: CouponsService) {}

  @Post()
  // @UseGuards(AuthGuard, RolesGuard)
  // @Roles(UserRole.ADMIN)
  create(@Body() createCouponDto: Partial<Coupon>) {
    return this.couponsService.create(createCouponDto);
  }

  @Post(COUPONS_ROUTES.VALIDATE)
  async validate(
    @Body('code') code: string,
    @Req() req: unknown, // In real app, get user from request
    @Body('userId') bodyUserId?: number, // Fallback for dev/testing
  ) {
    // const userId = req.user?.id || bodyUserId;
    const userId = bodyUserId || 1; // Default for now
    const coupon = await this.couponsService.validateCoupon(code, userId);
    return { valid: true, coupon };
  }
}
