import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { SystemSetting } from '../../../../src/database/entities/system-setting.entity';

describe('SettingsService', () => {
  let service: SettingsService;
  let settingsRepo: any;

  beforeEach(async () => {
    settingsRepo = {
      findOne: jest.fn(),
      find: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
      remove: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SettingsService,
        { provide: getRepositoryToken(SystemSetting), useValue: settingsRepo },
      ],
    }).compile();

    service = module.get<SettingsService>(SettingsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getAllSettings', () => {
    it('should return filtered settings as key-value map', async () => {
      settingsRepo.find.mockResolvedValue([
        { id: 1, key: 'supportPhone', value: '+963', description: 'Phone', isActive: true },
        { id: 2, key: 'internalKey', value: 'secret', description: 'Hidden', isActive: true },
      ]);

      const result = await service.getAllSettings();

      expect(result.supportPhone).toBeDefined();
      expect(result.internalKey).toBeUndefined();
    });
  });

  describe('getSettings', () => {
    it('should return only active settings values', async () => {
      settingsRepo.find.mockResolvedValue([
        { id: 1, key: 'supportPhone', value: '+963', description: 'Phone', isActive: true },
        { id: 2, key: 'inactiveKey', value: 'val', description: 'Inactive', isActive: false },
      ]);

      const result = await service.getSettings();

      expect(result.supportPhone).toBe('+963');
      expect(result.inactiveKey).toBeUndefined();
    });
  });

  describe('getSettingByKey', () => {
    it('should return setting when found', async () => {
      const setting = { id: 1, key: 'supportPhone', value: '+963' };
      settingsRepo.findOne.mockResolvedValue(setting);

      const result = await service.getSettingByKey('supportPhone');

      expect(settingsRepo.findOne).toHaveBeenCalledWith({ where: { key: 'supportPhone' } });
      expect(result).toEqual(setting);
    });

    it('should throw NotFoundException when not found', async () => {
      settingsRepo.findOne.mockResolvedValue(null);

      await expect(service.getSettingByKey('unknown')).rejects.toThrow(NotFoundException);
    });
  });

  describe('updateSettings', () => {
    it('should update existing settings and create new ones', async () => {
      settingsRepo.findOne
        .mockResolvedValueOnce({ id: 1, key: 'existing', value: 'old' })
        .mockResolvedValueOnce(null);
      settingsRepo.create.mockReturnValue({ key: 'newKey', value: 'newVal' });
      settingsRepo.save.mockImplementation((s) => Promise.resolve(s));

      const result = await service.updateSettings([
        { key: 'existing', value: 'updated' },
        { key: 'newKey', value: 'newVal' },
      ]);

      expect(settingsRepo.save).toHaveBeenCalledTimes(2);
      expect(result).toHaveLength(2);
    });
  });

  describe('deleteSettingById', () => {
    it('should delete setting when found', async () => {
      const setting = { id: 1, key: 'test', value: 'val' };
      settingsRepo.findOne.mockResolvedValue(setting);
      settingsRepo.remove.mockResolvedValue(undefined);

      await service.deleteSettingById(1);

      expect(settingsRepo.remove).toHaveBeenCalledWith(setting);
    });

    it('should throw NotFoundException when not found', async () => {
      settingsRepo.findOne.mockResolvedValue(null);

      await expect(service.deleteSettingById(999)).rejects.toThrow(NotFoundException);
    });
  });
});
