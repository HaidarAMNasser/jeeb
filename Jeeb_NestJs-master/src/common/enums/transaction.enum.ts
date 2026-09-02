export enum TransactionType {
  DEBIT = 'DEBIT', // خصم (دفع)
  CREDIT = 'CREDIT', // إضافة (شحن/ربح)
}

export enum TransactionReason {
  ORDER_PAYMENT = 'ORDER_PAYMENT',
  DELIVERY_FEE = 'DELIVERY_FEE',
  TIP = 'TIP',
  PENALTY = 'PENALTY',
  WITHDRAWAL = 'WITHDRAWAL', // سحب رصيد من المحفظة
  DEPOSIT = 'DEPOSIT', // شحن المحفظة
  REFUND = 'REFUND', // استعادة اموال
  COMPENSATION = 'COMPENSATION', // تعويض
  SUBSCRIPTION = 'SUBSCRIPTION', // اشتراك (إن وجد)
}
