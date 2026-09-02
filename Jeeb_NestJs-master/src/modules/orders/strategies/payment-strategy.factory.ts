import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PaymentMethod } from '../../../common/enums/payment.enum';
import { PaymentStrategy } from './payment-strategy.interface';
import { CashPaymentStrategy } from './cash-payment.strategy';
import { WalletPaymentStrategy } from './wallet-payment.strategy';
import { OnlinePaymentStrategy } from './online-payment.strategy';

@Injectable()
export class PaymentStrategyFactory {
  private readonly logger = new Logger(PaymentStrategyFactory.name);
  private readonly strategies: Map<PaymentMethod, PaymentStrategy> = new Map();

  constructor(
    private readonly cashStrategy: CashPaymentStrategy,
    private readonly walletStrategy: WalletPaymentStrategy,
    private readonly onlineStrategy: OnlinePaymentStrategy,
  ) {
    this.strategies.set(PaymentMethod.CASH, cashStrategy);
    this.strategies.set(PaymentMethod.WALLET, walletStrategy);
    this.strategies.set(PaymentMethod.ONLINE, onlineStrategy);
  }

  getStrategy(method: PaymentMethod): PaymentStrategy {
    const strategy = this.strategies.get(method);

    if (!strategy) {
      const availableMethods = Array.from(this.strategies.keys()).join(', ');
      throw new BadRequestException(
        `Unsupported payment method: ${method}. Available methods: ${availableMethods}`,
      );
    }

    return strategy;
  }

  async processPayment(
    method: PaymentMethod,
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<{ success: boolean; transactionId?: string; message?: string }> {
    const strategy = this.getStrategy(method);

    try {
      const result = await strategy.processPayment(amount, metadata);
      return result;
    } catch (error) {
      this.logger.error(`Payment processing failed for ${method}`, error);
      throw new BadRequestException(
        `Payment failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  async refundPayment(
    method: PaymentMethod,
    transactionId: string,
    amount: number,
  ): Promise<{ success: boolean; refundId?: string; message?: string }> {
    const strategy = this.getStrategy(method);

    try {
      const result = await strategy.refundPayment(transactionId, amount);
      return result;
    } catch (error) {
      this.logger.error(`Refund failed for ${method}`, error);
      throw new BadRequestException(
        `Refund failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  async validatePayment(
    method: PaymentMethod,
    amount: number,
    metadata?: Record<string, unknown>,
  ): Promise<boolean> {
    const strategy = this.getStrategy(method);
    return strategy.validatePayment(amount, metadata);
  }

  getAvailableMethods(): PaymentMethod[] {
    return Array.from(this.strategies.keys());
  }
}
