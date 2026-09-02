import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AreasService } from './areas.service';
import { CreateAreaDto } from './dto/create-area.dto';
import { UpdateAreaDto } from './dto/update-area.dto';
import { GetAreasQueryDto } from './dto/get-areas-query.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { AREAS_ROUTES } from '../../common/constants/api-routes.constants';
import type { UserPayload } from '../../common/interfaces/user-payload.interface';

@ApiTags('Areas')
@Controller(AREAS_ROUTES.BASE)
export class AreasController {
  constructor(private readonly areasService: AreasService) {}

  @ApiOperation({ summary: 'Create area (Admin only)' })
  @ApiBearerAuth('JWT-auth')
  @ApiResponse({ status: 201, description: 'Area created successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin only' })
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  create(
    @Body() createAreaDto: CreateAreaDto,
    @CurrentUser() user: UserPayload,
  ) {
    return this.areasService.create(createAreaDto, user.role);
  }

  @ApiOperation({ summary: 'Get all areas with pagination and filters' })
  @ApiResponse({ status: 200, description: 'Areas retrieved successfully' })
  @Get()
  @Public()
  findAll(@Query() query: GetAreasQueryDto) {
    return this.areasService.findAll(query);
  }

  @ApiOperation({ summary: 'Get area by ID' })
  @ApiResponse({ status: 200, description: 'Area retrieved successfully' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  @Get(AREAS_ROUTES.GET_ONE)
  @Public()
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.areasService.findOne(id);
  }

  @ApiOperation({ summary: 'Update area (Admin only)' })
  @ApiBearerAuth('JWT-auth')
  @ApiResponse({ status: 200, description: 'Area updated successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin only' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  @Patch(AREAS_ROUTES.UPDATE)
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateAreaDto: UpdateAreaDto,
    @CurrentUser() user: UserPayload,
  ) {
    return this.areasService.update(id, updateAreaDto, user.role);
  }

  @ApiOperation({ summary: 'Delete area (Admin only)' })
  @ApiBearerAuth('JWT-auth')
  @ApiResponse({ status: 200, description: 'Area deleted successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin only' })
  @ApiResponse({ status: 404, description: 'Area not found' })
  @Delete(AREAS_ROUTES.DELETE)
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  remove(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: UserPayload,
  ) {
    return this.areasService.remove(id, user.role);
  }
}
