import { PaymentMethod } from '../../../common/enums/payment.enum';

export interface PaymentStrategy {
  readonly method: PaymentMethod;
  processPayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<PaymentResult>;
  refundPayment(transactionId: string, amount: number): Promise<RefundResult>;
  validatePayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<boolean>;
}

export interface PaymentResult {
  success: boolean;
  transactionId?: string;
  message?: string;
  metadata?: Record<string, unknown>;
}

export interface RefundResult {
  success: boolean;
  refundId?: string;
  message?: string;
}
