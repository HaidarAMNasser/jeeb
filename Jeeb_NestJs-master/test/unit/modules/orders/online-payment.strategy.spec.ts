import { OnlinePaymentStrategy } from '../../../../src/modules/orders/strategies/online-payment.strategy';
import { PaymentProvider } from '../../../../src/common/enums/payment.enum';

describe('OnlinePaymentStrategy', () => {
  let strategy: OnlinePaymentStrategy;

  beforeEach(() => {
    strategy = new OnlinePaymentStrategy();
  });

  describe('processPayment', () => {
    it('يعالج دفع Stripe', async () => {
      const result = await strategy.processPayment(5000, {
        provider: PaymentProvider.STRIPE,
        orderId: 1,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('STRIPE_');
    });

    it('يعالج دفع PayPal', async () => {
      const result = await strategy.processPayment(5000, {
        provider: PaymentProvider.PAYPAL,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('PAYPAL_');
    });

    it('يعالج دفع MTN Cash', async () => {
      const result = await strategy.processPayment(5000, {
        provider: PaymentProvider.MTN_CASH,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('MTN_');
    });

    it('يعالج دفع Syriatel Cash', async () => {
      const result = await strategy.processPayment(5000, {
        provider: PaymentProvider.SYRIATEL_CASH,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('SYRIATEL_');
    });

    it('يستخدم provider افتراضي STRIPE عند عدم التحديد', async () => {
      const result = await strategy.processPayment(5000, { orderId: 1 });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('STRIPE_');
    });
  });

  describe('refundPayment', () => {
    it('يعالج استرداد الدفع الإلكتروني', async () => {
      const result = await strategy.refundPayment('STRIPE_123', 5000);

      expect(result.success).toBe(true);
      expect(result.refundId).toContain('REFUND_ONLINE_');
    });
  });

  describe('validatePayment', () => {
    it('يقبل Stripe', async () => {
      const result = await strategy.validatePayment(100, {
        provider: PaymentProvider.STRIPE,
      });
      expect(result).toBe(true);
    });

    it('يقبل PayPal', async () => {
      const result = await strategy.validatePayment(100, {
        provider: PaymentProvider.PAYPAL,
      });
      expect(result).toBe(true);
    });

    it('يقبل MTN Cash مع رقم هاتف صحيح', async () => {
      const result = await strategy.validatePayment(100, {
        provider: PaymentProvider.MTN_CASH,
        phoneNumber: '966512345678',
      });
      expect(result).toBe(true);
    });

    it('يرفض MTN Cash بدون رقم هاتف', async () => {
      const result = await strategy.validatePayment(100, {
        provider: PaymentProvider.MTN_CASH,
      });
      expect(result).toBe(false);
    });

    it('يرفض المبلغ الصفري', async () => {
      const result = await strategy.validatePayment(0, {
        provider: PaymentProvider.STRIPE,
      });
      expect(result).toBe(false);
    });
  });
});
