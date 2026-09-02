import { UserRole } from '../../../common/enums/user-role.enum';

export interface JwtPayload {
  sub: number;
  email: string | null;
  role: UserRole;
  is_guest?: boolean;
  iat?: number;
  exp?: number;
}
