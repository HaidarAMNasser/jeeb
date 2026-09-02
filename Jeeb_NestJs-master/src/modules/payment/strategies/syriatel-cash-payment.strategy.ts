import {
  PaymentResult,
  PaymentStrategy,
} from '../interfaces/payment-strategy.interface';
import { Injectable } from '@nestjs/common';

@Injectable()
export class SyriatelCashPaymentStrategy implements PaymentStrategy {
  processPayment(amount: number, metadata?: any): Promise<PaymentResult> {
    // هنا يتم الاتصال بـ API سيريتل كاش
    // محاكاة للعملية حالياً
    const phoneNumber = metadata?.phoneNumber as string;

    if (!phoneNumber) {
      return Promise.resolve({
        success: false,
        message: 'Phone number is required for Syriatel Cash',
      });
    }

    // محاكاة رد ناجح
    return Promise.resolve({
      success: true,
      transactionId: `SYR-${Date.now()}`,
      message: 'Syriatel Cash payment request sent successfully',
    });
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  validateTransaction(transactionId: string): Promise<boolean> {
    // محاكاة التحقق من الحالة
    return Promise.resolve(true);
  }
}
