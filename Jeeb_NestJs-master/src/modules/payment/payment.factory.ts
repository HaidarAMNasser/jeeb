import { Injectable, NotFoundException } from '@nestjs/common';
import { PaymentMethod, PaymentProvider } from '../../common/enums';
import { PaymentStrategy } from './interfaces/payment-strategy.interface';
import { CashPaymentStrategy } from './strategies/cash-payment.strategy';
import { SyriatelCashPaymentStrategy } from './strategies/syriatel-cash-payment.strategy';
import { StripePaymentStrategy } from './strategies/stripe-payment.strategy';

@Injectable()
export class PaymentFactory {
  constructor(
    private readonly cashStrategy: CashPaymentStrategy,
    private readonly syriatelStrategy: SyriatelCashPaymentStrategy,
    private readonly stripeStrategy: StripePaymentStrategy,
  ) {}

  getStrategy(
    method: PaymentMethod,
    provider?: PaymentProvider,
  ): PaymentStrategy {
    if (method === PaymentMethod.CASH) {
      return this.cashStrategy;
    }

    if (method === PaymentMethod.ONLINE) {
      if (!provider) {
        throw new NotFoundException(
          'Payment provider is required for ONLINE payment method.',
        );
      }

      switch (provider) {
        case PaymentProvider.SYRIATEL_CASH:
          return this.syriatelStrategy;
        case PaymentProvider.STRIPE:
          return this.stripeStrategy;
        // case PaymentProvider.USDT: return this.usdtStrategy;
        default:
          throw new NotFoundException(
            `Payment provider ${provider} is not supported yet.`,
          );
      }
    }

    throw new NotFoundException(
      `Payment method ${method} is not supported yet.`,
    );
  }
}
