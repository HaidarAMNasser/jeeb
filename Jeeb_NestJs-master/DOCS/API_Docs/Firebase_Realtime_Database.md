# Firebase Realtime Database Documentation

## نظرة عامة

نظام Firebase Realtime Database (RTDB) يستخدم لتتبع الطلبات والسائقين بشكل لحظي (Real-time). يوفر تحديثات فورية للتغييرات دون الحاجة لاستطلاع (polling).

---

## معلومات الاتصال

### Base URL

```
https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/
```

### Credentials (مطلوب للوصول عبر API)

- **Project ID**: `jeeb-f64a4`
- **Database URL**: `https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/`
- **Service Account**: `firebase-adminsdk-fbsvc@jeeb-f64a4.iam.gserviceaccount.com`

---

## Firebase Custom Token Authentication

### نظرة عامة

نظام المصادقة المخصصة يستخدم Firebase Custom Token لضمان أمان الوصول إلى RTDB. عند تسجيل دخول الديلفري، يتم إصدار Custom Token يربط Firebase UID بالـ deliveryId.

### Endpoint تحديث Firebase Token

```
POST /api/v1/auth/firebase-token
```

**المصادقة**: Bearer Token (JWT)

**Request Body:**

| Parameter | Type | Required | Description |
| :--------------- | :----- | :------- | :-------------- |
| `firebaseToken` | String | No* | FCM device token. Validation: `@IsOptional()` `@IsString()` `@IsNotEmpty()` `@ValidateIf((o) => !o.token)` |
| `token` | String | No* | بديل عن `firebaseToken`. Validation: `@IsOptional()` `@IsString()` `@IsNotEmpty()` `@ValidateIf((o) => !o.firebaseToken)` |

*مطلوب واحد على الأقل (إما `firebaseToken` أو `token`).

```json
{
  "firebaseToken": "fcm_device_token_here"
}
```

**Response لكل الأدوار (ما عدا DELIVERY):**

```json
{
  "statusCode": 201,
  "message": "Firebase token updated successfully",
  "data": {
    "success": true,
    "fcmTokenUpdated": true
  },
  "timestamp": "2026-04-06T10:27:20.858Z",
  "path": "/api/v1/auth/firebase-token"
}
```

**Response إضافي لـ DELIVERY فقط:**

```json
{
  "statusCode": 201,
  "message": "Firebase token and custom token generated successfully",
  "data": {
    "success": true,
    "fcmTokenUpdated": true,
    "firebaseUid": "delivery_30134",
    "customToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "timestamp": "2026-04-06T10:25:52.635Z",
  "path": "/api/v1/auth/firebase-token"
}
```

### ملخص المصادقة

| الدور | FCM Token | Custom Token | Firebase UID |
| ------------ | --------- | ------------ | ------------ |
| CUSTOMER | ✅ يُحدث | ❌ | ❌ |
| MERCHANT | ✅ يُحدث | ❌ | ❌ |
| DELIVERY | ✅ يُحدث | ✅ يُنشأ | ✅ يُرجع |
| ADMIN | ✅ يُحدث | ❌ | ❌ |
| SUPPORT | ✅ يُحدث | ❌ | ❌ |
| OFFICE_OWNER | ✅ يُحدث | ❌ | ❌ |

### Firebase UID Structure

- **Format**: `delivery_{userId}`
- **مثال**: `delivery_30134` حيث 30134 هو الـ userId في قاعدة البيانات

---

## هيكل البيانات (Data Structure)

### 1. Orders Collection (`/orders`)

```
/orders/{orderId}
```

