import { PipeTransform, Injectable, ArgumentMetadata } from '@nestjs/common';

@Injectable()
export class FormDataParsePipe implements PipeTransform {
  transform(value: any): any {
    if (!value || typeof value !== 'object') {
      return value;
    }

    if (value.deleteImageIds !== undefined) {
      const val = value.deleteImageIds;

      if (Array.isArray(val)) {
        value.deleteImageIds = val
          .map((v: any) => Number(v))
          .filter((v: number) => !isNaN(v));
      } else if (typeof val === 'string') {
        try {
          const parsed = JSON.parse(val);
          if (Array.isArray(parsed)) {
            value.deleteImageIds = parsed.map((v: any) => Number(v));
          } else if (!isNaN(Number(parsed))) {
            value.deleteImageIds = [Number(parsed)];
          }
        } catch {
          if (val.includes(',')) {
            value.deleteImageIds = val
              .split(',')
              .map((v: string) => Number(v.trim()))
              .filter((v: number) => !isNaN(v));
          } else if (!isNaN(Number(val))) {
            value.deleteImageIds = [Number(val)];
          }
        }
      }
    }

    if (value.location !== undefined) {
      const val = value.location;
      if (typeof val === 'string') {
        try {
          value.location = JSON.parse(val);
        } catch {
          // Keep as string if not valid JSON
        }
      } else if (typeof val === 'object' && val !== null) {
        // Handle nested object { lat: "30.0444", lng: "31.2357" }
        if (val.lat !== undefined) {
          value.location = {
            lat: Number(val.lat),
            lng: val.lng !== undefined ? Number(val.lng) : undefined,
          };
        }
      }
    }

    return value;
  }
}
