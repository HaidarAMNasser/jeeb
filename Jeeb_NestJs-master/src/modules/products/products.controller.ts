import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseInterceptors,
  UploadedFiles,
  ParseFilePipeBuilder,
  HttpStatus,
  UseGuards,
  Req,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { GetProductsQueryDto } from './dto/get-products-query.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';

import { PRODUCTS_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(PRODUCTS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @Roles(UserRole.MERCHANT, UserRole.ADMIN)
  @UseInterceptors(FilesInterceptor('images', 5))
  create(
    @Body() createProductDto: CreateProductDto,
    @UploadedFiles(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024,
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    files: Array<Express.Multer.File>,
    @CurrentUser() user: UserPayload,
  ) {
    return this.productsService.create(
      createProductDto,
      files,
      user.id,
      user.role,
    );
  }

  @Get()
  findAll(
    @Query() query: GetProductsQueryDto,
    @CurrentUser() user: UserPayload,
    @Req() req: any,
  ) {
    if (!query.merchantId && req.query?.merchantId) {
      query.merchantId = Number(req.query.merchantId);
    }
    if (!query.categoryId && req.query?.categoryId) {
      query.categoryId = Number(req.query.categoryId);
    }

    return this.productsService.findAll(query, user.id, user.role);
  }

  @Get(PRODUCTS_ROUTES.GET_ONE)
  findOne(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return this.productsService.findOne(+id, user.id, user.role);
  }

  @Patch(PRODUCTS_ROUTES.UPDATE)
  @UseInterceptors(FilesInterceptor('images', 5))
  update(
    @Param('id') id: string,
    @Body() updateProductDto: UpdateProductDto,
    @UploadedFiles(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024,
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    files: Array<Express.Multer.File>,
    @CurrentUser() user: UserPayload,
  ) {
    return this.productsService.update(
      +id,
      updateProductDto,
      files,
      user.id,
      user.role,
    );
  }

  @Delete(PRODUCTS_ROUTES.DELETE)
  remove(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return this.productsService.remove(+id, user.id, user.role);
  }

  @Delete(PRODUCTS_ROUTES.DELETE_IMAGE)
  removeImage(
    @Param('imageId') imageId: string,
    @CurrentUser() user: UserPayload,
  ) {
    return this.productsService.deleteImage(+imageId, user.id, user.role);
  }
}