| الحقل | النوع | الوصف |
| -------------------- | --------- | ------------------------------------------ |
| `id` | number | رقم الطلب (مطابق لـ `orderId`) |
| `orderId` | number | رقم الطلب |
| `status` | string | حالة الطلب |
| `customerId` | number | رقم العميل |
| `ownerId` | number | رقم صاحب المطعم |
| `deliveryId` | number | رقم السائق المكلف (nullable) |
| `deliveryUid` | string | Firebase UID للسائق (مثل: `delivery_57`) |
| `restaurantLocation` | object or null | موقع المطعم `{lat, lng}` |
| `customerLocation` | object or null | موقع العميل `{lat, lng}` |
| `routeHistory` | array | مصفوفة نقاط المسار `[{lat, lng, timestamp}]` |
| `speed` | number | سرعة السائق (كم/ساعة) |
| `createdAt` | timestamp | وقت الإنشاء (Unix timestamp) |
| `updatedAt` | timestamp | وقت آخر تحديث (Unix timestamp) |

#### هيكل routeHistory

```json
"routeHistory": [
  {"lat": 33.5100, "lng": 36.2700, "timestamp": 1699999900000},
  {"lat": 33.5110, "lng": 36.2720, "timestamp": 1699999960000},
  {"lat": 33.5138, "lng": 36.2765, "timestamp": 1699999999000}
]
```

**ملاحظة**: للحصول على الموقع الحالي للسائق:

```javascript
const currentLocation = routeHistory[routeHistory.length - 1];
```

#### حالات الطلب في Firebase

| الحالة | الوصف |
| ------------------ | ------------------ |
| `PENDING` | الطلب جديد |
| `CONFIRMED` | تم التأكيد |
| `SEARCHING` | جاري البحث عن سائق |
| `ASSIGNED` | تم تعيين سائق |
| `PREPARING` | جاري التحضير |
| `READY_FOR_PICKUP` | جاهز للاستلام |
| `PICKED_UP` | تم استلام الطلب |
| `ON_THE_WAY` | في الطريق |
| `DELIVERED` | تم التسليم |
| `CANCELLED` | ملغى |
| `REJECTED` | مرفوض |

---

### 2. Drivers Collection (`/drivers`)

```
/drivers/{driverId}
```

| الحقل | النوع | الوصف |
| ------------ | --------- | ---------------------------- |
| `id` | number | رقم السائق (مطابق لـ key) |
| `currentLat` | number | خط العرض الحالي |
| `currentLng` | number | خط الطول الحالي |
| `isOnline` | boolean | هل السائق متصل |
| `createdAt` | timestamp | وقت الإنشاء (Unix timestamp) |

---

## العمليات (Operations)

### Orders - الإنشاء والتحديث والحذف

#### 1. إنشاء مستند طلب (Create Order Document)

**المشغل**: عند إنشاء الطلب الجديد (PENDING)

**المسار**:

- `OrderCreationStage` في `order-pipeline.ts` — عند إنشاء الطلب الأولي
- `StatusUpdateStage` في `status-update.stage.ts` — كاحتياطي إذا لم يُنشأ المستند

```typescript
// src/modules/orders/pipeline/order-pipeline.ts (OrderCreationStage)
await this.firebaseService.createOrderDocument(order);

// src/modules/orders/pipeline/stages/status-update.stage.ts (StatusUpdateStage)
await this.firebaseService.createOrderDocument(order);
```

**البيانات المُرسلة**:

```json
{
  "id": 69,
  "orderId": 69,
  "status": "PENDING",
  "customerId": 52,
  "ownerId": 30114,
  "deliveryId": null,
  "deliveryUid": null,
  "restaurantLocation": {
    "lat": 35.3659335,
    "lng": 35.9443132
  },
  "customerLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "routeHistory": [],
  "speed": 0,
  "createdAt": 1774784651163,
  "updatedAt": 1774784651163
}
```

**ملاحظات**:

- `routeHistory` يبدأ كمصفوفة **فارغة** `[]`. تمتلئ النقاط لاحقاً عند تحديث موقع السائق.
- يتم إنشاؤه فوراً عند إنشاء الطلب (حالة PENDING).
- `deliveryId` و `deliveryUid` يكونان `null` في البداية.
- `restaurantLocation` و `customerLocation` قد يكونان `null` إذا لم تكن الإحداثيات متوفرة.

---

#### 2. تحديث حالة الطلب (Update Order Status)

**المشغل**: عند تغيير أي حالة طلب

