export interface DeliveryTimeoutJobData {
  orderId: number;
  driverIds: number[];
  attempt: number;
  currentRadius?: number;
}

export interface DeliveryRetryJobData {
  orderId: number;
  attempt: number;
  currentRadius?: number;
}

export interface ProcessorJobResult {
  success: boolean;
  message?: string;
  nextAction?: 'retry' | 'escalate' | 'manual';
}

export type DeliveryJobType = 'delivery-timeout' | 'delivery-retry';

export interface DeliveryJobData {
  name: DeliveryJobType;
  data: DeliveryTimeoutJobData | DeliveryRetryJobData;
}
