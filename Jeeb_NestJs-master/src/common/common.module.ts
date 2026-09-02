import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CleanupService } from './services/cleanup.service';
import { StorageModule } from './storage/storage.module';
import { ImageProcessingService } from './image-processing/image-processing.service';
import { SearchService } from './search/search.service';
import { LoginAttemptService } from './services/login-attempt.service';
import { IPBlockService } from './services/ip-block.service';
import { OtpAttemptService } from './services/otp-attempt.service';
import { OtpBruteForceGuard } from './guards/otp-brute-force.guard';
import { OtpAttemptInterceptor } from './interceptors/otp-attempt.interceptor';
import { LoginBlock } from '../database/entities/login-block.entity';

@Global()
@Module({
  imports: [StorageModule, TypeOrmModule.forFeature([LoginBlock])],
  providers: [
    CleanupService,
    ImageProcessingService,
    SearchService,
    LoginAttemptService,
    IPBlockService,
    OtpAttemptService,
    OtpBruteForceGuard,
    OtpAttemptInterceptor,
  ],
  exports: [
    CleanupService,
    ImageProcessingService,
    SearchService,
    LoginAttemptService,
    IPBlockService,
    OtpAttemptService,
    OtpBruteForceGuard,
    OtpAttemptInterceptor,
    TypeOrmModule,
  ],
})
export class CommonModule {}
