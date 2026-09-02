import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ALLOW_GUEST_KEY } from '../decorators/allow-guest.decorator';

@Injectable()
export class GuestRestrictionGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // If there is no user attached (e.g. public route), let it pass (handled by AuthGuard).
    if (!user || (!user.email && !user.sub)) {
      return true;
    }

    // Determine if the user is a guest based on email pattern or is_guest flag (Redis guest)
    const isGuest =
      (user as any).is_guest === true ||
      (user.email &&
        user.email.startsWith('guest-') &&
        user.email.endsWith('@jeeb.local'));

    if (!isGuest) {
      // Normal users are unaffected
      return true;
    }

    // Guests can perform any GET request natively
    if (request.method === 'GET') {
      return true;
    }

    // Check if the route is explicitly allowed for guests
    const allowGuest = this.reflector.getAllAndOverride<boolean>(
      ALLOW_GUEST_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (allowGuest) {
      return true;
    }

    // If it's a non-GET mutating operation and not explicitly allowed -> Forbidden.
    throw new ForbiddenException(
      'عذراً، يجب إنشاء حساب دائم للتمتع بهذه الصلاحيات وإتمام هذه العملية.',
    );
  }
}
