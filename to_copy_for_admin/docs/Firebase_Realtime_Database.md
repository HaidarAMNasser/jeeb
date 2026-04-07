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

## هيكل البيانات (Data Structure)

### 1. Orders Collection (`/orders`)

```
/orders/{orderId}
```

| الحقل                | النوع     | الوصف                                      |
| -------------------- | --------- | ------------------------------------------ |
| `id`                 | number    | رقم الطلب (مطابق لـ key)                   |
| `orderId`            | number    | رقم الطلب                                  |
| `status`             | string    | حالة الطلب                                 |
| `customerId`         | number    | رقم العميل                                 |
| `ownerId`            | number    | رقم صاحب المطعم                            |
| `deliveryId`         | number    | رقم السائق المكلف (nullable)               |
| `restaurantLocation` | object    | موقع المطعم {lat, lng}                     |
| `customerLocation`   | object    | موقع العميل {lat, lng}                     |
| `routeHistory`       | array     | مصفوفة نقاط المسار [{lat, lng, timestamp}] |
| `speed`              | number    | سرعة السائق (كم/ساعة)                      |
| `createdAt`          | timestamp | وقت الإنشاء (Unix timestamp)               |
| `updatedAt`          | timestamp | وقت آخر تحديث (Unix timestamp)             |

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

| الحالة             | الوصف              |
| ------------------ | ------------------ |
| `PENDING`          | الطلب جديد         |
| `CONFIRMED`        | تم التأكيد         |
| `SEARCHING`        | جاري البحث عن سائق |
| `ASSIGNED`         | تم تعيين سائق      |
| `PREPARING`        | جاري التحضير       |
| `READY_FOR_PICKUP` | جاهز للاستلام      |
| `PICKED_UP`        | تم استلام الطلب    |
| `ON_THE_WAY`       | في الطريق          |
| `DELIVERED`        | تم التسليم         |
| `CANCELLED`        | ملغى               |
| `REJECTED`         | مرفوض              |

---

### 2. Drivers Collection (`/drivers`)

```
/drivers/{driverId}
```

| الحقل        | النوع     | الوصف                        |
| ------------ | --------- | ---------------------------- |
| `id`         | number    | رقم السائق (مطابق لـ key)    |
| `currentLat` | number    | خط العرض الحالي              |
| `currentLng` | number    | خط الطول الحالي              |
| `isOnline`   | boolean   | هل السائق متصل               |
| `createdAt`  | timestamp | وقت الإنشاء (Unix timestamp) |

---

## العمليات (Operations)

### Orders - الإنشاء والتحديث والحذف

#### 1. إنشاء مستند طلب (Create Order Document)

**المشغل**: عند إنشاء الطلب الجديد (PENDING)

**المسار**:

- `OrderPipeline` - عند إنشاء الطلب الأولي
- `StatusUpdateStage` - كاحتياطي إذا لم يُنشأ المستند

```typescript
// src/modules/orders/pipeline/order-pipeline.ts
await this.firebaseService.createOrderDocument(order);

// src/modules/orders/pipeline/stages/status-update.stage.ts
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
  "restaurantLocation": {
    "lat": 35.3659335,
    "lng": 35.9443132
  },
  "customerLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "routeHistory": [
    {
      "lat": 35.3659335,
      "lng": 35.9443132,
      "timestamp": 1774784651163
    }
  ],
  "speed": 0,
  "createdAt": 1774784651163,
  "updatedAt": 1774784651163
}
```

**ملاحظات**:

- `routeHistory` يبدأ بنقطة واحدة تمثل موقع المطعم (نقطة الانطلاق)
- يتم إنشاؤه فوراً عند إنشاء الطلب (حالة PENDING وليس CONFIRMED)
- `deliveryId` يكون `null` في البداية

---

#### 2. تحديث حالة الطلب (Update Order Status)

**المشغل**: عند تغيير أي حالة طلب

```typescript
// src/modules/orders/pipeline/stages/status-update.stage.ts
await this.firebaseService.updateOrderDocument(order.id, newStatus);
```

**البيانات المُرسلة** (الحالة العادية):

```json
{
  "status": "SEARCHING",
  "updatedAt": 1711569035000
}
```

**البيانات المُرسلة** (مع deliveryId - عند ASSIGNED, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY):

```json
{
  "status": "ASSIGNED",
  "deliveryId": 57,
  "updatedAt": 1711569035000
}
```

**ملاحظات**:

- **deliveryId**: يُعين لأول مرة عند حالة ASSIGNED
- **deliveryId يُحدث** عند: ASSIGNED, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY

