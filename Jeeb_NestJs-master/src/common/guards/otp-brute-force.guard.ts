import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { OtpAttemptService } from '../../common/services/otp-attempt.service';
import { createErrorResponse } from '../constants/error-codes';

@Injectable()
export class OtpBruteForceGuard implements CanActivate {
  constructor(private readonly otpAttemptService: OtpAttemptService) {}

  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    const identifier = request.body?.phone || request.body?.email;

    if (!identifier) {
      return true;
    }

    return this.checkBlock(identifier);
  }

  private async checkBlock(identifier: string): Promise<boolean> {
    const blocked = await this.otpAttemptService.isBlocked(identifier);
    if (blocked) {
      const blockInfo = await this.otpAttemptService.getBlockInfo(identifier);
      const retryAfter = blockInfo?.blockTtl || 900;
      throw new HttpException(
        createErrorResponse(
          'OTP_VERIFY_ATTEMPTS_EXCEEDED',
          HttpStatus.TOO_MANY_REQUESTS,
          undefined,
          { retryAfter },
        ),
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    return true;
  }
}
