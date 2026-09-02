# دليل التعديلات الأخيرة - دليل الربط مع الواجهة الأمامية (Frontend)

تاريخ التحديث: 2026-06-08

---

## 1. التغيير في إنشاء الطلب (Create Order)

### الحقل الجديد `areaId`

- **الوصف**: حقل إجباري (`@IsNumber`, `@IsNotEmpty`, `@Min(1)`) يجب إرساله عند إنشاء الطلب
- **السبب**: يستخدم لحساب رسوم التوصيل (`deliveryFee`) بناءً على `Area.price`

### واجب الـ Frontend

- إضافة قائمة منسدلة (dropdown) لاختيار المنطقة (Area) في صفحة إنشاء الطلب
- جلب المناطق المتاحة من `GET /areas`
- إرسال `areaId` ضمن request body

### شكل الـ Request Body الجديد

```json
{
    "ownerId": 30114,
    "areaId": 1,
    "items": [
        { "productId": 5111, "quantity": 2 }
    ],
    "deliveryCoordinates": {
        "latitude": 33.5138,
        "longitude": 36.2765,
        "address": "123 Customer Street"
    },
    "paymentMethod": "CASH"
}
```

---

## 2. شكل الـ Response الجديد للـ Order

### الحقول الجديدة في الاستجابة

| الحقل | النوع | الوصف |
|:---|---:|:---|
| `areaId` | number | معرف المنطقة المختارة (جديد) |
| `area` | object | كائن المنطقة كامل: `{ id, name, price, description }` (جديد) |
| `deliveryFee` | number | رسوم التوصيل المحسوبة من `Area.price` (موجود سابقاً لكن الآن له قيمة فعلية) |
| `customerName` | string | اسم الزبون (جديد) |
| `phone` | string | رقم هاتف الزبون (جديد) |
| `originalUnitPrice` | number | السعر الأصلي للوحدة قبل الخصم (داخل items) (جديد) |
| `itemsTotal` | number | مجموع أسعار المنتجات (جديد) |
| `offersTotal` | number | مجموع أسعار العروض (جديد) |
| `subtotal` | number | المجموع الفرعي (itemsTotal + offersTotal) (جديد) |
| `productDiscount` | number | إجمالي خصم المنتجات (جديد) |
| `offerDiscount` | number | إجمالي خصم العروض (جديد) |
| `deliveryId` | number | معرف المندوب المسند (جديد) |
| `delivery` | object | بيانات المندوب (جديد) |
| `mealPreparationTime` | number | وقت التحضير بالدقائق (جديد) |
| `deliveryTime` | number | وقت التوصيل بالدقائق (جديد) |

### مثال Response (Create Order)

```json
{
    "statusCode": 201,
    "message": "Operation successful",
    "data": {
        "order": {
            "id": 125,
            "customerId": 52,
            "ownerId": 30114,
            "areaId": 1,
            "area": {
                "id": 1,
                "name": "المزة",
                "price": 3000,
                "description": "منطقة المزة - دمشق"
            },
            "customerName": "أحمد محمد",
            "phone": "+963912345678",
            "status": "PENDING",
            "deliveryDeadline": "2026-03-24T12:00:00.000Z",
            "deliveryFee": 5000,
            "items": [
                {
                    "id": 1,
                    "productId": 5111,
                    "productName": "برغر",
                    "quantity": 2,
                    "originalUnitPrice": 100,
                    "unitPrice": 90,
                    "totalPrice": 180,
                    "discount": 20
                }
            ],
            "itemsTotal": 200,
            "offersTotal": 0,
            "subtotal": 200,
            "priceBeforeDiscount": 210,
            "productDiscount": 20,
            "offerDiscount": 0,
            "totalAmount": 200,
            "totalCommissionAmount": 0,
            "platformCommission": 0,
            "ownerRevenue": 190,
            "currencyCode": "SAR",
            "deliveryId": null,
            "delivery": null,
            "mealPreparationTime": null,
            "deliveryTime": null
        }
    }
}
```

---

## 3. حساب رسوم التوصيل (Delivery Fee)

| العنصر | قبل التعديل | بعد التعديل |
|:---|---:|:---|
| **آلية الحساب** | المسافة (Haversine) × `tipPerKilometer` | قيمة ثابتة من `Area.price` |
| **Google Directions API** | كان يُستخدم لحساب المسافة | لم نعد نستخدمه لرسوم التوصيل |
| **المصدر** | `tipPerKilometer` من system_settings | `Area.price` من جدول المناطق |
| **الوحدة** | أصغر وحدة عملة (هللة/قرش) | أصغر وحدة عملة (هللة/قرش) |

