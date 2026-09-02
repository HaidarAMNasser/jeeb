import { CashPaymentStrategy } from '../../../../src/modules/orders/strategies/cash-payment.strategy';

describe('CashPaymentStrategy', () => {
  let strategy: CashPaymentStrategy;

  beforeEach(() => {
    strategy = new CashPaymentStrategy();
  });

  describe('processPayment', () => {
    it('يعالج الدفع النقدي بنجاح', async () => {
      const result = await strategy.processPayment(5000, {
        orderId: 1,
        collectorId: 5,
      });

      expect(result.success).toBe(true);
      expect(result.transactionId).toContain('CASH_');
      expect(result.message).toBe('Cash payment accepted');
    });
  });

  describe('refundPayment', () => {
    it('يعالج استرداد الدفع النقدي', async () => {
      const result = await strategy.refundPayment('CASH_123', 5000);

      expect(result.success).toBe(true);
      expect(result.refundId).toContain('REFUND_CASH_');
    });
  });

  describe('validatePayment', () => {
    it('يقبل المبلغ الموجب', async () => {
      const result = await strategy.validatePayment(100);
      expect(result).toBe(true);
    });

    it('يرفض المبلغ الصفري', async () => {
      const result = await strategy.validatePayment(0);
      expect(result).toBe(false);
    });
  });
});