---

#### 3. حذف مستند الطلب (Delete Order Document)

**المشغل**: عند:

- تم التسليم (DELIVERED) - **بعد تأخير 5 ثوانٍ**
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

- **تأخير 5 ثوانٍ**: عند حالة DELIVERED، يتم الانتظار 5 ثوانٍ قبل الحذف لإتاحة الوقت للتعقب النهائي
- مستند السائق لا يُحذف عند إنهاء الطلب (يبقى للتتبع)

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

---

### Drivers - الإنشاء والتحديث والحذف

#### 1. إنشاء مستند سائق (Create Driver Document)

**المشغل**: عند:

- تسجيل سائق جديد (Register)
- إنشاء سائق من قبل الأدمن
- إنشاء سائق من قبل صاحب المكتب
- قبول السائق لطلب توصيل

```typescript
// في auth.service.ts - عند تسجيل سائق جديد
await this.firebaseService.createDriverDocument({
  id: user.id,
  currentLat: user.currentLat || 0,
  currentLng: user.currentLng || 0,
  isOnline: false,
});

// في users-admin.service.ts - عند إنشاء سائق من الأدمن
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

- حذف حساب سائق

```typescript
// في auth.service.ts - عند حذف حساب سائق
await this.firebaseService.deleteDriverDocument(userId);

// في users-admin.service.ts - عند حذف سائق
await this.firebaseService.deleteDriverDocument(deliveryId);

// في office-owners.service.ts - عند حذف سائق
await this.firebaseService.deleteDriverDocument(deliveryId);
```

**ملاحظة**: لم يعد يتم حذف مستند السائق عند إنهاء الطلب - يبقى للتتبع.

---

## الجدول الزمني للعمليات

### دورة حياة الطلب في Firebase

```
PENDING → CREATE /orders/{id} (مع routeHistory واحد موقع المطعم)
    ↓
CONFIRMED → UPDATE /orders/{id} (status: "CONFIRMED")
    ↓
SEARCHING → UPDATE /orders/{id} (status: "SEARCHING")
    ↓
ASSIGNED → UPDATE /orders/{id} (status: "ASSIGNED", deliveryId: number)
    ↓
PREPARING → UPDATE /orders/{id} (status: "PREPARING")
    ↓
READY_FOR_PICKUP → UPDATE /orders/{id} (status: "READY_FOR_PICKUP", deliveryId: number)
    ↓
PICKED_UP → UPDATE /orders/{id} (status: "PICKED_UP", deliveryId: number)
    ↓
ON_THE_WAY → UPDATE /orders/{id} (status: "ON_THE_WAY", deliveryId: number)
         ↓ (التتبع اللحظي: routeHistory يُحدث)
    ↓
DELIVERED → DELETE /orders/{id} (بعد تأخير 5 ثوانٍ)
         ↓ (السائق يبقى في Firebase)
```

**ملاحظات دورة الحياة**:

- **deliveryId**: يُعين عند حالة ASSIGNED ويتحدث عند كل حالة توصيل (ASSIGNED, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY)
- **routeHistory**: يبدأ بنقطة واحدة (موقع المطعم) عند إنشاء الطلب
- **التأخير**: عند DELIVERED، يتم الانتظار 5 ثوانٍ قبل حذف المستند

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

**المطلوب**: Bearer Token (أو يمكن استخدام Firebase مباشرة مع Security Rules)

**Request Body:**

```json
{
  "orderId": 123,
  "lat": 33.514,
  "lng": 36.277,
  "timestamp": 1700000000000,
  "speed": 30
}
```

**Response:**

```json
{
  "success": true,
  "message": "Location updated successfully"
}
```

### ما يحدث عند التحديث:

1. تُضاف النقطة الجديدة لـ `routeHistory`
2. يُحدث `speed`
3. يُحدث `updatedAt`

### Security Rules للتتبع:

```json
{
  "rules": {
    "orders": {
      "$orderId": {
        ".read": true,
        ".create": false,
        ".update": "
          auth != null &&
          (
            (newData.hasChild('routeHistory') && newData.child('routeHistory').isArray()) ||
            (newData.hasChild('speed') && newData.child('speed').isNumber())
          ) &&
          !newData.hasChild('id') &&
          !newData.hasChild('orderId') &&
          !newData.hasChild('status') &&
          !newData.hasChild('customerId') &&
          !newData.hasChild('ownerId') &&
          !newData.hasChild('deliveryId') &&
          !newData.hasChild('restaurantLocation') &&
          !newData.hasChild('customerLocation') &&
          !newData.hasChild('createdAt')
        ",
        ".delete": false
      }
    }
  }
}
```

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
  "createdAt": 1700000000000
}
```