> **ملاحظة**: لم نعد نستخدم Google Directions API لحساب رسوم التوصيل عند إنشاء الطلب. رسوم التوصيل الآن تعتمد كلياً على المنطقة المختارة.

---

## 4. حساب عمولة المنصة (Platform Commission)

لم تتغير آلية الحساب:

```
platformCommission = deliveryFee × (deliveryCommissionRate / 100)
```

- `deliveryCommissionRate` مأخوذة من جدول `system_settings`
- **لا تغيير على الـ Frontend** — تحسب تلقائياً في الـ Backend

---

## 5. مراحل الطلب (Order Flow)

**لم تتغير** سوى مرحلة إنشاء الطلب حيث أصبح `areaId` مطلوباً:

```
إنشاء الطلب (areaId مطلوب)
    ↓
PENDING
    ↓ (يتأكد merchant)
CONFIRMED → SEARCHING → ASSIGNED → READY_FOR_PICKUP → PICKED_UP → ON_THE_WAY → DELIVERED
    ↓                            ↓
REJECTED                    CANCELLED
```

---

## 6. تغيير تسجيل المطعم (Merchant Registration)

### 6.1 التسجيل (Register)

- `isActive = false` (مثل سائق التوصيل — لم يعد `true` كما كان سابقاً)
- الرد بعد التسجيل — رسالة عربية:

```json
{
    "message": "تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى البريد الإلكتروني.",
    "data": {
        "message": "تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى البريد الإلكتروني."
    }
}
```

### 6.2 التحقق (OTP Verify)

- **الـ Response**: `202 Accepted` (بدلاً من `200 OK`)
- **لا يتم إرجاع JWT token** — لا يمكن للتاجر تسجيل الدخول بعد

```json
{
    "statusCode": 202,
    "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
    "data": {
        "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
        "userId": 27
    }
}
```

### 6.3 تسجيل الدخول (Login)

#### تغيير الحقول — استخدام `email` أو `phone` بشكل منفصل

تم استبدال الحقل `identifier` بحقلين منفصلين: **email** و **phone**. يجب تقديم أحدهما على الأقل.

**تسجيل الدخول بالبريد الإلكتروني:**
```json
{
    "email": "merchant@example.com",
    "password": "password123"
}
```

**تسجيل الدخول برقم الهاتف:**
```json
{
    "phone": "+963912345678",
    "password": "password123"
}
```

#### رسالة الخطأ عند بيانات غير صحيحة

```json
{
    "message": "Invalid email/phone or password",
    "error": "INVALID_CREDENTIALS",
    "code": 1002
}
```

#### إذا كان الحساب غير مفعل (`isActive = false`):

```json
{
    "message": "حسابك قيد المراجعة من قبل المدير. يرجى التواصل مع الإدارة لتفعيل حسابك.",
    "error": "ACCOUNT_PENDING",
    "code": 1006
}
```

#### Response (Success) — جميع الأدوار الآن تتضمن حقولاً جديدة

جميع الـ Responses تتضمن الآن الحقول التالية بالإضافة للحقول السابقة:

| الحقل | النوع | الوصف |
|:---|---:|:---|
| `firebaseToken` | string or null | توكن Firebase (جديد) |
| `isActive` | boolean | حالة الحساب (جديد — يحل محل `merchantIsActive` للتاجر) |
| `lastLoginAt` | string (ISO) or null | آخر وقت تسجيل دخول (جديد) |
| `lastLoginIp` | string or null | آخر IP تسجيل دخول (جديد) |

