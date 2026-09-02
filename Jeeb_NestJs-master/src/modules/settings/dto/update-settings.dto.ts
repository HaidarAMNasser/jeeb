import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateSettingsDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  driverRequestTimeoutSeconds?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  driverRequestBatchSize?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  initialSearchRadius?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  searchRadiusIncrement?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxSearchRadius?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  externalOrderMarkupRate?: number;

  @IsOptional()
  @IsString()
  termsAndConditions?: string;

  @IsOptional()
  @IsString()
  privacyPolicy?: string;

  @IsOptional()
  @IsString()
  aboutUs?: string;
}