---

## الوصول عبر API (REST API)

### المصادقة (Authentication)

للوصول إلى Firebase RTDB عبر REST API، يمكنك استخدام:

1. **Firebase Admin SDK** (موصى به)
2. **Custom Token**
3. **Anonymous Authentication** (للقراءة فقط)

### GET - قراءة البيانات

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

### PATCH - تحديث البيانات

```bash
# تحديث حالة الطلب
curl -X PATCH "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>" \
  -d '{"status": "ASSIGNED", "updatedAt": 1711569035000}'

# تحديث routeHistory (يتطلب Firebase Auth)
curl -X PATCH "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>" \
  -d '{"routeHistory": [...], "speed": 30, "updatedAt": 1711569035000}'
```

### PUT - إنشاء/استبدال

```bash
# إنشاء طلب جديد (كـ PENDING مع routeHistory واحد)
curl -X PUT "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>" \
  -d '{
    "id": 56,
    "orderId": 56,
    "status": "PENDING",
    "customerId": 52,
    "ownerId": 30114,
    "deliveryId": null,
    "restaurantLocation": {"lat": 35.3659, "lng": 35.9443},
    "customerLocation": {"lat": 33.5138, "lng": 36.2765},
    "routeHistory": [
      {"lat": 35.3659, "lng": 35.9443, "timestamp": 1711569034000}
    ],
    "speed": 0,
    "createdAt": 1711569034000,
    "updatedAt": 1711569034000
  }'
```

### DELETE - حذف البيانات

```bash
# حذف طلب
curl -X DELETE "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/orders/56.json?auth=<TOKEN>"

# حذف سائق
curl -X DELETE "https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/drivers/57.json?auth=<TOKEN>"
```

---

## التشفير والأمان

### القواعد (Security Rules)

#### قواعد Drivers

```json
{
  "rules": {
    "drivers": {
      "$driverId": {
        ".read": true,
        ".create": false,
        ".update": "auth != null &&
                   (
                     (newData.hasChild('currentLat') && newData.child('currentLat').isNumber()) ||
                     (newData.hasChild('currentLng') && newData.child('currentLng').isNumber()) ||
                     (newData.hasChild('isOnline') && newData.child('isOnline').isBool())
                   ) &&
                   !newData.hasChild('id') &&
                   !newData.hasChild('createdAt')",
        ".delete": false
      }
    }
  }
}
```

#### قواعد Orders

```json
{
  "rules": {
    "orders": {
      "$orderId": {
        ".read": true,
        ".create": false,
        ".update": "
          auth != null &&
          (
            (newData.hasChild('routeHistory') && newData.child('routeHistory').isArray()) ||
            (newData.hasChild('speed') && newData.child('speed').isNumber())
          ) &&
          !newData.hasChild('id') &&
          !newData.hasChild('orderId') &&
          !newData.hasChild('status') &&
          !newData.hasChild('customerId') &&
          !newData.hasChild('ownerId') &&
          !newData.hasChild('deliveryId') &&
          !newData.hasChild('restaurantLocation') &&
          !newData.hasChild('customerLocation') &&
          !newData.hasChild('createdAt')
        ",
        ".delete": false
      }
    }
  }
}
```

### ملخص الصلاحيات:

| Collection | قراءة   | إنشاء | تحديث                            | حذف |
| ---------- | ------- | ----- | -------------------------------- | --- |
| `drivers`  | ✅ الكل | ❌    | currentLat, currentLng, isOnline | ❌  |
| `orders`   | ✅ الكل | ❌    | routeHistory, speed              | ❌  |

---

## التكامل مع الكود

### FirebaseService

الخدمة الرئيسية موجودة في:

```
src/modules/firebase/firebase.service.ts
```

#### Methods المتاحة:

| Method                                                | الوصف                    |
| ----------------------------------------------------- | ------------------------ |
| `createOrderDocument(order)`                          | إنشاء مستند طلب          |
| `updateOrderDocument(orderId, status)`                | تحديث حالة الطلب         |
| `deleteOrderDocument(orderId)`                        | حذف مستند طلب            |
| `updateOrderDriverLocation(orderId, location, speed)` | تحديث موقع السائق للتتبع |
| `setDeliveryId(orderId, deliveryId)`                  | تعيين deliveryId         |
| `createDriverDocument(driver)`                        | إنشاء مستند سائق         |
| `deleteDriverDocument(driverId)`                      | حذف مستند سائق           |
| `updateDriverLocation(driverId, lat, lng)`            | تحديث موقع السائق        |
| `updateDriverOnlineStatus(driverId, isOnline)`        | تحديث حالة الاتصال       |

