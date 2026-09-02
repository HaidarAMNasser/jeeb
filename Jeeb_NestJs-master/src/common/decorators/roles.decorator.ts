import { SetMetadata } from '@nestjs/common';
import { UserRole } from '../enums/user-role.enum';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: UserRole[]) => {
  if (roles.length === 0) {
    return SetMetadata(ROLES_KEY, undefined);
  }
  return SetMetadata(ROLES_KEY, roles);
};
