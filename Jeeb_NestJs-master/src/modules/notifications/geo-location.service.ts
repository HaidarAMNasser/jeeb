import { Injectable, Logger } from '@nestjs/common';

interface IpApiResponse {
  status: 'success' | 'fail';
  country?: string;
  regionName?: string;
  city?: string;
  query?: string;
}

@Injectable()
export class GeoLocationService {
  private readonly logger = new Logger(GeoLocationService.name);

  async getLocationFromIp(ip: string): Promise<string> {
    if (!ip || ip === '::1' || ip === '127.0.0.1' || ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
      return 'محلي';
    }

    try {
      const response = await fetch(`http://ip-api.com/json/${ip}?fields=status,country,regionName,city,query`, {
        signal: AbortSignal.timeout(3000),
      });

      if (!response.ok) {
        this.logger.warn(`ip-api.com returned status ${response.status} for IP ${ip}`);
        return ip;
      }

      const data: IpApiResponse = await response.json();

      if (data.status !== 'success') {
        this.logger.warn(`ip-api.com failed for IP ${ip}`);
        return ip;
      }

      const parts = [data.city, data.regionName, data.country].filter(Boolean);
      return parts.length > 0 ? parts.join('، ') : ip;
    } catch (error) {
      this.logger.error(`Failed to resolve location for IP ${ip}: ${error.message}`);
      return ip;
    }
  }
}
