import { Injectable, Logger } from '@nestjs/common';
import { PaymentMethod } from '../../../common/enums/payment.enum';
import {
  PaymentStrategy,
  PaymentResult,
  RefundResult,
} from './payment-strategy.interface';

interface WalletMetadata {
  userId?: number;
  balance?: number;
}

@Injectable()
export class WalletPaymentStrategy implements PaymentStrategy {
  private readonly logger = new Logger(WalletPaymentStrategy.name);

  readonly method = PaymentMethod.WALLET;

  async processPayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<PaymentResult> {
    const walletMetadata = metadata as WalletMetadata;
    const userId = walletMetadata?.userId;
    const balance = (walletMetadata?.balance as number) ?? 0;

    this.logger.log(`Processing wallet payment: ${amount} for user ${userId}`);

    // In a real implementation, this would:
    // 1. Check user's wallet balance
    // 2. Deduct from wallet
    // 3. Create transaction record

    return {
      success: true,
      transactionId: `WALLET_${Date.now()}`,
      message: 'Wallet payment successful',
      metadata: {
        walletBalance: balance - amount,
      },
    };
  }

  async refundPayment(
    transactionId: string,
    amount: number,
  ): Promise<RefundResult> {
    this.logger.log(
      `Processing wallet refund: ${amount} for transaction ${transactionId}`,
    );

    return {
      success: true,
      refundId: `REFUND_WALLET_${Date.now()}`,
      message: 'Wallet refund processed',
    };
  }

  async validatePayment(
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<boolean> {
    const walletMetadata = metadata as WalletMetadata;
    const balance = (walletMetadata?.balance as number) ?? 0;
    return balance >= amount && amount > 0;
  }
}
