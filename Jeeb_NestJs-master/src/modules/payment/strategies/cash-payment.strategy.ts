import {
  PaymentResult,
  PaymentStrategy,
} from '../interfaces/payment-strategy.interface';
import { Injectable } from '@nestjs/common';

@Injectable()
export class CashPaymentStrategy implements PaymentStrategy {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  processPayment(amount: number, metadata?: any): Promise<PaymentResult> {
    // للدفع الكاش، نعتبر العملية ناجحة مبدئياً لكنها معلقة حتى التسليم الفعلي
    return Promise.resolve({
      success: true,
      message: 'Cash payment initiated. Amount to be collected upon delivery.',
      metadata: { collected: false },
    });
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  validateTransaction(transactionId: string): Promise<boolean> {
    return Promise.resolve(true); // الكاش لا يحتاج تحقق خارجي
  }
}