**Customer Response:**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 12,
        "firstName": "John",
        "lastName": "Doe",
        "email": "customer@example.com",
        "phone": "+963912345678",
        "role": "CUSTOMER",
        "notificationChannel": "EMAIL",
        "firebaseToken": null,
        "countryId": 1,
        "country": { ... },
        "cityId": 1,
        "city": { ... },
        "areaId": null,
        "area": null,
        "address": "123 Street",
        "isOnline": false,
        "isActive": true,
        "verifiedAt": "2026-03-08T16:33:56.616Z",
        "location": null,
        "lastLoginAt": "2026-06-08T10:00:00.000Z",
        "lastLoginIp": "192.168.1.100"
    }
}
```

**Merchant Response** — ملاحظات خاصة:
- `isActive` يحل محل `merchantIsActive` (القديم)
- `type` أزيل من الـ Response
- `hidePhoneNumber` و `merchantId` حقول جديدة

```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 27,
        "firstName": "John",
        "lastName": "Doe",
        "email": "merchant@example.com",
        "phone": "+963912345678",
        "role": "MERCHANT",
        "notificationChannel": "EMAIL",
        "firebaseToken": null,
        "countryId": 1,
        "country": { ... },
        "cityId": 1,
        "city": { ... },
        "areaId": null,
        "area": null,
        "address": "Restaurant Street",
        "isOnline": false,
        "isActive": true,
        "verifiedAt": "2026-03-10T13:55:59.554Z",
        "lastLoginAt": "2026-06-08T10:00:00.000Z",
        "lastLoginIp": "192.168.1.100",
        "merchantId": 5,
        "restaurantName": "Tasty Burger",
        "isOpen": true,
        "hidePhoneNumber": false,
        "estimatedDeliveryMinutes": 30
    }
}
```

**Delivery Response** — ملاحظات خاصة:
- `country` و `city` objects كاملة (جديد)
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 35,
        "firstName": "Khalid",
        "lastName": "Ali",
        "email": "driver@example.com",
        "phone": "+963912345678",
        "role": "DELIVERY",
        "notificationChannel": "EMAIL",
        "firebaseToken": null,
        "countryId": 1,
        "country": {
            "id": 1,
            "name": "Syria",
            "code": "SY"
        },
        "cityId": 1,
        "city": {
            "id": 1,
            "name": "Damascus"
        },
        "areaId": null,
        "area": null,
        "address": "Delivery Street",
        "isOnline": true,
        "isActive": true,
        "verifiedAt": "2026-06-07T10:00:00.000Z",
        "lastLoginAt": "2026-06-08T10:00:00.000Z",
        "lastLoginIp": "192.168.1.100"
    }
}
```

### 6.4 واجب الـ Frontend

- **صفحة التسجيل**: لا تغيير — فقط أظهر الرسالة العربية كما هي
- **صفحة التحقق (OTP)**: 
  - إذا كان الرد `202` والرسالة "قيد المراجعة" → اعرض رسالة للمستخدم بأن الحساب قيد المراجعة ولا يمكن الدخول حالياً
  - لا تحاول حفظ JWT token
- **صفحة تسجيل الدخول**: 
  - **تغيير الحقول**: استخدام حقل `email` (Validation: Email) أو `phone` (Validation: string) — أرسل أحدهما فقط حسب نوع الإدخال
  - **التعرف على نوع الإدخال**: إذا كان المدخل يحتوي على `@` → استخدم حقل `email`، وإلا → استخدم حقل `phone`
  - **التعامل مع الخطأ الجديد**: `"Invalid email/phone or password"` → اعرض للمستخدم "الإيميل/الهاتف أو كلمة المرور غير صحيحة"
  - إذا ظهر الخطأ `401` برسالة "حسابك قيد المراجعة من قبل المدير" → اعرض هذه الرسالة للمستخدم
  - **تحديث واجهة TypeScript/Type**:
    - استبدال `LoginPayload.identifier` بـ `LoginPayload.email | LoginPayload.phone` (يجب تقديم أحدهما)
    - إضافة الحقول الجديدة للـ Response: `firebaseToken`, `isActive`, `lastLoginAt`, `lastLoginIp`
    - للتاجر: استخدام `isActive` بدلاً من `merchantIsActive`
    - للمندوب: `country` و `city` objects

---

## 7. تفعيل حساب التاجر (Confirm Merchant)

### الـ Endpoint الجديد

| العنصر | القيمة |
|:---|---:|
| **Method** | `PATCH` |
| **URL** | `/users/merchants/:id/confirm` |
| **الصلاحية** | ADMIN فقط |
| **الـ Body** | لا يحتوي Body |

### ماذا يفعل؟

1. يضبط `isActive = true` لحساب التاجر
2. يرسل إشعار Firebase للتاجر بعنوان "تفعيل الحساب"
3. محتوى الإشعار: "تم تفعيل حساب مطعمك بنجاح. يمكنك الآن تسجيل الدخول وإدارة طلباتك."

### مثال Response

```json
{
    "statusCode": 200,
    "message": "تم تفعيل حساب التاجر بنجاح",
    "data": {
        "id": 27,
        "firstName": "John",
        "lastName": "Doe",
        "email": "merchant@example.com",
        "phone": "+963912345678",
        "role": "MERCHANT",
        "isActive": true,
        "restaurantName": "Tasty Burger Restaurant"
    }
}
```

