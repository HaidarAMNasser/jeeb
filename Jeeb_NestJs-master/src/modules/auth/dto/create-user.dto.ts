import { IsEnum, IsNotEmpty } from 'class-validator';
import { RegisterDto } from './register.dto';
import { UserRole } from '../../../common/enums/user-role.enum';

export class CreateUserDto extends RegisterDto {
  @IsNotEmpty()
  @IsEnum(UserRole)
  declare role: UserRole;
}