```typescript
// src/modules/orders/pipeline/stages/status-update.stage.ts
await this.firebaseService.updateOrderDocument(order.id, newStatus);
```

**البيانات المُرسلة**:

```json
{
  "status": "SEARCHING",
  "updatedAt": 1711569035000
}
```

**ملاحظات**:

- `updateOrderDocument` يُحدث فقط `status` و `updatedAt`.
- `deliveryId` و `deliveryUid` يُحدّثان عبر `setDeliveryId()` بشكل منفصل (انظر أدناه).

---

#### 2b. تعيين deliveryId (Set Delivery ID)

**المشغل**: عند:

- تعيين سائق للطلب (حالة ASSIGNED) — يُستدعى من `delivery-assignment.service.ts`
- تحديث السائق في الحالات ASSIGNED, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY — يُستدعى من `order-actions.service.ts`

```typescript
// src/modules/orders/services/delivery-assignment.service.ts
await this.firebaseService.setDeliveryId(orderId, deliveryId);

// src/modules/orders/services/order-actions.service.ts
await this.firebaseService.setDeliveryId(orderId, deliveryAssignment.deliveryId);
```

**البيانات المُرسلة**:

```json
{
  "deliveryId": 57,
  "deliveryUid": "delivery_57",
  "updatedAt": 1711569035000
}
```

**ملاحظات**:

- `deliveryId` و `deliveryUid` يُعينان لأول مرة عند حالة ASSIGNED.
- يُحدثان عند كل حالة توصيل: READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY.
- يتم استدعاء `setDeliveryId` بالإضافة إلى `updateOrderDocument` (وليس كجزء منه).

---

#### 3. حذف مستند الطلب (Delete Order Document)

**المشغل**: عند:

- تم التسليم (DELIVERED) — **بعد تأخير 5 ثوانٍ**
- إلغاء الطلب (CANCELLED)
- رفض الطلب (REJECTED)

```typescript
// src/modules/orders/pipeline/stages/status-update.stage.ts
// DELIVERED status - waits 5 seconds before deleting
setTimeout(async () => {
  await this.firebaseService.deleteOrderDocument(order.id);
}, 5000);

// CANCELLED/REJECTED - deletes immediately
await this.firebaseService.deleteOrderDocument(order.id);
```

**ملاحظات**:

- **تأخير 5 ثوانٍ**: عند حالة DELIVERED، يتم الانتظار 5 ثوانٍ قبل الحذف لإتاحة الوقت للتعقب النهائي.
- مستند السائق لا يُحذف عند إنهاء الطلب (يبقى للتتبع).

---

#### 4. تحديث موقع السائق للتتبع (Update Order Driver Location)

**المشغل**: عند إرسال السائق لموقعه عبر endpoint التتبع

```typescript
// POST /api/v1/tracking/update-location
await this.firebaseService.updateOrderDriverLocation(orderId, location, speed);
```

**البيانات المُرسلة**:

```json
{
  "routeHistory": [
    { "lat": 33.51, "lng": 36.27, "timestamp": 1699999900000 },
    { "lat": 33.511, "lng": 36.272, "timestamp": 1699999960000 },
    { "lat": 33.5138, "lng": 36.2765, "timestamp": 1699999999000 }
  ],
  "speed": 30,
  "updatedAt": 1711569035000
}
```

**ملاحظات**:

- يتم إلحاق النقطة الجديدة في نهاية `routeHistory` (لا استبدال).
- إذا كانت `routeHistory` فارغة، تُنشأ مصفوفة جديدة وتُضاف النقطة.

---

### Drivers - الإنشاء والتحديث والحذف

#### 1. إنشاء مستند سائق (Create Driver Document)

**المشغل**: عند:

- تسجيل سائق جديد (Register) — في `registration.service.ts`
- إنشاء سائق من قبل الأدمن — في `users-admin.service.ts`
- إنشاء سائق من قبل صاحب المكتب — في `office-owners.service.ts`
- قبول السائق لطلب توصيل — في `delivery-assignment.service.ts`

