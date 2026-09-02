import { Injectable, OnModuleInit, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SystemSetting } from '../../database/entities/system-setting.entity';

@Injectable()
export class SettingsService implements OnModuleInit {
  constructor(
    @InjectRepository(SystemSetting)
    private readonly settingsRepo: Repository<SystemSetting>,
  ) {}

  async onModuleInit() {
    await this.initializeDefaultSettings();
  }

  private async initializeDefaultSettings() {
    const defaultSettings = [
      {
        key: 'driverRequestTimeoutSeconds',
        value: 180,
        description: 'Time in seconds to wait for drivers to accept order',
      },
      {
        key: 'driverRequestBatchSize',
        value: 3,
        description: 'Number of drivers to notify in each batch',
      },
      {
        key: 'initialSearchRadius',
        value: 5.0,
        description: 'Initial search radius in km',
      },
      {
        key: 'searchRadiusIncrement',
        value: 2.0,
        description: 'Radius increment for each batch',
      },
      {
        key: 'maxSearchRadius',
        value: 20.0,
        description: 'Maximum search radius in km',
      },
      {
        key: 'externalOrderMarkupRate',
        value: 0.0,
        description: 'Commission rate for external orders',
      },
      {
        key: 'defaultProductCommissionRate',
        value: 10.0,
        description: 'Default commission rate for products',
      },
      {
        key: 'productsAutoConfirmed',
        value: true,
        description: 'Auto-confirm products for customers',
      },
      {
        key: 'supportPhone',
        value: '+963912345678',
        description: 'Customer support phone',
      },
      {
        key: 'supportEmail',
        value: 'support@jeeb.com',
        description: 'Customer support email',
      },
      {
        key: 'whatsappNumber',
        value: '+963912345678',
        description: 'WhatsApp contact number',
      },
      {
        key: 'websiteUrl',
        value: 'https://jeeb.com',
        description: 'Company website URL',
      },
      {
        key: 'address',
        value: 'Damascus, Syria',
        description: 'Company address',
      },
      {
        key: 'termsAndConditions',
        value: '',
        description: 'Terms and Conditions text',
      },
      { key: 'privacyPolicy', value: '', description: 'Privacy Policy text' },
      { key: 'aboutUs', value: '', description: 'About Us text' },
      {
        key: 'deliveryTipPerKilometer',
        value: 500,
        description:
          'Tip amount per kilometer for delivery driver in SYP (for calculating driver tip based on distance)',
      },
      // Global Loyalty System Settings
      {
        key: 'global_loyalty_threshold',
        value: 5,
        description:
          'Number of orders required for customer to earn loyalty points',
      },
      {
        key: 'global_loyalty_points',
        value: 100,
        description: 'Amount of points awarded when threshold is reached',
      },
      {
        key: 'global_loyalty_redeem_points',
        value: 100,
        description: 'Points required to redeem for a discount',
      },
      {
        key: 'global_loyalty_discount_value',
        value: 1000,
        description: 'Monetary discount value given when redeeming points',
      },
      {
        key: 'driverScoringWeights',
        value: JSON.stringify({ distance: 0.4, eta: 0.4, acceptance: 0.2 }),
        description:
          'Weights for smart driver scoring: distance (road distance), eta (estimated arrival time), acceptance (historical acceptance rate)',
      },
      {
        key: 'maxOrdersPerDelivery',
        value: 10,
        description:
          'Maximum number of orders a delivery driver can receive per day',
      },
      {
        key: 'isMaintenanceMode',
        value: false,
        description: 'Whether the system is under maintenance',
      },
    ];

    for (const setting of defaultSettings) {
      const exists = await this.settingsRepo.findOne({
        where: { key: setting.key },
      });
      if (!exists) {
        await this.settingsRepo.save(this.settingsRepo.create(setting));
      }
    }
  }

  async getAllSettings(): Promise<any> {
    const allowedKeys = [
      'defaultProductCommissionRate',
      'productsAutoConfirmed',
      'supportPhone',
      'supportEmail',
      'whatsappNumber',
      'deliveryTipPerKilometer',
      'maxOrdersPerDelivery',
    ];

    const settings = await this.settingsRepo.find({ order: { id: 'ASC' } });
    const filteredSettings = settings.filter((s) =>
      allowedKeys.includes(s.key),
    );

    const result: any = {};
    filteredSettings.forEach((setting) => {
      result[setting.key] = {
        id: setting.id,
        key: setting.key,
        value: setting.value,
        description: setting.description,
        isActive: setting.isActive,
        createdAt: setting.createdAt,
        updatedAt: setting.updatedAt,
      };
    });
    return result;
  }

  async getSettings(): Promise<any> {
    const settings = await this.getAllSettings();
    const result: any = {};
    for (const key of Object.keys(settings)) {
      const setting = settings[key];
      if (setting.isActive) {
        result[setting.key] = setting.value;
      }
    }
    return result;
  }

  async getSettingByKey(key: string): Promise<SystemSetting> {
    const setting = await this.settingsRepo.findOne({ where: { key } });
    if (!setting) {
      throw new NotFoundException(`Setting with key "${key}" not found`);
    }
    return setting;
  }

  async updateSettings(
    updates: { key: string; value: any }[],
  ): Promise<SystemSetting[]> {
    const results: SystemSetting[] = [];
    for (const update of updates) {
      let setting = await this.settingsRepo.findOne({
        where: { key: update.key },
      });
      if (setting) {
        setting.value = update.value;
      } else {
        setting = this.settingsRepo.create({
          key: update.key,
          value: update.value,
        });
      }
      results.push(await this.settingsRepo.save(setting));
    }
    return results;
  }

  async deleteSetting(key: string): Promise<void> {
    const setting = await this.getSettingByKey(key);
    await this.settingsRepo.remove(setting);
  }

  async deleteSettingById(id: number): Promise<void> {
    const setting = await this.settingsRepo.findOne({ where: { id } });
    if (!setting) {
      throw new NotFoundException(`Setting with ID "${id}" not found`);
    }
    await this.settingsRepo.remove(setting);
  }
}
