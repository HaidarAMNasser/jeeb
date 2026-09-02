🏗 اسم المعمارية المعتمدة

Modular Monolith with Lightweight Domain-Driven Design

🎯 ماذا تعني؟
🔹 Monolith

تطبيق Backend واحد
قاعدة بيانات واحدة
Deployment واحد

🔹 Modular

مقسم داخليًا إلى Domains مستقلة منطقيًا

🔹 Lightweight DDD

كل Domain يحتوي:

Entities

Business Logic

Enums

DTOs

بدون تعقيد طبقات Clean Architecture الكاملة.

📐 الشكل المعماري العام
                   ┌────────────────────┐
                   │     Flutter App     │
                   └──────────┬─────────┘
                              │ REST API
                              ▼
                ┌───────────────────────────┐
                │        NestJS Backend      │
                │  (Modular Monolith Core)   │
                ├───────────────────────────┤
                │  Auth Module               │
                │  Users Module              │
                │  Orders Module             │
                │  Delivery Module           │
                │  Wallet Module             │
                │  Payments Module           │
                │  GPS Module                │
                │  Admin Module              │
                └──────────┬────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
  PostgreSQL            Redis             Firebase
 (Main DB)          (Cache & Queue)   (Live GPS Only)
🧱 القالب العام (Template Pattern)

داخل كل Module:

module-name/
 ├── module-name.module.ts
 ├── module-name.controller.ts
 ├── module-name.service.ts
 ├── dto/
 ├── entities/
 └── enums/
🧠 مثال واضح من مشروعك

سنأخذ مثال:

🎯 Order Assignment مع Cash Logic
📦 1️⃣ Orders Module
order.entity.ts
@Entity()
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  customerId: number;

  @Column()
  deliveryId: number;

  @Column()
  totalAmount: number;

  @Column()
  paymentMethod: string;

  @Column()
  status: string;
}
💰 2️⃣ Wallet Module
@Entity()
export class Wallet {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  deliveryId: number;

  @Column({ default: 0 })
  balance: number;
}
🧠 Business Flow Example
عند Assign طلب Cash:
Controller يستقبل الطلب
POST /orders/assign
OrdersService:
async assignOrder(orderId: number, deliveryId: number) {

   const order = await this.orderRepo.findOne({ where: { id: orderId } });

   if(order.paymentMethod === 'CASH') {
      await this.walletService.deductForCashOrder(deliveryId, order.totalAmount);
   }

   order.deliveryId = deliveryId;
   order.status = 'ASSIGNED';

   return this.orderRepo.save(order);
}
📡 GPS Module (Hybrid)
أثناء التوصيل:

Flutter → Firebase

عند التسليم:

Flutter → Nest
Nest → PostgreSQL (save final location)

🔥 لماذا هذه المعمارية مناسبة لك؟

✔ فريق صغير
✔ 1000–10000 مستخدم
✔ إطلاق خلال شهرين
✔ قابل للتوسع لاحقًا
✔ منطق مالي منظم

🧠 الفكرة الجوهرية

كل Domain مسؤول عن نفسه

منطق الأعمال داخل Services

Firebase ليس مصدر الحقيقة

PostgreSQL هو المصدر الرسمي

Redis للمهام الخلفية