### TrackingController

الـ Controller للتتبع اللحظي:

```
src/modules/tracking/tracking.controller.ts
```

#### endpoint:

```
POST /api/v1/tracking/update-location
```

---

## مراقبة الأخطاء

### Logs

النظام يسجل العمليات في Console:

```
🔥 [FIREBASE] Order document created for order 56
🔥 [FIREBASE] Order document updated for order 56 to SEARCHING
🔥 [FIREBASE] Driver document created for driver 57
🔥 [FIREBASE] Updated driver location for order 56
```

### الأخطاء المحتملة

| الخطأ               | الوصف                 |
| ------------------- | --------------------- |
| `PERMISSION_DENIED` | لا توجد صلاحية للوصول |
| `DATABASE_ERROR`    | خطأ في قاعدة البيانات |
| `NETWORK_ERROR`     | خطأ في الشبكة         |

---

## ملاحظات مهمة

1. **القراءة فقط**: لا يُنصح بتعديل البيانات مباشرة من Firebase Console، يجب أن يتم ذلك من خلال التطبيق.

2. **التزامن**: Firebase RTDB يوفر تزامن لحظي، التغييرات تظهر فوراً.

3. **الاحتفاظ بالبيانات**: يتم حذف مستندات الطلبات عند التسليم/الإلغاء/الرفض.

4. **تأخير الحذف**: حالة DELIVERED تنتظر 5 ثوانٍ قبل حذف المستند.

5. **الاحتفاظ بالسائقين**: مستندات السائقين تبقى بعد إنهاء الطلب (للتتبع).

6. **deliveryId**: يُعين عند ASSIGNED ويتحدث عند كل حالة توصيل.

7. **التوقيت**: جميع التواريخ مخزنة كـ Unix timestamp (milliseconds).

8. **routeHistory**: للحصول على الموقع الحالي للسائق، استخدم آخر عنصر في المصفوفة.

---

## Script للمزامنة

للمزامنة اليدوية بين قاعدة البيانات وFirebase:

```bash
npm run db:sync-drivers-firebase
```

الملف: `scripts/sync-drivers-to-firebase.ts`

---

## Flutter Client Integration (ON_THE_WAY)

لإظهار تتبع السائق للعميل على واجهة Flutter:

1. راقب حالة الطلب من:
   - `/orders/{orderId}/status`
2. عند وصول الحالة إلى `ON_THE_WAY` راقب:
   - `/orders/{orderId}/deliveryId`
3. بعد وجود `deliveryId` صالح، راقب موقع السائق من:
   - `/drivers/{deliveryId}/currentLat`
   - `/drivers/{deliveryId}/currentLng`
   - `/drivers/{deliveryId}/isOnline` (اختياري لحالة الاتصال)

### ملاحظات واجهة المستخدم

- يفضل إظهار بطاقة تتبع الخريطة فقط عندما الحالة `ON_THE_WAY`.
- استخدم Widget قابلة لإعادة الاستخدام داخل `core` حتى يمكن استخدامها في شاشات متعددة.
- إذا لم تتوفر إحداثيات السائق بعد، أخفِ الخريطة أو أظهر placeholder بسيط حتى تصل البيانات.

### Reusable Widget Recommendation

- في Flutter app: أنشئ Widget عامة في `lib/core/presentation/widgets/` مثل:
  - `LiveTrackingMapCard`
- اجعلها تستقبل:
  - `latitude`, `longitude`
  - `title`
  - `statusLabel` / `statusOnline` (اختياري)

---

## الأسئلة الشائعة (FAQ)

### س: هل يمكنني قراءة البيانات بدون مصادقة؟

### ج: نعم، القراءة مسموحة للجميع (مع Security Rules المحدثة).

### س: هل البيانات تبقى للأبد؟

### ج: لا، يتم حذف بيانات الطلب عند التسليم/الإلغاء/الرفض.

### س: كيف أعرف موقع السائق الحالي؟

### ج: استخدم آخر عنصر في `routeHistory`:

```javascript
const currentLocation = routeHistory[routeHistory.length - 1];
```

### س: هل يمكنني إضافة حقول إضافية؟

### ج: نعم، يمكن توسيع الهيكل حسب الحاجة.

### س: هل يمكن للسائق تحديث موقعه مباشرة؟

### ج: نعم، عبر endpoint `/tracking/update-location` أو مباشرة عبر Firebase مع Security Rules.
