import {
  Controller,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { SettingsService } from './settings.service';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { SETTINGS_ROUTES } from '../../common/constants/api-routes.constants';

@Controller(SETTINGS_ROUTES.BASE)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @Public()
  getAllSettings() {
    return this.settingsService.getAllSettings();
  }

  @Patch()
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  updateSettings(@Body() body: { key: string; value: any }[]) {
    return this.settingsService.updateSettings(body);
  }

  @Delete(SETTINGS_ROUTES.BY_ID)
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  deleteSetting(@Param('id', ParseIntPipe) id: number) {
    return this.settingsService.deleteSettingById(id);
  }
}
