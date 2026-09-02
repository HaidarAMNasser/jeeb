import { IsInt, IsNotEmpty } from 'class-validator';

export class ManageFavoriteDto {
  @IsInt()
  @IsNotEmpty()
  entityId: number;
}
