export interface BlazeConfig {
  apiKey: string;
  baseUrl: string;
}

export const blazeConfig = (): BlazeConfig => ({
  apiKey: process.env.BLAZE_API_KEY || '',
  baseUrl: process.env.BLAZE_BASE_URL || 'https://blazeai.boxu.dev/api/v1',
});
