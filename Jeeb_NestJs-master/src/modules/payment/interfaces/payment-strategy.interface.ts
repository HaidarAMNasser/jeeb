export interface PaymentResult {
  success: boolean;
  transactionId?: string;
  message?: string;
  metadata?: any;
}

export interface PaymentStrategy {
  /**
   * معالجة الدفع
   * @param amount المبلغ المطلوب خصمه
   * @param metadata بيانات إضافية (مثل رقم الهاتف لـ Syriatel Cash)
   */
  processPayment(amount: number, metadata?: any): Promise<PaymentResult>;

  /**
   * التحقق من حالة العملية (للعمليات غير المتزامنة مثل Webhooks)
   */
  validateTransaction(transactionId: string): Promise<boolean>;
}
