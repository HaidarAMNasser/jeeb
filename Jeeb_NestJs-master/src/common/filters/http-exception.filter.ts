import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { ApiResponse } from '../interfaces/api-response.interface';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const messageResponse =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    // Normalize message if it's an object (validation errors)
    let errorMessage: string | string[];

    if (
      typeof messageResponse === 'object' &&
      messageResponse !== null &&
      'message' in messageResponse
    ) {
      errorMessage = (messageResponse as { message: string | string[] })
        .message;
    } else if (typeof messageResponse === 'string') {
      errorMessage = messageResponse;
    } else {
      errorMessage = 'Internal server error';
    }

    // Custom message for Throttler (429 Too Many Requests)
    if (status === HttpStatus.TOO_MANY_REQUESTS) {
      const throttleException = exception as any;
      const throttleInfo = throttleException?.throttler
        ? ` | Throttler: ${JSON.stringify(throttleException.throttler)}`
        : '';
      errorMessage = `لقد تجاوزت الحد المسموح به من الطلبات. يرجى الانتظار قليلاً والمحاولة مرة أخرى. (Too many requests)${throttleInfo}`;
    }

    this.logger.error(
      `Http Status: ${status} Error Message: ${JSON.stringify(errorMessage)}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    const errorResponse: ApiResponse<Record<string, never>> = {
      statusCode: status,
      message: Array.isArray(errorMessage)
        ? errorMessage.join(', ')
        : errorMessage,
      data: {},
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    response.status(status).json(errorResponse);
  }
}