```typescript
// في registration.service.ts - عند تسجيل سائق جديد
await this.firebaseService.createDriverDocument({
  id: user.id,
  currentLat: user.currentLat || 0,
  currentLng: user.currentLng || 0,
  isOnline: false,
});

// في users-admin.service.ts - عند إنشاء سائق من الأدمن
await this.firebaseService.createDriverDocument({
  id: savedUser.id,
  currentLat: lat,
  currentLng: lng,
  isOnline: true,
});

// في office-owners.service.ts - عند إنشاء سائق من صاحب المكتب
await this.firebaseService.createDriverDocument({
  id: savedUser.id,
  currentLat: 0,
  currentLng: 0,
  isOnline: true,
});

// في delivery-assignment.service.ts - عند قبول طلب التوصيل
await this.firebaseService.createDriverDocument({
  id: driver.id,
  currentLat: driver.currentLat,
  currentLng: driver.currentLng,
  isOnline: driver.isOnline,
});
```

**البيانات المُرسلة**:

```json
{
  "id": 57,
  "currentLat": 33.5138,
  "currentLng": 36.2765,
  "isOnline": true,
  "createdAt": 1711569034000
}
```

---

#### 2. حذف مستند سائق (Delete Driver Document)

**المشغل**: عند:

- حذف حساب سائق (من الأدمن أو صاحب المكتب أو المستخدم نفسه)

```typescript
// في profile.service.ts - عند حذف السائق لحسابه
await this.firebaseService.deleteDriverDocument(userId);

// في users-admin.service.ts - عند حذف سائق من الأدمن
await this.firebaseService.deleteDriverDocument(deliveryId);

// في office-owners.service.ts - عند حذف سائق من صاحب المكتب
await this.firebaseService.deleteDriverDocument(deliveryId);
```

**ملاحظة**: لم يعد يتم حذف مستند السائق عند إنهاء الطلب — يبقى للتتبع.

---

## الجدول الزمني للعمليات

### دورة حياة الطلب في Firebase

```
PENDING → CREATE /orders/{id} (routeHistory: [])
    ↓
CONFIRMED → UPDATE /orders/{id} (status: "CONFIRMED")
    ↓
SEARCHING → UPDATE /orders/{id} (status: "SEARCHING")
    ↓
ASSIGNED → UPDATE /orders/{id} (status: "ASSIGNED")
         → UPDATE /orders/{id} (deliveryId, deliveryUid) ← setDeliveryId()
    ↓
PREPARING → UPDATE /orders/{id} (status: "PREPARING")
    ↓
READY_FOR_PICKUP → UPDATE /orders/{id} (status: "READY_FOR_PICKUP")
                 → UPDATE /orders/{id} (deliveryId, deliveryUid) ← setDeliveryId()
    ↓
PICKED_UP → UPDATE /orders/{id} (status: "PICKED_UP")
          → UPDATE /orders/{id} (deliveryId, deliveryUid) ← setDeliveryId()
    ↓
ON_THE_WAY → UPDATE /orders/{id} (status: "ON_THE_WAY")
           → UPDATE /orders/{id} (deliveryId, deliveryUid) ← setDeliveryId()
           ↓ (التتبع اللحظي: routeHistory يُحدث)
    ↓
DELIVERED → DELETE /orders/{id} (بعد تأخير 5 ثوانٍ)
         ↓ (السائق يبقى في Firebase)
```

**ملاحظات دورة الحياة**:

- **`deliveryId` و `deliveryUid`**: يُعينان عند حالة ASSIGNED عبر `setDeliveryId()`، ويُحدثان عند كل حالة توصيل (READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY).
- **`routeHistory`**: يبدأ كمصفوفة **فارغة** عند إنشاء الطلب. تُضاف النقاط لاحقاً عبر `updateOrderDriverLocation`.
- **التأخير**: عند DELIVERED، يتم الانتظار 5 ثوانٍ قبل حذف المستند.

### دورة حياة السائق في Firebase

