أنت أضفت دور جديد:

👑 Admin
🏪 Merchant (صاحب مطعم) ← جديد
🚚 Delivery
👤 Customer

ونريد إضافة:

إدارة مطاعم

CRUD منتجات

بحث وفلترة

رؤية الفواتير الخاصة بالمطعم فقط

احترام البنية:

Modular Monolith

Lightweight DDD

RBAC

PostgreSQL

دعنا نصممها بشكل نظيف هندسيًا 👇

🎯 أولًا: إضافة الدور الجديد
تحديث Enum
export enum UserRole {
  ADMIN = 'ADMIN',
  MERCHANT = 'MERCHANT',
  DELIVERY = 'DELIVERY',
  CUSTOMER = 'CUSTOMER'
}
🏗 ثانيًا: تصميم البنية (Modules)

سنضيف Modules جديدة:

restaurants

products

merchant-dashboard (اختياري تنظيمي)

invoices

🧠 التصميم الصحيح Domainيًا
1️⃣ Restaurant Entity
@Entity('restaurants')
export class Restaurant {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  ownerId: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'ownerId' })
  owner: User;

  @Column({ default: true })
  isActive: boolean;

  @Column()
  cityId: number;
}

⚠ كل مطعم له Owner واحد (MERCHANT)

2️⃣ Product Entity
@Entity('products')
export class Product {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  restaurantId: number;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  name: string;

  @Column({ type: 'integer' })
  price: number; // smallest currency unit

  @Column({ default: true })
  isAvailable: boolean;
}
🔐 الآن أهم نقطة: الصلاحيات
القاعدة الذهبية:

Merchant يرى ويدير فقط المطاعم التي يملكها

🎯 كيف نطبق ذلك هندسيًا؟
في كل Service

لا تعتمد فقط على Guard
بل تحقق من الملكية داخل الـ Service

مثال:

async updateProduct(productId: number, merchantId: number) {

  const product = await this.productRepo.findOne({
    where: { id: productId },
    relations: ['restaurant'],
  });

  if (product.restaurant.ownerId !== merchantId) {
    throw new ForbiddenException();
  }

  return product;
}

🔥 هذا مهم جدًا.

🧠 نمط التصميم المستخدم

Ownership Pattern

RBAC

Service-Level Authorization

🏪 ماذا يستطيع Merchant؟

CRUD Restaurant (لو واحد فقط → تعديل فقط)

CRUD Products

رؤية طلبات مطعمه

رؤية الفواتير الخاصة به

فلترة الطلبات حسب:

التاريخ

الحالة

المدينة

📦 كيف يرى طلباته فقط؟

في Order Entity أضف:

@Column()
restaurantId: number;

ثم عند جلب الطلبات:

where: {
  restaurant: {
    ownerId: merchantId
  }
}
🧾 نظام الفواتير

لا تجعل Invoice منفصل عن Order.

بما أن Order هو مصدر الحقيقة.

يمكنك:

إضافة داخل Order:

@Column({ type: 'integer' })
platformCommission: number;

@Column({ type: 'integer' })
restaurantRevenue: number;

ثم Merchant يرى:

إجمالي المبيعات

عمولة المنصة

صافي الربح

🧠 هل نحتاج Invoice Table؟

فقط إذا:

تريد توليد PDF

تريد أرشفة شهرية

تريد قفل الفواتير بعد فترة

في هذه الحالة:

@Entity('invoices')
export class Invoice {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  restaurantId: number;

  @Column()
  fromDate: Date;

  @Column()
  toDate: Date;

  @Column({ type: 'integer' })
  totalAmount: number;

  @Column({ type: 'integer' })
  commission: number;

  @Column({ type: 'integer' })
  netAmount: number;

  @Column({ default: false })
  isPaid: boolean;
}
🔎 البحث والفلترة

استخدم Query Builder في TypeORM:

const query = this.orderRepo.createQueryBuilder('order')
  .where('order.restaurantId = :restaurantId', { restaurantId })
  .andWhere('order.createdAt BETWEEN :from AND :to', { from, to });
🏗 الشكل النهائي للمعمارية بعد إضافة Merchant
modules/
│
├── users
├── auth
├── restaurants
├── products
├── orders
├── deliveries
├── invoices
├── payments
├── countries
├── cities
🔥 هل نحتاج علاقة Merchant ←→ Restaurant متعددة؟

سؤال مهم:

هل التاجر يملك مطعم واحد فقط؟
أم يمكن أن يملك عدة مطاعم؟

إذا يمكن عدة مطاعم
فالتصميم الحالي ممتاز.

🚀 أفضل ممارسة احترافية

أنصحك بإضافة:

@Column({ default: false })
isApproved: boolean;

لـ Restaurant

حتى يقوم Admin بالموافقة قبل نشره.