### Errors المحتملة

| الحالة | الـ Response |
|:---|---:|
| التاجر غير موجود (404) | `{ "message": "Merchant not found", "code": "MERCHANT_NOT_FOUND" }` |
| المستخدم ليس ADMIN (403) | `{ "message": "Forbidden resource" }` |

> **ملاحظة**: لا يوجد خطأ "already active" — الـ endpoint يعيد التفعيل دون مشكلة حتى لو كان الحساب مفعلاً مسبقاً.

### واجب الـ Frontend (Admin Panel)

- إضافة زر "Confirm Merchant / تفعيل التاجر" في صفحة إدارة التجار
- الزر يظهر فقط للتجار الذين `merchantIsActive = false`
- بعد النقر، إرسال `PATCH /users/merchants/{id}/confirm`
- إظهار رسالة نجاح "تم تفعيل حساب التاجر بنجاح"
- إعادة تحميل قائمة التجار لتحديث الحالة

---

## 8. تفعيل حساب السائق (Delivery Activation)

**موجود مسبقاً** — فقط للتذكير:

| العنصر | القيمة |
|:---|---:|
| **Method** | `PATCH` |
| **URL** | `/users/deliveries/:id` |
| **الـ Body** | `{ "isActive": true }` |

نفس الآلية:
- السائقون يسجلون بـ `isActive = false`
- يحتاجون تفعيل من ADMIN
- بعد التفعيل، يمكنهم تسجيل الدخول

---

## 9. ملخص الحقول الجديدة والمعدلة في الـ API

| الحقل | مكان الظهور | النوع | مطلوب؟ | ملاحظة |
|:---|---:|:---:|:---:|:---|
| `areaId` | Request (Create Order) | number | ✅ إجباري | يجب إرساله عند إنشاء الطلب |
| `areaId` | Response (Order) | number | — | يظهر في جميع استجابات الطلب |
| `area` | Response (Order) | object | — | كائن المنطقة كامل: `{ id, name, price, description }` (جديد) |
| `deliveryFee` | Response (Order) | number | — | محسوب من `Area.price` (قيمة فعلية الآن) |
| `customerName` | Response (Order) | string | — | اسم الزبون (جديد) |
| `phone` | Response (Order) | string | — | رقم هاتف الزبون (جديد) |
| `originalUnitPrice` | Response (Order/items) | number | — | السعر الأصلي قبل الخصم (جديد) |
| `itemsTotal` | Response (Order) | number | — | مجموع المنتجات (جديد) |
| `offersTotal` | Response (Order) | number | — | مجموع العروض (جديد) |
| `subtotal` | Response (Order) | number | — | المجموع الفرعي (جديد) |
| `productDiscount` | Response (Order) | number | — | خصم المنتجات (جديد) |
| `offerDiscount` | Response (Order) | number | — | خصم العروض (جديد) |
| `deliveryId` | Response (Order) | number | — | معرف المندوب (جديد) |
| `delivery` | Response (Order) | object | — | بيانات المندوب (جديد) |
| `mealPreparationTime` | Response (Order) | number | — | وقت التحضير (جديد) |
| `deliveryTime` | Response (Order) | number | — | وقت التوصيل (جديد) |
| `email` أو `phone` | Request (Login) | string | ✅ إجباري (أحدهما) | **يحل محل** `identifier` — `email` للإيميل، `phone` للهاتف |
| `firebaseToken` | Response (Login) | string | — | توكن Firebase (جديد لكل الأدوار) |
| `isActive` | Response (Login) | boolean | — | `false` بعد التسجيل، `true` بعد التفعيل (يحل محل `merchantIsActive`) |
| `lastLoginAt` | Response (Login) | string | — | آخر وقت تسجيل دخول (جديد) |
| `lastLoginIp` | Response (Login) | string | — | آخر IP تسجيل دخول (جديد) |
| `hidePhoneNumber` | Response (Login/Merchant) | boolean | — | إخفاء رقم الهاتف (جديد) |
| `merchantId` | Response (Login/Merchant) | number | — | معرف المطعم (جديد) |
| `country` | Response (Login/Delivery) | object | — | معلومات الدولة (جديد للمندوب) |
| `city` | Response (Login/Delivery) | object | — | معلومات المدينة (جديد للمندوب) |

---

## 10. ملاحظات إضافية للـ Frontend

