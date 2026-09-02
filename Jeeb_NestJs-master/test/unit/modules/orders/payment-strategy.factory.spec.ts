import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { PaymentStrategyFactory } from '../../../../src/modules/orders/strategies/payment-strategy.factory';
import { CashPaymentStrategy } from '../../../../src/modules/orders/strategies/cash-payment.strategy';
import { WalletPaymentStrategy } from '../../../../src/modules/orders/strategies/wallet-payment.strategy';
import { OnlinePaymentStrategy } from '../../../../src/modules/orders/strategies/online-payment.strategy';
import { PaymentMethod } from '../../../../src/common/enums/payment.enum';

describe('PaymentStrategyFactory', () => {
  let factory: PaymentStrategyFactory;
  let cashStrategy: CashPaymentStrategy;
  let walletStrategy: WalletPaymentStrategy;
  let onlineStrategy: OnlinePaymentStrategy;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentStrategyFactory,
        CashPaymentStrategy,
        WalletPaymentStrategy,
        OnlinePaymentStrategy,
      ],
    }).compile();

    factory = module.get<PaymentStrategyFactory>(PaymentStrategyFactory);
    cashStrategy = module.get(CashPaymentStrategy);
    walletStrategy = module.get(WalletPaymentStrategy);
    onlineStrategy = module.get(OnlinePaymentStrategy);
  });

  describe('getStrategy', () => {
    it('يرجع CashPaymentStrategy لـ CASH', () => {
      const strategy = factory.getStrategy(PaymentMethod.CASH);
      expect(strategy).toBeInstanceOf(CashPaymentStrategy);
    });

    it('يرجع WalletPaymentStrategy لـ WALLET', () => {
      const strategy = factory.getStrategy(PaymentMethod.WALLET);
      expect(strategy).toBeInstanceOf(WalletPaymentStrategy);
    });

    it('يرجع OnlinePaymentStrategy لـ ONLINE', () => {
      const strategy = factory.getStrategy(PaymentMethod.ONLINE);
      expect(strategy).toBeInstanceOf(OnlinePaymentStrategy);
    });

    it('يرمي BadRequestException لطريقة دفع غير مدعومة', () => {
      expect(() => factory.getStrategy('UNKNOWN' as PaymentMethod)).toThrow(
        BadRequestException,
      );
    });
  });

  describe('processPayment', () => {
    it('يعالج الدفع عبر CASH', async () => {
      const result = await factory.processPayment(PaymentMethod.CASH, 100);
      expect(result.success).toBe(true);
    });

    it('يعالج الدفع عبر WALLET', async () => {
      const result = await factory.processPayment(PaymentMethod.WALLET, 100, {
        balance: 200,
      });
      expect(result.success).toBe(true);
    });

    it('يعالج الدفع عبر ONLINE', async () => {
      const result = await factory.processPayment(PaymentMethod.ONLINE, 100);
      expect(result.success).toBe(true);
    });
  });

  describe('getAvailableMethods', () => {
    it('يرجع جميع طرق الدفع المتاحة', () => {
      const methods = factory.getAvailableMethods();
      expect(methods).toContain(PaymentMethod.CASH);
      expect(methods).toContain(PaymentMethod.WALLET);
      expect(methods).toContain(PaymentMethod.ONLINE);
      expect(methods.length).toBe(3);
    });
  });
});
