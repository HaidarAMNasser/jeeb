export enum OrderStatus {
  PENDING = 'PENDING', // الطلبوصل ولم يقبله المطعر بعد
  CONFIRMED = 'CONFIRMED', // المطععم قبل الطلب
  PREPARING = 'PREPARING', // المطعم يقوم بتجهيز الطلب
  SEARCHING = 'SEARCHING', // جاري البحث عن سائق
  ASSIGNED = 'ASSIGNED', // تم تعيين سائق
  READY_FOR_PICKUP = 'READY_FOR_PICKUP', // جاهز للاستلام
  PICKED_UP = 'PICKED_UP', // السائق استلم الطلب
  ON_THE_WAY = 'ON_THE_WAY', // السائق في الطريق
  DELIVERED = 'DELIVERED', // تم التوصيل
  PAID = 'PAID', // السائق رفع أيصال الدفع
  COMPLETE = 'COMPLETE', // الأدمن تأكد من الأيصالأل
  CANCELLED = 'CANCELLED', // ملغى من العميل أو النظام
  REJECTED = 'REJECTED', // مرفوض من المطعم
}