```
إنشاء حساب سائق → CREATE /drivers/{id}
    ↓
قبول طلب توصيل → UPDATE /drivers/{id} (مع الموقع الحالي)
    ↓
تحديث الموقع (أثناء التوصيل) → UPDATE /drivers/{id}
    ↓
إنهاء الطلب → (لا يُحذف السائق - يبقى للتتبع)
    ↓
حذف حساب السائق → DELETE /drivers/{id}
```

---

## التتبع اللحظي (Real-time Tracking)

### endpoint تحديث الموقع

```
POST /api/v1/tracking/update-location
```

**المصادقة**: لا يتطلب Bearer Token (عام — `@Public()`). يمكن لأي جهاز إرسال تحديثات الموقع.

**Request Body:**

| Parameter | Type | Required | Description |
| :-------- | :--- | :------- | :---------- |
| `orderId` | Number | Yes | رقم الطلب. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `lat` | Number | Yes | خط العرض. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `lng` | Number | Yes | خط الطول. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `timestamp` | Number | Yes | التوقيت (Unix timestamp). Validation: `@IsNumber()` `@IsNotEmpty()` |
| `speed` | Number | No | السرعة (كم/س). Validation: `@IsNumber()` `@IsOptional()`. الافتراضي: 0 |

```json
{
  "orderId": 123,
  "lat": 33.514,
  "lng": 36.277,
  "timestamp": 1700000000000,
  "speed": 30
}
```

**Response (بعد معالجة TransformInterceptor):**

```json
{
  "statusCode": 200,
  "message": "Location updated successfully",
  "data": {
    "success": true
  },
  "timestamp": "2026-06-12T10:00:00.000Z",
  "path": "/api/v1/tracking/update-location"
}
```

### ما يحدث عند التحديث:

1. تُقرأ `routeHistory` الحالية من Firebase.
2. تُضاف النقطة الجديدة إلى `routeHistory`.
3. يُحدث `speed`.
4. يُحدث `updatedAt`.

---

## أمثلة على الـ Data JSON

### مثال على مستند طلب (مع تتبع)

```json
{
  "id": 56,
  "orderId": 56,
  "status": "ON_THE_WAY",
  "customerId": 52,
  "ownerId": 30114,
  "deliveryId": 57,
  "deliveryUid": "delivery_57",
  "restaurantLocation": {
    "lat": 35.3659335,
    "lng": 35.9443132
  },
  "customerLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "routeHistory": [
    { "lat": 35.3659, "lng": 35.9443, "timestamp": 1700000000000 },
    { "lat": 35.0, "lng": 36.0, "timestamp": 1700000100000 },
    { "lat": 34.5, "lng": 36.1, "timestamp": 1700000200000 },
    { "lat": 33.9, "lng": 36.2, "timestamp": 1700000300000 },
    { "lat": 33.5138, "lng": 36.2765, "timestamp": 1700000400000 }
  ],
  "speed": 45,
  "createdAt": 1700000000000,
  "updatedAt": 1700000400000
}
```

### مثال على مستند سائق

```json
{
  "id": 57,
  "currentLat": 33.5138,
  "currentLng": 36.2765,
  "isOnline": true,
  "createdAt": 1711569034000
}
```

---

## الوصول عبر API (REST API)

### المصادقة (Authentication)

للوصول إلى Firebase RTDB عبر REST API، يمكنك استخدام:

1. **Firebase Admin SDK** (موصى به — Backend فقط)
2. **Custom Token** (لـ DELIVERY فقط — للتتبع المباشر من التطبيق)
3. **Anonymous Authentication** (للقراءة فقط)

### GET — قراءة البيانات

```bash
# قراءة جميع الطلبات
curl "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders.json?auth=<TOKEN>"

# قراءة طلب واحد
curl "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>"

# قراءة جميع السائقين
curl "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/drivers.json?auth=<TOKEN>"

# قراءة سائق واحد
curl "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/drivers/57.json?auth=<TOKEN>"
```

### PATCH — تحديث البيانات

