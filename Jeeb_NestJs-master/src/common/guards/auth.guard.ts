import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { TokenService } from '../../modules/auth/token.service';
import { JwtPayload } from '../../modules/auth/interfaces/jwt-payload.interface';
import { UserPayload } from '../interfaces/user-payload.interface';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

interface AuthenticatedRequest extends Request {
  user?: UserPayload;
}

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly logger = new Logger(AuthGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly tokenService: TokenService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      // Even if public, try to extract user if token exists (optional auth)
      const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
      const token = this.extractTokenFromHeader(request);
      if (token) {
        try {
          // If token is invalid/revoked, we just ignore it for public routes
          // instead of throwing error, or we could treat it as unauthenticated.
          // Let's try to verify it.
          const isRevoked = await this.tokenService.isTokenRevoked(token);
          if (!isRevoked) {
            const payload = await this.jwtService.verifyAsync<JwtPayload>(
              token,
              {
                secret: this.configService.get<string>('JWT_SECRET'),
              },
            );
            request.user = {
              id: payload.sub,
              email: payload.email,
              role: payload.role,
              ...(payload.is_guest ? { is_guest: true } : {}),
            } as any;
          }
        } catch {
          // Token invalid? Just proceed as guest.
        }
      }
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException();
    }
    try {
      const isRevoked = await this.tokenService.isTokenRevoked(token);
      if (isRevoked) {
        throw new UnauthorizedException('Token revoked');
      }

      const payload = await this.jwtService.verifyAsync<JwtPayload>(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      request.user = {
        id: payload.sub,
        email: payload.email,
        role: payload.role,
        ...(payload.is_guest ? { is_guest: true } : {}),
      } as any;
    } catch (error) {
      throw new UnauthorizedException();
    }
    return true;
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
