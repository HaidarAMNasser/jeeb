import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { SettingsController } from '../../../../src/modules/settings/settings.controller';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { RolesGuard } from '../../../../src/common/guards/roles.guard';

describe('SettingsController', () => {
  let controller: SettingsController;
  let settingsService: jest.Mocked<SettingsService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SettingsController],
      providers: [
        {
          provide: SettingsService,
          useValue: {
            getAllSettings: jest.fn(),
            updateSettings: jest.fn(),
            deleteSettingById: jest.fn(),
          },
        },
        { provide: JwtService, useValue: { signAsync: jest.fn(), decode: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn() } },
        Reflector,
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .compile();

    controller = module.get<SettingsController>(SettingsController);
    settingsService = module.get(SettingsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getAllSettings (GET /settings)', () => {
    it('should return all settings', async () => {
      const expected = { supportPhone: { key: 'supportPhone', value: '+963' } };
      settingsService.getAllSettings.mockResolvedValue(expected);

      const result = await controller.getAllSettings();

      expect(settingsService.getAllSettings).toHaveBeenCalled();
      expect(result).toEqual(expected);
    });
  });

  describe('updateSettings (PATCH /settings)', () => {
    it('should delegate to service', async () => {
      const body = [{ key: 'supportPhone', value: '+964' }];
      settingsService.updateSettings.mockResolvedValue([]);

      await controller.updateSettings(body as any);

      expect(settingsService.updateSettings).toHaveBeenCalledWith(body);
    });
  });

  describe('deleteSetting (DELETE /settings/:id)', () => {
    it('should delegate to service', async () => {
      settingsService.deleteSettingById.mockResolvedValue(undefined);

      await controller.deleteSetting(1);

      expect(settingsService.deleteSettingById).toHaveBeenCalledWith(1);
    });
  });
});
