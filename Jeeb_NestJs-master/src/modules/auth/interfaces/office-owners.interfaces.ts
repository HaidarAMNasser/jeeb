import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

export interface DeliveryDriverQuery extends PaginationQueryDto {
  search?: string;
  status?: 'ACTIVE' | 'INACTIVE';
  cityId?: number;
}

export interface DeliveryDriverStats {
  total: number;
  active: number;
  inactive: number;
  online: number;
  offline: number;
}

export interface OfficeOwnerContext {
  id: number;
  email: string;
  role: string;
}

export interface DeliveryDriverResponse {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  phone: string;
  isActive: boolean;
  isOnline: boolean;
  currentLat?: number;
  currentLng?: number;
  city?: {
    id: number;
    name: string;
  };
  createdAt: Date;
  lastLoginAt?: Date;
}

export interface FileUploadRequest {
  file: Express.Multer.File;
  body: Record<string, string>;
  user: OfficeOwnerContext;
}
