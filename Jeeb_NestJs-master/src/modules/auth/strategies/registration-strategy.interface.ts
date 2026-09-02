import { UserRole } from '../../../common/enums/user-role.enum';
import { RegisterDto } from '../dto/register.dto';

export interface RegistrationStrategy {
  readonly role: UserRole;
  register(
    dto: RegisterDto,
    files?: Express.Multer.File[],
  ): Promise<Record<string, any>>;
}