1. **لا توجد تغييرات** على صفحات المستخدم (Customer) سوى إضافة اختيار المنطقة عند إنشاء الطلب
2. **صفحة السائق (Delivery)**: تحديث طفيف — Response تسجيل الدخول أصبح يتضمن `country` و `city` objects كاملة
3. **التغيير الأكبر** هو في تدفق تسجيل المطعم — أصبح مثل تدفق سائق التوصيل تماماً
4. **Admin Panel**: تمت إضافة endpoint جديد `Confirm Merchant` لتأكيد تفعيل التجار
5. Firebase notification سترسل إلى التاجر عند التفعيل — تأكد من معالجة الـ notification type `MERCHANT_ACCOUNT_STATUS`
6. **تسجيل الدخول**: استخدام `email` أو `phone` بدلاً من `identifier` — أرسل أحدهما بناءً على نوع الإدخال (بريد إلكتروني أو رقم هاتف)
7. **تحديث Types/Interfaces**: 
   - إضافة `firebaseToken`, `isActive`, `lastLoginAt`, `lastLoginIp` لجميع Login Responses
   - للتاجر: استخدام `isActive` بدلاً من `merchantIsActive`، إضافة `hidePhoneNumber`, `merchantId`
   - للمندوب: إضافة `country` و `city` objects
   - للطلب (Order): إضافة `customerName`, `phone`, `itemsTotal`, `offersTotal`, `subtotal`, `productDiscount`, `offerDiscount`, `deliveryId`, `delivery`, `mealPreparationTime`, `deliveryTime`, `area` (كائن كامل: `{ id, name, price, description }`)

---

## 11. Areas API — إدارة المناطق (جديد)

### 11.1 نظرة عامة

الـ **Areas** هي مناطق التوصيل (Delivery Zones). كل منطقة تحدد سعر توصيل ثابت (`price`) يُستخدم الآن لحساب `deliveryFee` عند إنشاء الطلب.

**الحقول:**

| الحقل | النوع | الوصف |
|:---|---:|:---|
| `id` | number | معرف المنطقة |
| `name` | string | اسم المنطقة (مثل "Downtown") |
| `price` | string | سعر التوصيل بصيغة `"5000.00"` (decimal) |
| `description` | string or null | وصف المنطقة (اختياري) |
| `createdAt` | string (ISO) | تاريخ الإنشاء |
| `updatedAt` | string (ISO) | تاريخ آخر تحديث |

**لماذا يحتاجها الـ Frontend؟**

- **صفحة إنشاء الطلب**: يجب جلب كل المناطق عبر `GET /areas` لملء dropdown اختيار `areaId`
- **Admin Panel**: إدارة المناطق (إضافة، تعديل، حذف) — ضرورية لضبط أسعار التوصيل

**هيكل Pagination الموحد:**

```json
{
    "total": 25,
    "page": 1,
    "limit": 10,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPreviousPage": false
}
```

| الحقل | النوع | الوصف |
|:---|---:|:---|
| `total` | number | إجمالي عدد السجلات |
| `page` | number | رقم الصفحة الحالية |
| `limit` | number | عدد السجلات في الصفحة |
| `totalPages` | number | إجمالي عدد الصفحات |
| `hasNextPage` | boolean | هل توجد صفحة تالية؟ |
| `hasPreviousPage` | boolean | هل توجد صفحة سابقة؟ |

---

### 11.2 جلب كل المناطق — `GET /areas`

- **الاستخدام الرئيسي**: ملء dropdown اختيار المنطقة عند إنشاء الطلب
- **Method**: `GET`
- **URL**: `/areas`
- **Headers**: `Authorization: Bearer <token>`
- **الصلاحية**: أي مستخدم مسجل دخول
- **الترتيب**: حسب `createdAt` تنازلياً (الأحدث أولاً)

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `page` | number | No | 1 | رقم الصفحة |
| `limit` | number | No | 10 | عدد العناصر في الصفحة |
| `search` | string | No | — | بحث في `name` + `price` + `description` (غير حساس لحالة الأحرف) |
| `min_price` | number | No | — | فلتر الحد الأدنى للسعر (>= 0) |
| `max_price` | number | No | — | فلتر الحد الأعلى للسعر (>= 0) |

#### أمثلة URLs

| الغرض | الـ URL |
|---|---|
| جلب كل المناطق (الصفحة 1) | `/areas` |
| الصفحة 2، 5 عناصر | `/areas?page=2&limit=5` |
| بحث باسم "downtown" | `/areas?search=downtown` |
| فلتر سعر 1000 إلى 10000 | `/areas?min_price=1000&max_price=10000` |
| الكل معاً | `/areas?page=1&limit=10&search=downtown&min_price=1000&max_price=10000` |

