import { Injectable, Logger } from '@nestjs/common';
import { PaymentMethod } from '../../../common/enums/payment.enum';
import {
  PaymentStrategy,
  PaymentResult,
  RefundResult,
} from './payment-strategy.interface';

@Injectable()
export class CashPaymentStrategy implements PaymentStrategy {
  private readonly logger = new Logger(CashPaymentStrategy.name);

  readonly method = PaymentMethod.CASH;

  async processPayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<PaymentResult> {
    this.logger.log(
      `Processing cash payment: ${amount} for order ${metadata?.orderId}`,
    );

    return {
      success: true,
      transactionId: `CASH_${Date.now()}`,
      message: 'Cash payment accepted',
      metadata: {
        collectedAt: new Date().toISOString(),
        collectorId: metadata?.collectorId,
      },
    };
  }

  async refundPayment(
    transactionId: string,
    amount: number,
  ): Promise<RefundResult> {
    this.logger.log(
      `Processing cash refund: ${amount} for transaction ${transactionId}`,
    );

    return {
      success: true,
      refundId: `REFUND_CASH_${Date.now()}`,
      message: 'Cash refund processed',
    };
  }

  async validatePayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<boolean> {
    return amount > 0;
  }
}
