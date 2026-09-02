import { IsNumber, IsBoolean } from 'class-validator';

export class DeleteUserDto {
  @IsNumber()
  id: number;

  @IsBoolean()
  hardDelete?: boolean = false;
}
