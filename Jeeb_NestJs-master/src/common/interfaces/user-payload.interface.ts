import { UserRole } from '../enums';

export interface UserPayload {
  id: number;
  email: string | null;
  role: UserRole;
  firstName?: string;
  lastName?: string;
  is_guest?: boolean;
}
