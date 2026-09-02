# 🏗️ شرح نماذج البيانات (Data Models) والعلاقات - Jeeb System

يوضح هذا الملف هيكلية قاعدة البيانات (Database Schema) والـ Entities المستخدمة في نظام **Jeeb**، مع شرح تفصيلي للعلاقات بين الجداول والقرارات التصميمية (Design Decisions).

---

## 0️⃣ الثوابت والقيم المحددة (Enums)

تم توحيد جميع القيم الثابتة (Enums) في ملفات منفصلة لضمان الاتساق وسهولة الصيانة.

- **UserRole**: [`ADMIN`, `CUSTOMER`, `DELIVERY`, `MERCHANT`, `SUPPORT`]
- **OrderStatus**: [`PENDING`, `CONFIRMED`, `PREPARING`, `READY_FOR_PICKUP`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED`, `REJECTED`]
- **PaymentMethod**: [`CASH`, `WALLET`, `ONLINE`]
- **PaymentProvider**: [`STRIPE`, `SYRIATEL_CASH`, `MTN_CASH`, `USDT`, `PAYPAL`, `LOCAL_BANK_TRANSFER`, `UNKNOWN`]
- **DeliveryStatus**: [`ASSIGNED`, `ACCEPTED`, `PICKED`, `COMPLETED`, `REJECTED`]
- **AuditAction**: [`CREATE`, `UPDATE`, `DELETE`, `LOGIN`, `LOGOUT`]
- **TransactionType**: [`CREDIT`, `DEBIT`]
- **ExternalProvider**: [`UBER_EATS`, `TALABAT`, `DOORDASH`, `DELIVEROO`, `JEHEZ`, `HUNGERSTATION`, `UNKNOWN`]
- **CategoryType**: [`CUISINE`, `MENU`]

---

## 1️⃣ المستخدمين والأدوار والموقع (Users, Roles & Location)

### 👤 `User` Entity

الجدول المركزي لإدارة جميع مستخدمي النظام (عملاء، سائقين، أصحاب مطاعم).

- **المبدأ**: Single Table Inheritance (جزئياً) عبر حقل `role`.
- **التحديثات الأخيرة**: تم استبدال `name` بـ `firstName` و `lastName`، وإضافة علاقات مع `Country` و `City` و `Area`.
- **العلاقات**:
  - **One-to-One** مع `Wallet`: كل مستخدم يملك محفظة مالية واحدة.
  - **Many-to-One** مع `Country`: المستخدم ينتمي لدولة واحدة.
  - **Many-to-One** مع `City`: المستخدم ينتمي لمدينة واحدة.
  - **Many-to-One** مع `Area`: المستخدم ينتمي لمنطقة واحدة.
  - **One-to-Many** مع `Order` (كـ Customer): المستخدم يمكنه طلب عدة طلبات.
  - **One-to-Many** مع `DeliveryAssignment` (كـ Delivery): السائق يمكنه توصيل عدة طلبات (عبر الزمن).
  - **One-to-Many** مع `Restaurant` (كـ Owner): المستخدم يمكنه امتلاك عدة مطاعم.
  - **One-to-Many** مع `NotificationLog`: المستخدم لديه سجل إشعارات مرتبط به.

#### 🔑 الحقول الأساسية

- `id`: المعرف الفريد.
- `firstName`, `lastName`: الاسم الشخصي والعائلي.
- `role`: (ENUM: `UserRole`).
- `verifiedAt`: (datetime) تاريخ ووقت التحقق من الحساب (يمنع تسجيل الدخول إذا كان فارغاً).
- `isOnline`: (boolean) للسائقين فقط (تحديد الجاهزية).
- `currentLat`, `currentLng`: (float) لتتبع موقع السائق.
- `areaId`: (int) معرف المنطقة (اختياري، يرتبط بجدول `areas`).
- `area`: (relation) `Many-to-One` مع `Area` — المنطقة التي ينتمي إليها المستخدم.

### 🔔 `NotificationLog` Entity

سجل مركزي لتخزين جميع الإشعارات ورسائل الـ OTP المرسلة عبر النظام.

- **الهدف**: تتبع حالة تسليم الإشعارات، التحقق من صلاحية الـ OTP، وأرشفة الرسائل لأغراض التدقيق.
- **الحقول**:
  - `recipient`: (string) رقم الهاتف أو البريد الإلكتروني للمستلم.
  - `channel`: (ENUM: `NotificationChannel`) قناة الإرسال (`WHATSAPP`, `EMAIL`).
  - `type`: (ENUM: `NotificationType`) نوع الإشعار (`OTP`, `WELCOME`, `ORDER_UPDATE`, `ALERT`).
  - `content`: (string) محتوى الرسالة أو معرف القالب.
  - `otpCode`: (string) رمز التحقق (للمطابقة).
  - `status`: (string) حالة الإرسال (`PENDING`, `SENT`, `FAILED`).
  - `isUsed`: (boolean) هل تم استخدام الـ OTP بنجاح.
  - `expiresAt`: (datetime) وقت انتهاء صلاحية الـ OTP.
  - `usedAt`: (datetime) وقت استخدام الـ OTP.
  - `metadata`: (JSON) بيانات إضافية (مثل سبب الفشل).
- **العلاقات**:
  - **Many-to-One** مع `User`: الإشعار قد يكون مرتبطاً بمستخدم معين (اختياري).
  - **Many-to-One** مع `Order`: الإشعار قد يكون مرتبطاً بطلب معين (اختياري).

### 🍽️ `Restaurant` Entity

كيان المطعم الذي يقدم المنتجات.

- **الحقول**:
  - `name`: اسم المطعم.
  - `description`: وصف المطعم.
  - `address`: العنوان النصي.
  - `isActive`: (boolean) حالة نشاط المطعم (يمكن للتاجر إيقافه مؤقتاً).
  - `isApproved`: (boolean) حالة موافقة الإدارة (يجب أن يكون true ليظهر للعملاء).
  - `lat`, `lng`: إحداثيات الموقع الجغرافي.
  - `isExternal`: (boolean) هل المطعم يدار بواسطة نظام خارجي (API Integration).
  - `commissionRate`: (float) نسبة مئوية تستخدم كعمولة (خصم) للمطاعم الداخلية، أو كزيادة (Markup) للمطاعم الخارجية.
  - `externalProvider`: (ENUM) اسم المزود الخارجي (مثل `UBER_EATS`) في حال كان المطعم خارجياً.
- **العلاقات**:
  - **Many-to-One** مع `User` (Owner): المطعم يتبع لتاجر (Merchant) واحد.
  - **Many-to-One** مع `City`: المطعم يقع في مدينة واحدة.
  - **One-to-Many** مع `Product`: المطعم يقدم عدة منتجات.
  - **One-to-Many** مع `Order`: المطعم يتلقى عدة طلبات.
  - **One-to-Many** مع `Category`: المطعم لديه عدة أقسام منيو (Menu Categories).
  - **Many-to-Many** مع `Category`: المطعم يتبع لعدة تصنيفات مطبخ (Cuisines).

### 🍔 `Product` Entity

كيان المنتجات (الوجبات) التي يقدمها المطعم.

- **الحقول**:
  - `name`: اسم المنتج.
  - `description`: وصف المنتج.
  - `price`: السعر (بأصغر وحدة عملة).
  - `imageUrl`: رابط صورة المنتج.
  - `isAvailable`: (boolean) هل المنتج متاح حالياً للطلب.
- **العلاقات**:
  - **Many-to-One** مع `Restaurant`: المنتج يتبع لمطعم واحد (Cascade Delete مفعل).
  - **Many-to-One** مع `Category`: المنتج ينتمي لقسم منيو واحد (Menu Category).

### 🏷️ `Category` Entity

كيان التصنيفات الذي يدعم نوعين من التصنيفات: مطابخ (Cuisines) وأقسام منيو (Menu Sections).

- **الحقول**:
  - `name`: (JSON) اسم التصنيف (عربي/إنجليزي).
  - `type`: (ENUM: `CategoryType`) نوع التصنيف (`CUISINE` أو `MENU`).
  - `imageUrl`: صورة التصنيف.
  - `displayOrder`: ترتيب العرض.
  - `isActive`: حالة التفعيل.
- **العلاقات**:
  - **Many-to-Many** مع `Restaurant` (إذا كان النوع `CUISINE`): المطاعم التي تندرج تحت هذا المطبخ.
  - **Many-to-One** مع `Restaurant` (إذا كان النوع `MENU`): المطعم الذي يملك هذا القسم.
  - **One-to-Many** مع `Product`: المنتجات المدرجة تحت هذا القسم.

### 🌍 `Country` Entity

جدول الدول المدعومة في النظام.

### 🏙️ `City` Entity

جدول المدن المدعومة، ويرتبط بالدولة.

- **الحقول**:
  - `name`: (JSON) الاسم باللغتين العربية والإنجليزية.
  - `countryId`: معرف الدولة التابعة لها.

---

## 2️⃣ الطلبات والتوصيل (Orders & Delivery)

### 📦 `Order` Entity

الجدول الأساسي للمعاملات التجارية.

- **الحقول**:
  - `totalAmount`, `deliveryFee`, `discountAmount`: القيم المالية بأصغر وحدة.
  - `status`: حالة الطلب (ENUM: `OrderStatus`).
  - `paymentMethod`: طريقة الدفع.
  - `deliveryDeadline`: وقت التسليم المتوقع.
  - `couponCode`: كود الخصم المستخدم (إن وجد).
  - `restaurantRevenue`: (integer) حصة المطعم من قيمة الطلب (بعد خصم العمولة أو السعر الأساسي).
  - `platformCommission`: (integer) حصة المنصة (الربح) من الطلب.
- **العلاقات**:
  - **Many-to-One** مع `User` (Customer).
  - **Many-to-One** مع `Restaurant`.
  - **One-to-Many** مع `OrderItem`.
  - **One-to-One** مع `DeliveryAssignment`.
  - **One-to-One** مع `PaymentTransaction`.
  - **One-to-Many** مع `Invoice`: كل طلب له فاتورتان عادةً (للعميل وللمطعم).

### 🧾 `Invoice` Entity

سجل مالي يوثق المستحقات لكل طرف في عملية الطلب، ويدعم النموذج المختلط (Hybrid Model).

- **الهدف**: توثيق ما يدفعه العميل (Receivable) وما يجب دفعه للمطعم (Payable) بشكل منفصل.
- **الحقول**:
  - `orderId`: رقم الطلب.
  - `type`: (ENUM: `CUSTOMER`, `VENDOR`) نوع الفاتورة.
  - `amount`: المبلغ المستحق.
  - `status`: حالة السداد (`PENDING`, `PAID`, `CANCELLED`).
  - `breakdown`: (JSON) تفاصيل مالية دقيقة (السعر الأصلي، نسبة الزيادة/الخصم، الصافي).
- **العلاقات**:
  - **Many-to-One** مع `Order`.

### 🛒 `OrderItem` Entity

تفاصيل كل منتج داخل الطلب.

- **الحقول**:
  - `quantity`: الكمية.
  - `price`: سعر الوحدة وقت الطلب (لتثبيت السعر حتى لو تغير لاحقاً).
  - `options`: (JSON) خيارات إضافية (مثل: بدون بصل، زيادة جبن).

### 🛵 `DeliveryAssignment` Entity

جدول لإدارة عملية تعيين السائقين للطلبات.

- **الحقول**:
  - `status`: حالة التوصيل (`ASSIGNED`, `PICKED`, `DELIVERED`).
  - `assignedAt`, `acceptedAt`, `pickedAt`, `deliveredAt`: توقيتات المراحل المختلفة.
- **العلاقات**:
  - **One-to-One** مع `Order`.
  - **Many-to-One** مع `User` (Delivery Driver).

---

## 3️⃣ المدفوعات والمحفظة (Payments & Wallet)

### 💳 `PaymentTransaction` Entity

سجل لجميع عمليات الدفع الإلكتروني أو النقدي المرتبطة بالطلبات.

- **الحقول**:
  - `amount`: المبلغ.
  - `provider`: مزود الخدمة (`STRIPE`, `SYRIATEL_CASH`).
  - `status`: حالة الدفع (`PENDING`, `SUCCESS`, `FAILED`).
  - `metadata`: بيانات إضافية من بوابة الدفع.

### 💰 `Wallet` Entity

المحفظة الرقمية لكل مستخدم.

- **الحقول**:
  - `balance`: الرصيد الحالي.
  - `currency`: العملة.

### 💸 `WalletTransaction` Entity

سجل حركات المحفظة (إيداع/سحب).

- **الحقول**:
  - `amount`: المبلغ.
  - `type`: (`CREDIT`, `DEBIT`).
  - `referenceType`: سبب الحركة (طلب، استرداد، شحن رصيد).

---

## 4️⃣ التدقيق والأمان (Audit & Security)

### 🛡️ `AuditLog` Entity

سجل تتبع التغييرات الحساسة في النظام.

- **الحقول**:
  - `action`: نوع العملية (`CREATE`, `UPDATE`, `DELETE`).
  - `entityName`, `entityId`: الكيان المتأثر.
  - `oldData`, `newData`: (JSON) لقطة للبيانات قبل وبعد التعديل.
  - `ipAddress`, `userAgent`: معلومات عن الجهاز والموقع.

---

## 5️⃣ التسويق والعروض (Marketing)

### 🎟️ `Coupon` Entity

نظام الكوبونات (رموز الخصم) التي يدخلها المستخدم يدوياً للحصول على تخفيض.

- **المبدأ**: الكوبون مرتبط برمز فريد، وله صلاحية زمنية وقيود استخدام.
- **الحقول**:
  - `code`: (string) الرمز النصي للكوبون (Unique).
  - `type`: (ENUM: `PERCENTAGE`, `FIXED`) نوع الخصم.
  - `value`: (integer) قيمة الخصم (نسبة مئوية أو مبلغ ثابت بأصغر وحدة).
  - `maxDiscountAmount`: (integer) الحد الأقصى للخصم (للكوبونات النسبية).
  - `usageLimit`: (integer) الحد الأقصى لاستخدام الكوبون (Global Limit).
  - `usedCount`: (integer) عدد مرات الاستخدام الحالية.
  - `expiresAt`: (timestamp) تاريخ انتهاء الصلاحية.
  - `isActive`: (boolean) لتفعيل/تعطيل الكوبون يدوياً.
- **العلاقات**:
  - **One-to-Many** مع `CouponUsage`: لتتبع سجل استخدام الكوبون لكل مستخدم وطلب.

### 📜 `CouponUsage` Entity

جدول وسيط لتتبع استخدام الكوبونات ومنع التكرار (Single Use Per User Logic).

- **الحقول**:
  - `couponId`: معرف الكوبون المستخدم.
  - `userId`: معرف المستخدم الذي استخدم الكوبون.
  - `orderId`: معرف الطلب الذي تم تطبيق الكوبون عليه.
  - `usedAt`: تاريخ ووقت الاستخدام.

### 💸 `Discount` Entity

نظام الخصومات التلقائية (Automatic Discounts) التي تطبق بدون تدخل المستخدم بناءً على شروط معينة.

- **المبدأ**: تطبيق الخصم الأكثر فائدة للمستخدم أو الأكثر تحديداً (Product > Restaurant > Global).
- **الحقول**:
  - `type`, `value`: نوع وقيمة الخصم.
  - `restaurantId`: (optional) إذا كان الخصم خاصاً بمطعم معين.
  - `productId`: (optional) إذا كان الخصم خاصاً بمنتج معين.
  - `cityId`: (optional) إذا كان الخصم خاصاً بمدينة معينة.
  - `firstOrderOnly`: (boolean) خصم خاص للطلب الأول فقط.
  - `expiresAt`, `isActive`: التحكم في صلاحية الخصم.
- **منطق التطبيق**:
  - يتم البحث عن جميع الخصومات المطبقة (مطعم، منتج، مدينة).
  - يتم اختيار الخصم الأكثر توفيراً (Best Value) وعدم الجمع بين الخصومات (No Stacking) في المرحلة الحالية لتبسيط الحسابات.
