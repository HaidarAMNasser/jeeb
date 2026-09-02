import { BadRequestException } from '@nestjs/common';
import { CreateProductDto } from '../dto/create-product.dto';
import { UpdateProductDto } from '../dto/update-product.dto';
import { Product } from '../../../database/entities/product.entity';

export class ProductStockValidator {
  static validateStockForCreate(createProductDto: CreateProductDto): void {
    if (
      createProductDto.hasStock &&
      (createProductDto.stockQuantity === undefined ||
        createProductDto.stockQuantity === null)
    ) {
      throw new BadRequestException(
        'Stock quantity is required when hasStock is true',
      );
    }
  }

  static validateStockForUpdate(
    product: Product,
    updateProductDto: UpdateProductDto,
  ): void {
    if (
      product.hasStock &&
      (product.stockQuantity === undefined || product.stockQuantity === null)
    ) {
      if (
        updateProductDto.hasStock === true &&
        updateProductDto.stockQuantity === undefined
      ) {
        throw new BadRequestException(
          'Stock quantity is required when enabling stock',
        );
      }
    }
  }
}
