أولًا: كم Model سنحتاج؟

بناءً على نظامك (Delivery + Wallet + Cash + GPS + Payments):

🧱 Core Models (الأساسية جدًا)

1️⃣ User
2️⃣ Role
3️⃣ Restaurant
4️⃣ Order
5️⃣ OrderItem
6️⃣ DeliveryAssignment
7️⃣ Wallet
8️⃣ WalletTransaction
9️⃣ PaymentTransaction
🔟 Tip

User Model

يمثل:

Admin

Delivery

Customer

Design Pattern مهم هنا:

Single Table Inheritance Pattern (بشكل مبسط)

بدل إنشاء 3 جداول، نستخدم:

role: ADMIN | DELIVERY | CUSTOMER
الحقول الأساسية:
id
name
email
password
role
country
city
address
isOnline (للدليفري)
createdAt
2️⃣ Restaurant Model
id
name
ownerId
address
country
city
isActive
createdAt
3️⃣ Order Model (أهم Model في النظام)
id
customerId
restaurantId
deliveryId (nullable)
totalAmount
deliveryFee
tipAmount
paymentMethod
status
deliveryDeadline
finalLocation (JSON: lat & lng)
createdAt
🔥 Design Pattern مهم هنا:
State Pattern (بشكل مبسط عبر Enum)
PENDING
ASSIGNED
PICKED
ON_THE_WAY
DELIVERED
CANCELLED

لا تسمح بتغيير الحالة عشوائياً.
4️⃣ OrderItem Model
id
orderId
productName
quantity
price
5️⃣ DeliveryAssignment Model
id
orderId
deliveryId
assignedAt
acceptedAt
deliveredAt
status
6️⃣ Wallet Model (أخطر جزء)
id
deliveryId
balance
updatedAt
7️⃣ WalletTransaction Model

🔴 مهم جدًا محاسبيًا

id
walletId
amount
type (DEBIT | CREDIT)
reason (CASH_ORDER | REWARD | PENALTY)
orderId (nullable)
createdAt
🔥 Design Pattern هنا:
Ledger Pattern (محاسبي)

لا نعدل الرصيد مباشرة فقط، بل نسجل كل حركة في WalletTransaction.

الرصيد = مجموع الحركات.
8️⃣ PaymentTransaction Model

لل دفع أونلاين:

id
orderId
amount
provider (SYRIATEL | SHAM | PAYPAL | USDT)
status
providerReference
createdAt
9️⃣ Tip Model
id
orderId
amount
receiverType (DELIVERY | ADMIN)
🧠 الآن الصورة العامة للعلاقات
User
├── has many Orders (customer)
├── has many DeliveryAssignments (delivery)
├── has one Wallet (delivery)

Order
├── belongs to User (customer)
├── belongs to Restaurant
├── has one DeliveryAssignment
├── has many OrderItems
├── has one PaymentTransaction
├── has one Tip
🔥 أهم Design Patterns مستخدمة في النظام
Pattern أين نستخدمه
Modular Monolith هيكل المشروع
Lightweight DDD تقسيم الدومينات
State Pattern حالات الطلب
Ledger Pattern Wallet
Repository Pattern عبر TypeORM
Service Layer Pattern business logic