#### Response (Success — 200 OK)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [
        {
            "id": 1,
            "name": "Downtown",
            "price": "5000.00",
            "description": "Central business district delivery zone",
            "createdAt": "2026-03-10T12:00:00.000Z",
            "updatedAt": "2026-03-10T12:00:00.000Z"
        },
        {
            "id": 2,
            "name": "Uptown",
            "price": "8000.00",
            "description": "Upper district delivery zone",
            "createdAt": "2026-03-10T12:05:00.000Z",
            "updatedAt": "2026-03-10T12:05:00.000Z"
        }
    ],
    "pagination": {
        "total": 2,
        "page": 1,
        "limit": 10,
        "totalPages": 1,
        "hasNextPage": false,
        "hasPreviousPage": false
    },
    "timestamp": "2026-03-10T12:00:00.000Z",
    "path": "/api/v1/areas"
}
```

#### Response (Error — 400 Bad Request)

عند إرسال `min_price` أكبر من `max_price`:

```json
{
    "statusCode": 400,
    "message": "min_price must be less than or equal to max_price",
    "data": {},
    "timestamp": "2026-03-10T12:00:00.000Z",
    "path": "/api/v1/areas"
}
```

#### Response (Error — 401 Unauthorized)

عند عدم إرسال التوكن أو انتهاء صلاحيته:

```json
{
    "statusCode": 401,
    "message": "Unauthorized",
    "data": {},
    "timestamp": "2026-03-10T12:00:00.000Z",
    "path": "/api/v1/areas"
}
```

#### واجب الـ Frontend

- جلب المناطق عند تحميل صفحة **إنشاء الطلب** لتعبئة dropdown اختيار `areaId`
- يُفضل تخزين القائمة مؤقتاً (caching) لأنها نادراً ما تتغير
- إظهار `name` للمستخدم، وإرسال `id` كـ `areaId` في Request Create Order

---

### 11.3 جلب منطقة واحدة — `GET /areas/:id`

- **Method**: `GET`
- **URL**: `/areas/{id}`
- **Headers**: `Authorization: Bearer <token>`
- **الصلاحية**: أي مستخدم مسجل دخول

#### Response (Success — 200 OK)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": {
        "id": 1,
        "name": "Downtown",
        "price": "5000.00",
        "description": "Central business district delivery zone",
        "createdAt": "2026-03-10T12:00:00.000Z",
        "updatedAt": "2026-03-10T12:00:00.000Z"
    },
    "timestamp": "2026-03-10T12:00:00.000Z",
    "path": "/api/v1/areas/1"
}
```

#### Response (Error — 404 Not Found)

```json
{
    "statusCode": 404,
    "message": "Area with ID 999 not found",
    "data": {},
    "timestamp": "2026-03-10T12:00:00.000Z",
    "path": "/api/v1/areas/999"
}
```

---

### 11.4 إنشاء منطقة جديدة — `POST /areas` (Admin Only)

- **الاستخدام**: Admin Panel — إضافة منطقة توصيل جديدة
- **Method**: `POST`
- **URL**: `/areas`
- **Headers**:
  - `Content-Type: application/json`
  - `Authorization: Bearer <admin_token>`
- **الصلاحية**: ADMIN فقط

#### Request Body

| Key | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✅ | اسم المنطقة (غير فارغ) |
| `price` | number | ✅ | سعر التوصيل (>= 0، بأصغر وحدة عملة) |
| `description` | string | ❌ | وصف المنطقة |

```json
{
    "name": "New District",
    "price": 7500,
    "description": "New residential area delivery zone"
}
```

#### Response (Success — 201 Created)

```json
{
    "statusCode": 201,
    "message": "Operation successful",
    "data": {
        "id": 3,
        "name": "New District",
        "price": "7500.00",
        "description": "New residential area delivery zone",
        "createdAt": "2026-06-07T10:00:00.000Z",
        "updatedAt": "2026-06-07T10:00:00.000Z"
    },
    "timestamp": "2026-06-07T10:00:00.000Z",
    "path": "/api/v1/areas"
}
```

#### Response (Error — 403 Forbidden)

عند محاولة مستخدم غير ADMIN:

```json
{
    "statusCode": 403,
    "message": "Only Admins can create areas",
    "data": {},
    "timestamp": "2026-06-07T10:00:00.000Z",
    "path": "/api/v1/areas"
}
```

