import {
  Injectable,
  NestMiddleware,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { ApiResponse } from '../interfaces/api-response.interface';

@Injectable()
export class NotFoundMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const errorResponse: ApiResponse<Record<string, never>> = {
      statusCode: HttpStatus.NOT_FOUND,
      message: `The requested route "${req.method} ${req.originalUrl}" is not found`,
      data: {},
      timestamp: new Date().toISOString(),
      path: req.originalUrl,
    };

    res.status(HttpStatus.NOT_FOUND).json(errorResponse);
  }
}
