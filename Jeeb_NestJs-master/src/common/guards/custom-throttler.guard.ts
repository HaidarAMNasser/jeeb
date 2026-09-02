import { Injectable, ExecutionContext, Logger } from '@nestjs/common';
import { ThrottlerGuard as NestThrottlerGuard } from '@nestjs/throttler';
import { Request } from 'express';

@Injectable()
export class CustomThrottlerGuard extends NestThrottlerGuard {
  private readonly logger = new Logger(CustomThrottlerGuard.name);

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const method = request.method.toUpperCase();

    const isGetRequest = method === 'GET';
    const throttlerName = isGetRequest ? 'get' : 'default';

    const throttler = this.throttlers.find((t) => t.name === throttlerName);
    if (!throttler) {
      return super.canActivate(context);
    }

    this.throttlers = [throttler];

    return super.canActivate(context);
  }

  protected async getTracker(req: Record<string, any>): Promise<string> {
    const request = req as Request;
    const forwarded = request.headers['x-forwarded-for'];
    const ip = forwarded
      ? Array.isArray(forwarded)
        ? forwarded[0]
        : forwarded.split(',')[0].trim()
      : request.ip || 'unknown';
    return `throttler:${ip}:${request.headers['user-agent'] || 'unknown'}`;
  }
}
