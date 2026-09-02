import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseFilePipeBuilder,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { GetCategoriesQueryDto } from './dto/get-categories-query.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CATEGORIES_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(CATEGORIES_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  @Roles(UserRole.ADMIN)
  @UseInterceptors(FileInterceptor('image'))
  create(
    @Body() createCategoryDto: CreateCategoryDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
    @CurrentUser() user: UserPayload,
  ) {
    return this.categoriesService.create(
      createCategoryDto,
      file,
      user.id,
      user.role,
    );
  }

  @Get()
  findAll(@Query() query: GetCategoriesQueryDto) {
    return this.categoriesService.findAll(query);
  }

  @Get(CATEGORIES_ROUTES.GET_ONE)
  findOne(@Param('id') id: string) {
    return this.categoriesService.findOne(+id);
  }

  @Patch(CATEGORIES_ROUTES.UPDATE)
  @Roles(UserRole.ADMIN)
  @UseInterceptors(FileInterceptor('image'))
  update(
    @Param('id') id: string,
    @Body() updateCategoryDto: UpdateCategoryDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
    @CurrentUser() user: UserPayload,
  ) {
    if (
      updateCategoryDto.displayOrder &&
      typeof updateCategoryDto.displayOrder === 'string'
    ) {
      updateCategoryDto.displayOrder = parseInt(updateCategoryDto.displayOrder);
    }

    if (typeof updateCategoryDto.isActive === 'string') {
      updateCategoryDto.isActive = updateCategoryDto.isActive === 'true';
    }

    return this.categoriesService.update(
      +id,
      updateCategoryDto,
      file,
      user.id,
      user.role,
    );
  }

  @Delete(CATEGORIES_ROUTES.DELETE)
  @Roles(UserRole.ADMIN)
  remove(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return this.categoriesService.remove(+id, user.id, user.role);
  }
}