```bash
# تحديث حالة الطلب فقط
curl -X PATCH "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>" \
  -d '{"status": "ASSIGNED", "updatedAt": 1711569035000}'

# تحديث routeHistory (يتطلب Custom Token من DELIVERY)
curl -X PATCH "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<CUSTOM_TOKEN>" \
  -d '{"routeHistory": [...], "speed": 30, "updatedAt": 1711569035000}'
```

### PUT — إنشاء/استبدال

```bash
# إنشاء طلب جديد (كـ PENDING مع routeHistory فارغ)
curl -X PUT "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>" \
  -d '{
    "id": 56,
    "orderId": 56,
    "status": "PENDING",
    "customerId": 52,
    "ownerId": 30114,
    "deliveryId": null,
    "deliveryUid": null,
    "restaurantLocation": {"lat": 35.3659, "lng": 35.9443},
    "customerLocation": {"lat": 33.5138, "lng": 36.2765},
    "routeHistory": [],
    "speed": 0,
    "createdAt": 1711569034000,
    "updatedAt": 1711569034000
  }'
```

### DELETE — حذف البيانات

```bash
# حذف طلب
curl -X DELETE "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>"

# حذف سائق
curl -X DELETE "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/drivers/57.json?auth=<TOKEN>"
```

---

## التشفير والأمان

### Security Rules (انظر `Firebase_Security_Rules.md` للتفاصيل)

القواعد الجديدة تعتمد على:

- **القراءة**: مسموحة للجميع
- **الكتابة في orders**: فقط للديلفري صاحب المستند (عبر مطابقة `auth.uid` مع `deliveryUid`)
- **الكتابة في drivers**: فقط للديلفري صاحب الملف

### ملخص الصلاحيات:

| Collection | قراءة | إنشاء | تحديث | حذف |
| ---------- | ----- | ----- | ----- | --- |
| `drivers` | ✅ الكل | ❌ (من Client) | `currentLat`, `currentLng`, `onLine` | ❌ |
| `orders` | ✅ الكل | ❌ (من Client) | `routeHistory`, `speed` | ❌ |

> **ملاحظة:** عمليات الإنشاء والحذف تتم من خلال Backend عبر Admin SDK الذي يتجاوز Security Rules.

---

## التكامل مع الكود

### FirebaseService

الخدمة الرئيسية موجودة في:

```
src/modules/firebase/firebase.service.ts
```

#### Methods المتاحة:

| Method | الوصف |
| ----------------------------------------------------- | ------------------------------ |
| `createOrderDocument(order)` | إنشاء مستند طلب |
| `updateOrderDocument(orderId, status)` | تحديث حالة الطلب |
| `deleteOrderDocument(orderId)` | حذف مستند طلب |
| `updateOrderDriverLocation(orderId, location, speed)` | تحديث موقع السائق للتتبع |
| `setDeliveryId(orderId, deliveryId)` | تعيين `deliveryId` و `deliveryUid` |
| `createDriverDocument(driver)` | إنشاء مستند سائق |
| `deleteDriverDocument(driverId)` | حذف مستند سائق |
| `updateDriverLocation(driverId, lat, lng)` | تحديث موقع السائق |
| `updateDriverOnlineStatus(driverId, onLine)` | تحديث حالة الاتصال (الباراميتر: `onLine` وليس `isOnline`) |
| `createCustomTokenForDelivery(user)` | إنشاء Custom Token للديلفري |
| `verifyIdToken(token)` | التحقق من Firebase ID Token (للمصادقة المجهولة) |

### TrackingController

الـ Controller للتتبع اللحظي:

```
src/modules/tracking/tracking.controller.ts
```

#### endpoint:

```
POST /api/v1/tracking/update-location
```

> **ملاحظة:** هذا الـ endpoint عام (`@Public()`) ولا يتطلب Bearer Token.

---

## مراقبة الأخطاء

### Logs

النظام يسجل العمليات في Console:

```
📦 [PIPELINE] Order 56 status updated to PENDING
🔥 [FIREBASE] Created order document for new order 56
🔥 [FIREBASE] Updated order 56 status to ASSIGNED with deliveryId 57
🔥 [FIREBASE] Set deliveryId 57 for order 56
🔥 [FIREBASE] Driver document created for driver 57
🔍 [AUTH] updateFirebaseToken - user.id: 30134, userRole: DELIVERY, isDelivery: true
✅ [AUTH] Custom token created successfully, uid: delivery_30134
```

