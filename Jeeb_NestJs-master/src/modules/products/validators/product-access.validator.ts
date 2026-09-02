import { ForbiddenException } from '@nestjs/common';
import { Product } from '../../../database/entities/product.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { createErrorResponse } from '../../../common/constants/error-codes';

export class ProductAccessValidator {
  static checkProductReadAccess(
    product: Product,
    userId: number,
    role: UserRole,
  ): void {
    if (!userId || !role) {
      return;
    }

    if (role === UserRole.ADMIN || role === UserRole.MERCHANT) {
      return;
    }

    if (role === UserRole.CUSTOMER || role === UserRole.DELIVERY) {
      return;
    }

    throw new ForbiddenException(
      createErrorResponse(
        'PRODUCT_ACCESS_DENIED',
        403,
        'You do not have permission to view this product',
      ),
    );
  }

  static checkProductOwnership(
    product: Product,
    userId: number,
    role: UserRole,
  ): void {
    if (!userId || !role) {
      throw new ForbiddenException(
        createErrorResponse(
          'PRODUCT_ACCESS_DENIED',
          403,
          'Authentication required to modify products',
        ),
      );
    }

    if (role === UserRole.ADMIN) {
      return;
    }

    if (role !== UserRole.MERCHANT) {
      throw new ForbiddenException(
        createErrorResponse(
          'PRODUCT_ACCESS_DENIED',
          403,
          'Only merchants and admins can modify products',
        ),
      );
    }

    if (product.merchantId !== userId) {
      throw new ForbiddenException(
        createErrorResponse(
          'PRODUCT_NOT_OWNED',
          403,
          'You do not own this product',
        ),
      );
    }
  }
}
