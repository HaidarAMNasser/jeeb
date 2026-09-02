import { WalletPaymentStrategy } from '../../../../src/modules/orders/strategies/wallet-payment.strategy';

describe('WalletPaymentStrategy', () => {
  let strategy: WalletPaymentStrategy;

  beforeEach(() => {
    strategy = new WalletPaymentStrategy();
  });

  describe('processPayment', () => {
    it('يعالج الدفع بالمحفظة بنجاح', async () => {
      const result = await strategy.processPayment(5000, {
        userId: 1,
        balance: 10000,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('WALLET_');
      expect(result.metadata).toEqual({ walletBalance: 5000 });
    });
  });

  describe('refundPayment', () => {
    it('يعالج استرداد المحفظة', async () => {
      const result = await strategy.refundPayment('WALLET_123', 5000);

      expect(result.success).toBe(true);
      expect(result.refundId).toContain('REFUND_WALLET_');
    });
  });

  describe('validatePayment', () => {
    it('يقبل إذا كان الرصيد كافياً', async () => {
      const result = await strategy.validatePayment(5000, { balance: 10000 });
      expect(result).toBe(true);
    });

    it('يرفض إذا كان الرصيد غير كافٍ', async () => {
      const result = await strategy.validatePayment(5000, { balance: 1000 });
      expect(result).toBe(false);
    });

    it('يرفض المبلغ الصفري', async () => {
      const result = await strategy.validatePayment(0, { balance: 1000 });
      expect(result).toBe(false);
    });
  });
});