> **ملاحظة:** سجلات Firebase داخل `FirebaseService` تستخدم `this.logger.log('RTDB: ...')`. سجلات `🔥 [FIREBASE]` تأتي من الـ pipeline stages.

### الأخطاء المحتملة

| الخطأ | الوصف |
| ------------------- | --------------------- |
| `PERMISSION_DENIED` | لا توجد صلاحية للوصول (من Firebase Security Rules) |
| `DATABASE_ERROR` | خطأ في قاعدة البيانات |
| `NETWORK_ERROR` | خطأ في الشبكة |

---

## ملاحظات مهمة

1. **القراءة فقط**: لا يُنصح بتعديل البيانات مباشرة من Firebase Console، يجب أن يتم ذلك من خلال التطبيق.

2. **التزامن**: Firebase RTDB يوفر تزامن لحظي، التغييرات تظهر فوراً.

3. **الاحتفاظ بالبيانات**: يتم حذف مستندات الطلبات عند التسليم/الإلغاء/الرفض.

4. **تأخير الحذف**: حالة DELIVERED تنتظر 5 ثوانٍ قبل حذف المستند.

5. **الاحتفاظ بالسائقين**: مستندات السائقين تبقى بعد إنهاء الطلب (للتتبع).

6. **`deliveryId` و `deliveryUid`**: يُعينان عند ASSIGNED عبر `setDeliveryId()` ويُحدثان عند كل حالة توصيل.

7. **التوقيت**: جميع التواريخ مخزنة كـ Unix timestamp (milliseconds).

8. **`routeHistory`**: يبدأ كمصفوفة فارغة عند إنشاء الطلب. للحصول على الموقع الحالي للسائق، استخدم آخر عنصر في المصفوفة.

9. **Custom Token**: يُنشأ فقط للديلفري عبر endpoint `/auth/firebase-token` ويستخدم للتتبع المباشر.

10. **`@Public()` على tracking**: endpoint `/tracking/update-location` عام ولا يتطلب مصادقة.

---

## Script للمزامنة

للمزامنة اليدوية بين قاعدة البيانات وFirebase:

```bash
npm run db:sync-drivers-firebase
```

الملف: `scripts/sync-drivers-to-firebase.ts`

---

## الأسئلة الشائعة (FAQ)

### س: كيف يحصل الديلفري على Custom Token؟

**ج:** عند استدعاء endpoint `/auth/firebase-token` مع تسجيل دخول كـ DELIVERY، يتم إرجاع `customToken` في الـ response. هذا الـ token يُستخدم للمصادقة مع Firebase RTDB.

### س: هل يمكن للعميل أو التاجر تحديث بيانات الطلب في Firebase؟

**ج:** لا، القواعد تسمح فقط للـ DELIVERY بكتابة بيانات التتبع (`routeHistory`, `speed`). التحديثات الأخرى تتم من Backend فقط.

### س: كيف أعرف موقع السائق الحالي؟

**ج:** استخدم آخر عنصر في `routeHistory`:

```javascript
const currentLocation = routeHistory[routeHistory.length - 1];
```

### س: هل يمكن للسائق تحديث موقعه مباشرة؟

**ج:** نعم، عبر endpoint `/tracking/update-location` (لا يتطلب مصادقة) أو مباشرة عبر Firebase مع Custom Token.

### س: ما الفرق بين deliveryId و deliveryUid؟

**ج:**

- **deliveryId**: رقم المستخدم في قاعدة البيانات (مثل: `57`)
- **deliveryUid**: Firebase UID المستخدم في المصادقة (مثل: `delivery_57`)

### س: هل يمكن إضافة حقول إضافية؟

**ج:** نعم، يمكن توسيع الهيكل حسب الحاجة، مع مراعاة تحديث Security Rules إذا كانت الحقول الجديدة قابلة للكتابة.