---

### 11.5 تحديث منطقة — `PATCH /areas/:id` (Admin Only)

- **الاستخدام**: Admin Panel — تعديل بيانات منطقة موجودة
- **Method**: `PATCH`
- **URL**: `/areas/{id}`
- **Headers**:
  - `Content-Type: application/json`
  - `Authorization: Bearer <admin_token>`
- **الصلاحية**: ADMIN فقط
- **ملاحظة**: جميع الحقول اختيارية (جزئي — PATCH)

#### Request Body

| Key | Type | Required | Description |
|---|---|---|---|
| `name` | string | ❌ | الاسم الجديد |
| `price` | number | ❌ | السعر الجديد (>= 0) |
| `description` | string | ❌ | الوصف الجديد |

```json
{
    "name": "Updated District",
    "price": 9000
}
```

#### Response (Success — 200 OK)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": {
        "id": 3,
        "name": "Updated District",
        "price": "9000.00",
        "description": "New residential area delivery zone",
        "createdAt": "2026-06-07T10:00:00.000Z",
        "updatedAt": "2026-06-07T10:30:00.000Z"
    },
    "timestamp": "2026-06-07T10:30:00.000Z",
    "path": "/api/v1/areas/3"
}
```

#### Response (Error — 403 Forbidden)

```json
{
    "statusCode": 403,
    "message": "Only Admins can update areas",
    "data": {},
    "timestamp": "2026-06-07T10:30:00.000Z",
    "path": "/api/v1/areas/3"
}
```

#### Response (Error — 404 Not Found)

```json
{
    "statusCode": 404,
    "message": "Area with ID 999 not found",
    "data": {},
    "timestamp": "2026-06-07T10:30:00.000Z",
    "path": "/api/v1/areas/999"
}
```

---

### 11.6 حذف منطقة — `DELETE /areas/:id` (Admin Only)

- **الاستخدام**: Admin Panel — حذف منطقة نهائياً
- **Method**: `DELETE`
- **URL**: `/areas/{id}`
- **Headers**: `Authorization: Bearer <admin_token>`
- **الصلاحية**: ADMIN فقط
- **تحذير**: لا يوجد `ON DELETE CASCADE` — لا يمكن حذف منطقة مرتبطة بأي طلب موجود

#### Response (Success — 200 OK)

```json
{
    "statusCode": 200,
    "message": "Area deleted successfully",
    "data": {},
    "timestamp": "2026-06-07T11:00:00.000Z",
    "path": "/api/v1/areas/3"
}
```

#### Response (Error — 403 Forbidden)

```json
{
    "statusCode": 403,
    "message": "Only Admins can delete areas",
    "data": {},
    "timestamp": "2026-06-07T11:00:00.000Z",
    "path": "/api/v1/areas/3"
}
```

#### Response (Error — 404 Not Found)

```json
{
    "statusCode": 404,
    "message": "Area with ID 999 not found",
    "data": {},
    "timestamp": "2026-06-07T11:00:00.000Z",
    "path": "/api/v1/areas/999"
}
```

---

### 11.7 نصائح للمطور Frontend

1. **تخزين مؤقت (Caching)**: المناطق لا تتغير كثيراً — يمكن حفظ القائمة في `localStorage` أو `state management` وتحديثها فقط عند دخول صفحة Admin Panel
2. **معالجة الـ price**: الـ API يُرجع `price` كـ **string** (`"5000.00"`). حولها إلى `number` قبل استخدامها في الحسابات: `Number(area.price)`
3. **إعادة تحميل dropdown**: بعد إضافة/تعديل/حذف منطقة من Admin Panel، أعد جلب القائمة لتحديث dropdown إنشاء الطلب
4. **معالجة الخطأ 404 في Admin**: عند محاولة تعديل أو حذف منطقة محذوفة مسبقاً
5. **الفلاتر**: معاملات `min_price` و `max_price` ترسل كـ query strings — تأكد من تحويلها إلى أرقام صحيحة قبل الإرسال

---

## 12. التحقق من عدم تكرار رقم الهاتف عند التسجيل (جديد)

### 12.1 نظرة عامة

تمت إضافة التحقق من عدم تكرار **رقم الهاتف** عند تسجيل المستخدمين الجدد للأدوار **CUSTOMER** و **DELIVERY** فقط. هذا يمنع إنشاء حساب جديد برقم هاتف مستخدم مسبقاً.

| الدور | يشملة التحقق؟ |
|:---|---:|
| CUSTOMER | ✅ نعم |
| DELIVERY | ✅ نعم |
| MERCHANT | ❌ لا (له مسار تسجيل مختلف عبر ADMIN) |

### 12.2 آلية العمل

عند تقديم طلب التسجيل (`POST /auth/register`):

```
1. التحقق من البريد الإلكتروني (موجود مسبقاً)
2. التحقق من أن role = CUSTOMER أو DELIVERY
3. التحقق من رقم الهاتف ← إذا كان مستخدماً → 400 Bad Request
4. إنشاء المستخدم
```

### 12.3 شكل الخطأ (400 Bad Request)

```json
{
    "statusCode": 400,
    "message": "Phone number already registered",
    "data": {},
    "timestamp": "2026-06-07T12:00:00.000Z",
    "path": "/api/v1/auth/register"
}
```

| الحقل | القيمة |
|:---|---:|
| `statusCode` | 400 |
| `message` | `"Phone number already registered"` |
| `data` | `{}` |

### 12.4 مثال لسيناريو كامل

**Request** (محاولة تسجيل برقم هاتف موجود):

```json
{
    "email": "newuser@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER"
}
```

**Response**:

```json
{
    "statusCode": 400,
    "message": "Phone number already registered",
    "data": {},
    "timestamp": "2026-06-07T12:00:00.000Z",
    "path": "/api/v1/auth/register"
}
```

### 12.5 واجب الـ Frontend

1. **معالجة الخطأ 400**: رسالة `"Phone number already registered"` تعني أن رقم الهاتف مستخدم مسبقاً. اعرض رسالة للمستخدم "رقم الهاتف مسجل مسبقاً"
2. **التمييز عن أخطاء البريد الإلكتروني**: نفس رقم الحالة (400) لكن يمكن التفريق عبر محتوى `message`:
   - `"User with this email already exists"` ← "البريد الإلكتروني مسجل مسبقاً"
   - `"Phone number already registered"` ← "رقم الهاتف مسجل مسبقاً"
3. **تسليط الضوء على حقل الهاتف**: قم بتمييز حقل الإدخال (input) للهاتف باللون الأحمر عند ورود هذا الخطأ
4. **صفحة الدعم**: أضف نصيحة للمستخدم مثل "إذا كنت تعتقد أن هذا خطأ، يرجى التواصل مع الدعم"

---

## 13. إرسال إشعار لجميع العملاء — `POST /notifications/send-to-customers` (جديد)

### 13.1 نظرة عامة

Endpoint جديد لإرسال إشعار Firebase مباشرة لجميع العملاء (دور CUSTOMER) دون الحاجة لتحديد `topic` أو `type` — يتم تعيينهما تلقائياً (`ALL_CUSTOMERS` + `CUSTOM` + `FIREBASE`).

| العنصر | القيمة |
|:---|---:|
| **Method** | `POST` |
| **URL** | `/notifications/send-to-customers` |
| **الصلاحية** | أي مستخدم مسجل دخول (Bearer Token) |

### 13.2 Request Body

| الحقل | النوع | مطلوب | الوصف |
|:---|---:|:---:|:---|
| `title` | string | ✅ | عنوان الإشعار |
| `body` | string | ✅ | محتوى الإشعار |

```json
{
    "title": "عرض خاص للعملاء",
    "body": "خصم 15% على طلبك القادم"
}
```

### 13.3 Response (Success — 200 OK)

```json
{
    "success": true,
    "data": {
        "id": 47,
        "channel": "FIREBASE",
        "type": "CUSTOM",
        "title": "عرض خاص للعملاء",
        "body": "خصم 15% على طلبك القادم",
        "topic": "ALL_CUSTOMERS",
        "sentAt": "2024-01-15T10:30:00Z",
        "createdAt": "2024-01-15T10:29:00Z",
        "totalTargeted": 150,
        "deliveredCount": 120,
        "undeliveredCount": 30
    }
}
```

### 13.4 واجب الـ Frontend

| السيناريو | الإجراء |
|:---|---:|
| **Admin Panel** — إرسال إشعار لكل العملاء | أضف نموذج (form) بحقول `title` و `body` وزر إرسال إلى هذا الـ endpoint |
| **معالجة الخطأ** | نفس معالجة أخطاء الإشعارات الأخرى (401, 500) |
| **تحديث Types/Interfaces** | أضف `SendToCustomersPayload` بنوع `{ title: string; body: string }` |
