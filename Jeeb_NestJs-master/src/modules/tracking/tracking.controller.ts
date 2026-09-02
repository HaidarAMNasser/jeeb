import {
  Controller,
  Post,
  Body,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { UpdateDriverLocationDto } from './dto/tracking.dto';
import { TRACKING_ROUTES } from '../../common/constants/api-routes.constants';
import { AuthGuard } from '../../common/guards/auth.guard';
import { Public } from '../../common/decorators/public.decorator';

@Controller(TRACKING_ROUTES.BASE)
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class TrackingController {
  constructor(private readonly firebaseService: FirebaseService) {}

  @Post(TRACKING_ROUTES.UPDATE_LOCATION)
  @Public()
  async updateDriverLocation(@Body() dto: UpdateDriverLocationDto) {
    await this.firebaseService.updateOrderDriverLocation(
      dto.orderId,
      { lat: dto.lat, lng: dto.lng, timestamp: dto.timestamp },
      dto.speed || 0,
    );

    return {
      success: true,
      message: 'Location updated successfully',
    };
  }
}
