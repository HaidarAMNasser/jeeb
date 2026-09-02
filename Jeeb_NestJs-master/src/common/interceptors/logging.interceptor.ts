import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body } = request;
    const now = Date.now();

    this.logger.log(`➡️ [${method}] ${url}`);
    this.logger.debug(`📦 Request Body: ${JSON.stringify(body)}`);

    return next.handle().pipe(
      tap({
        next: () => {
          const response = context.switchToHttp().getResponse();
          this.logger.log(
            `⬅️ [${method}] ${url} - ${response.statusCode} - ${Date.now() - now}ms`,
          );
        },
        error: (error) => {
          const response = context.switchToHttp().getResponse();
          this.logger.error(
            `❌ [${method}] ${url} - ${response.statusCode} - ${Date.now() - now}ms`,
          );
        },
      }),
    );
  }
}
