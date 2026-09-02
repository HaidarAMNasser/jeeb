import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class RequestTimeoutMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    req.setTimeout(30000, () => {
      res.status(408).json({
        message: 'Request timeout exceeded. Please try again.',
        error: 'REQUEST_TIMEOUT',
        statusCode: 408,
      });
    });
    next();
  }
}
