import { Module } from '@nestjs/common';
import { BlazeApiService } from './blaze-api.service';
import { BlazeApiController } from './blaze-api.controller';

@Module({
  controllers: [BlazeApiController],
  providers: [BlazeApiService],
  exports: [BlazeApiService],
})
export class BlazeApiModule {}
