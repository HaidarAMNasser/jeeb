import {
  PaymentResult,
  PaymentStrategy,
} from '../interfaces/payment-strategy.interface';
import { Injectable } from '@nestjs/common';

@Injectable()
export class StripePaymentStrategy implements PaymentStrategy {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  processPayment(amount: number, metadata?: unknown): Promise<PaymentResult> {
    return Promise.resolve({
      success: true,
      transactionId: `pi_${Date.now()}`, // Payment Intent ID
      message: 'Stripe payment intent created',
    });
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  validateTransaction(transactionId: string): Promise<boolean> {
    // التحقق من Stripe API
    return Promise.resolve(true);
  }
}
