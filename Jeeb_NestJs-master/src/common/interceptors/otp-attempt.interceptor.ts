import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { Observable, from, throwError } from 'rxjs';
import { switchMap, catchError, map } from 'rxjs/operators';
import { OtpAttemptService } from '../../common/services/otp-attempt.service';

@Injectable()
export class OtpAttemptInterceptor implements NestInterceptor {
  private readonly logger = new Logger(OtpAttemptInterceptor.name);

  constructor(private readonly otpAttemptService: OtpAttemptService) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const identifier = request.body?.phone || request.body?.email;

    if (!identifier) {
      return next.handle();
    }

    return next.handle().pipe(
      switchMap((value) =>
        from(this.otpAttemptService.recordSuccessfulAttempt(identifier)).pipe(
          map(() => value),
        ),
      ),
      catchError((err) => {
        if (err instanceof BadRequestException) {
          return from(
            this.otpAttemptService.recordFailedAttempt(identifier),
          ).pipe(
            switchMap(() => throwError(() => err)),
          );
        }
        return throwError(() => err);
      }),
    );
  }
}
