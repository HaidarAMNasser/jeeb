// import { createParamDecorator, ExecutionContext } from '@nestjs/common';
// import { User } from '../../database/entities/user.entity';

// export const CurrentUser = createParamDecorator(
//   (data: keyof User | undefined, ctx: ExecutionContext) => {
//     const request = ctx.switchToHttp().getRequest();
//     const user = request.user;

//     return data ? user?.[data] : user;
//   },
// );

import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';
import { User } from '../../database/entities/user.entity';

interface AuthenticatedRequest extends Request {
  user: User;
}

export const CurrentUser = createParamDecorator(
  (data: keyof User | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<AuthenticatedRequest>();

    const user = request.user;

    return data ? user?.[data] : user;
  },
);
