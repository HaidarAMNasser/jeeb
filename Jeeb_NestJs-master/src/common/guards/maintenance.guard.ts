import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { SettingsService } from '../../modules/settings/settings.service';
import { ErrorCodes } from '../constants/error-codes';

@Injectable()
export class MaintenanceGuard implements CanActivate {
  constructor(private readonly settingsService: SettingsService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const isMaintenanceMode =
        await this.settingsService.getSettingByKey('isMaintenanceMode');

      // If maintenance mode is active, throw ServiceUnavailableException
      // We convert the value to boolean in case it's stored as string "true"/"false"
      if (
        isMaintenanceMode &&
        (isMaintenanceMode.value === true || isMaintenanceMode.value === 'true')
      ) {
        throw new ServiceUnavailableException({
          statusCode: 503,
          message: 'التطبيق تحت الصيانه حالياً، يرجى المحاولة لاحقاً.',
          error: `ERROR_${ErrorCodes.MAINTENANCE_MODE.code}`,
          timestamp: new Date().toISOString(),
          path: context.switchToHttp().getRequest().url,
        });
      }
    } catch (error) {
      // If the setting doesn't exist yet or there's an error, we proceed as normal
      // unless it's the ServiceUnavailableException we just threw.
      if (error instanceof ServiceUnavailableException) {
        throw error;
      }
    }

    return true;
  }
}
