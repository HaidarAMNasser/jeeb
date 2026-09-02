import { Controller, All, Req, Res, HttpStatus, Logger } from '@nestjs/common';
import type { Request, Response } from 'express';

@Controller()
export class FallbackController {
  private readonly logger = new Logger(FallbackController.name);

  @All('*')
  handleFallback(@Req() req: Request, @Res() res: Response) {
    const errorResponse = {
      statusCode: HttpStatus.NOT_FOUND,
      message: `The requested route "${req.method} ${req.originalUrl}" is not found`,
      data: {},
      timestamp: new Date().toISOString(),
      path: req.originalUrl,
    };

    this.logger.warn(`Route not found: ${req.method} ${req.originalUrl}`);

    res.status(HttpStatus.NOT_FOUND).json(errorResponse);
  }
}
