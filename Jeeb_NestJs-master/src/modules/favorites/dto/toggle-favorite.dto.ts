import { IsOptional, IsArray, IsInt } from 'class-validator';

export class ToggleFavoriteDto {
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  products?: number[];
}
