# Orders API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة

نظام إدارة الطلبات المتقدم مع دعم كامل لـ:

- **Pipeline Architecture** للمعالجة متعددة المراحل
- **Role-based Access Control** لصلاحيات مختلفة
- **Real-time Notifications** عبر Firebase
- **Multiple Payment Strategies** (Cash, Wallet, Online)
- **Queue-based Processing** مع BullMQ
- **Comprehensive Status Management** مع انتقالات الحالات الصحيحة
- **Offers System** دعم العروض والخصومات (Many-to-Many)
- **Life Cycle Tracking** تتبع كامل لدورة حياة الطلب مع توقيتات دقيقة
- **Flexible Order Creation** إمكانية إنشاء طلبات بمنتجات فقط، عروض فقط، أو كليهما

## دورة حياة الطلب (Order Life Cycle)

يمر الكائن `Order` بدورة حياة منظمة تعتمد على الحالات (`OrderStatus`). كل حالة تؤدي إلى تغييرات محددة في بيانات الكائن:

1.  **التزامن الزماني (Timing)**: عند انتقال الطلب إلى حالة `CONFIRMED` من قبل التاجر، يتم تحديد `mealPreparationTime` و `deliveryTime`. وبناءً عليهما، يتم حساب `deliveryDeadline` (موعد التسليم المتوقع) تلقائياً كـ (الوقت الحالي + مجموع الوقتين).
2.  **إدارة المخزون**: يتم خصم المخزون عند الإنشاء (`PENDING`) وإعادته عند الإلغاء/الرفض. وفي حال استعادة الطلب، يتم الخصم مرة أخرى لضمان توفر المنتجات.
3.  **إسناد التوصيل**: تبدأ عملية البحث عن سائقين وإرسال الإشعارات فقط عندما يصبح الطلب `READY_FOR_PICKUP`.
4.  **الحماية (Restore Window)**: توجد "نافذة زمنية" مدتها 3 دقائق لاستعادة الطلبات الملغاة قبل أن تصبح الحالة نهائية وغير قابلة للتغيير.

---

## نظرة عامة على حالات الطلب

يمر الطلب عبر المراحل التالية مع التحقق من صلاحيات الانتقال:

```
PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP → ASSIGNED → PICKED_UP → ON_THE_WAY → DELIVERED
                 ↓                                              ↓                    ↓
           REJECTED (terminal)                           CANCELLED (terminal)    (terminal)
```

### حالات الطلب (OrderStatus)

| الحالة             | الوصف                          | English                                         |
| ------------------ | ------------------------------ | ----------------------------------------------- |
| `PENDING`          | الطلب وصل ولم يقبله التاجر بعد | Order received, waiting for merchant acceptance |
| `CONFIRMED`        | التاجر قبل الطلب               | Merchant confirmed the order                    |
| `PREPARING`        | التاجر بدأ التحضير             | Merchant started preparing the order            |
| `READY_FOR_PICKUP` | جاهز للاستلام                  | Order ready for pickup by delivery driver       |
| `ASSIGNED`         | تم تعيين سائق                  | Driver assigned to the order                    |
| `PICKED_UP`        | السائق استلم الطلب             | Driver picked up the order from merchant        |
| `ON_THE_WAY`       | السائق في الطريق               | Driver is on the way to delivery location       |
| `DELIVERED`        | تم التوصيل                     | Order successfully delivered (Terminal)         |
| `CANCELLED`        | ملغى                           | Order cancelled (Restorable within 3 mins)      |
| `REJECTED`         | مرفوض                          | Order rejected by merchant (Terminal)           |

### الصلاحيات وتصفية البيانات (Role-based Filtering)

يتم عرض البيانات بناءً على هوية المستخدم المرتبطة بالـ Token:

| الدور (Role) | الفلترة المطبقة (Filtering Logic)                                         | الوصف                                                       |
| :----------- | :------------------------------------------------------------------------ | :---------------------------------------------------------- |
| **ADMIN**    | لا توجد فلترة                                                             | يمكن للمدير رؤية جميع الطلبات في النظام.                    |
| **MERCHANT** | `ownerId = currentUserId`                                                 | يرى التاجر فقط الطلبات التي تنتمي لمتاجره.                  |
| **DELIVERY** | `status = 'READY_FOR_PICKUP'` <br> OR `applied/assigned to currentUserId` | يرى السائق الطلبات الجاهزة للاستلام أو التي استلمها بالفعل. |
| **CUSTOMER** | `customerId = currentUserId`                                              | يرى العميل طلباته الشخصية فقط.                              |

---

### انتقالات الحالات المسموحة

| من حالة          | إلى حالة                                                   |
| ---------------- | ---------------------------------------------------------- |
| PENDING          | CONFIRMED, REJECTED, CANCELLED                             |
| CONFIRMED        | PREPARING, CANCELLED                                       |
| PREPARING        | READY_FOR_PICKUP, CANCELLED                                |
| READY_FOR_PICKUP | ASSIGNED, CANCELLED                                        |
| ASSIGNED         | PICKED_UP, CANCELLED                                       |
| PICKED_UP        | ON_THE_WAY, DELIVERED                                      |
| ON_THE_WAY       | DELIVERED                                                  |
| DELIVERED        | (نهاية - لا انتقالات)                                      |
| CANCELLED        | PENDING, CONFIRMED (خلال 3 دقائق فقط - MERCHANT/ADMIN فقط) |
| REJECTED         | (نهاية - حالة نهائية)                                      |

### المراحل التفصيلية لكل حالة

#### 1️⃣ PENDING (في الانتظار) {#pending}

**الوصف:** الطلب الجديد وصل إلى النظام بانتظار قبول التاجر

**من يمكنه الوصول:**

- العميل (CUSTOMER): يمكنه عرض الطلب أو إلغاؤه
- التاجر (MERCHANT): يمكنه عرض الطلب أو تأكيده أو رفضه
- المدير (ADMIN): يمكنه عرض وتعديل أي طلب

**مثال Response عند استرجاع الطلب:**

```json
{
  "id": 123,
  "status": "PENDING",
  "deliveryDeadline": "2024-01-15T14:30:00.000Z",
  "items": [
    {
      "productName": "شاورما دجاج",
      "quantity": 2,
      "unitPrice": 7500,
      "totalPrice": 15000
    }
  ],
  "totalAmount": 19000,
  "createdAt": "2024-01-15T13:45:00.000Z"
}
```

**الإجراءات المتاحة:**

- تأكيد الطلب (MERCHANT/ADMIN) → CONFIRMED
- رفض الطلب (MERCHANT/ADMIN) → REJECTED
- إلغاء الطلب (CUSTOMER/MERCHANT/ADMIN) → CANCELLED

---

#### 2️⃣ CONFIRMED (تم التأكيد) {#confirmed}

**الوصف:** التاجر أكد الطلب وبدء التحضير

**من يمكنه الوصول:**

- التاجر (MERCHANT): يمكنه تحضير الطلب أو إلغاؤه
- المدير (ADMIN): يمكنه أي إجراء

**Request - تغيير إلى PREPARING:**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/preparing \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم بدء تحضير الطلب"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "PREPARING",
  "updatedAt": "2024-01-15T13:50:00.000Z",
  "items": [...],
  "totalAmount": 19000
}
```

**الإجراءات المتاحة:**

- بدء التحضير (MERCHANT/ADMIN) → PREPARING
- إلغاء الطلب (MERCHANT/ADMIN) → CANCELLED

---

#### 3️⃣ PREPARING (قيد التحضير) {#preparing}

**الوصف:** التاجر يحضر الطلب

**من يمكنه الوصول:**

- التاجر (MERCHANT): يمكنه إكمال التحضير أو إلغاؤه
- المدير (ADMIN): يمكنه أي إجراء

**Request - تغيير إلى READY_FOR_PICKUP:**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/ready-for-pickup \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "الطلب جاهز للاستلام"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "READY_FOR_PICKUP",
  "updatedAt": "2024-01-15T14:00:00.000Z",
  "items": [...],
  "totalAmount": 19000
}
```

**ملاحظة:** عند الوصول لهذه الحالة، يتم إرسال إشعارات تلقائية للسائقين المتاحين عبر `DeliveryAssignmentService`.

**الإجراءات المتاحة:**

- تحديد جاهز للاستلام (MERCHANT/ADMIN) → READY_FOR_PICKUP
- إلغاء الطلب (MERCHANT/ADMIN) → CANCELLED

---

#### 4️⃣ READY_FOR_PICKUP (جاهز للاستلام) {#ready-for-pickup}

**الوصف:** الطلب جاهز لاستلامه من قبل سائق التوصيل

**من يمكنه الوصول:**

- السائقين المتاحين (DELIVERY): يمكنهم عرض وطلب قبول التوصيل
- صاحب المطعم (MERCHANT): يمكنه العرض والإلغاء
- المدير (ADMIN): يمكنه أي إجراء

**Request - إرسال إشعارات التوصيل (إذا لم تكن مُرسلة تلقائياً):**

```bash
curl -X POST http://localhost:3000/api/v1/orders/123/send-delivery-notifications \
  -H "Authorization: Bearer <access_token>"
```

**Response:**

```json
{
  "message": "Delivery notifications sent successfully"
}
```

**Request - قبول التوصيل (من السائق):**

```bash
curl -X POST http://localhost:3000/api/v1/orders/123/accept-delivery \
  -H "Authorization: Bearer <access_token>"
```

**Response:**

```json
{
  "id": 1,
  "orderId": 123,
  "deliveryId": 5,
  "status": "ACCEPTED",
  "assignedAt": "2024-01-15T14:05:00.000Z",
  "acceptedAt": "2024-01-15T14:05:00.000Z"
}
```

**ملاحظة:** عند قبول التحويل، تتغير حالة الطلب إلى ASSIGNED تلقائياً

**الإجراءات المتاحة:**

- تعيين سائق (نظام/مسؤول) → ASSIGNED
- إلغاء الطلب (MERCHANT/ADMIN) → CANCELLED

---

#### 5️⃣ ASSIGNED (تم التعيين) {#assigned}

**الوصف:** تم تعيين سائق للطلب

**من يمكنه الوصول:**

- السائق المكلف (DELIVERY): يمكنه استلام الطلب أو رفضه
- المدير (ADMIN): يمكنه أي إجراء

**Request - تغيير إلى PICKED_UP (من السائق):**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/picked-up \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم استلام الطلب من المطعم"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "PICKED_UP",
  "deliveryAssignment": {
    "id": 1,
    "deliveryId": 5,
    "pickedAt": "2024-01-15T14:10:00.000Z",
    "status": "PICKED_UP"
  },
  "updatedAt": "2024-01-15T14:10:00.000Z"
}
```

**الإجراءات المتاحة:**

- استلام الطلب (DELIVERY/ADMIN) → PICKED_UP
- إلغاء الطلب (ADMIN) → CANCELLED

---

#### 6️⃣ PICKED_UP (تم الاستلام) {#picked-up}

**الوصف:** السائق استلم الطلب من المطعم وهو في طريقه

**من يمكنه الوصول:**

- السائق المكلف (DELIVERY): يمكنه تحديث حالة التوصيل
- المدير (ADMIN): يمكنه أي إجراء

**Request - تغيير إلى ON_THE_WAY (من السائق):**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/on-the-way \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "في الطريق إلى العميل"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "ON_THE_WAY",
  "deliveryAssignment": {
    "id": 1,
    "deliveryId": 5,
    "status": "ON_THE_WAY"
  },
  "updatedAt": "2024-01-15T14:20:00.000Z"
}
```

**أو يمكن القفز مباشرة إلى DELIVERED:**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/delivered \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم التسليم بنجاح"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "DELIVERED",
  "finalLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "deliveryAssignment": {
    "id": 1,
    "deliveryId": 5,
    "deliveredAt": "2024-01-15T14:30:00.000Z",
    "status": "DELIVERED"
  },
  "updatedAt": "2024-01-15T14:30:00.000Z"
}
```

**الإجراءات المتاحة:**

- في الطريق (DELIVERY/ADMIN) → ON_THE_WAY
- تم التسليم (DELIVERY/ADMIN) → DELIVERED

---

#### 7️⃣ ON_THE_WAY (في الطريق) {#on-the-way}

**الوصف:** السائق في الطريق إلى عنوان العميل

**من يمكنه الوصول:**

- السائق المكلف (DELIVERY): يمكنه تأكيد التسليم
- المدير (ADMIN): يمكنه أي إجراء

**Request - تغيير إلى DELIVERED (من السائق):**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/delivered \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم التسليم للعميل"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "DELIVERED",
  "finalLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "deliveryAssignment": {
    "id": 1,
    "deliveryId": 5,
    "deliveredAt": "2024-01-15T14:35:00.000Z",
    "status": "DELIVERED"
  },
  "updatedAt": "2024-01-15T14:35:00.000Z"
}
```

**ملاحظة مهمة:** عند الوصول لهذه الحالة:

- يتم تعيين `finalLocation` من `deliveryCoordinates`
- هذه حالة نهائية (terminal state)
- لا يمكن العودة منها لحالة أخرى

---

#### 8️⃣ DELIVERED (تم التسليم) {#delivered}

- السائق المكلف (DELIVERY): يمكنه تحديث حالة الطلب إلى DELIVERED
- المدير (ADMIN): يمكنه أي إجراء

**ملاحظة:** هذه حالة نهائية (Terminal State) للطلب الناجح، لا يمكن الانتقال منها لأي حالة أخرى.

**الحالات السابقة المسموحة:**

- PICKED_UP (يمكن القفز مباشرة)
- ON_THE_WAY

---

### Request لتغيير الحالة إلى DELIVERED

**من PICKED_UP (القفز مباشرة):**

- **URL:** `/orders/:id/delivered`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

**URL Parameters:**

| المعامل | النوع  | مطلوب | الوصف     |
| ------- | ------ | ----- | --------- |
| `id`    | number | نعم   | رقم الطلب |

**Payload (Request Body):**

| الحقل               | النوع  | مطلوب   | الوصف                  |
| ------------------- | ------ | ------- | ---------------------- |
| `reason`            | string | لا      | سبب التسليم            |
| `finalLocation`     | object | **نعم** | الموقع النهائي للتسليم |
| `finalLocation.lat` | number | نعم     | خط العرض               |
| `finalLocation.lng` | number | نعم     | خط الطول               |

```json
{
  "reason": "تم التسليم بنجاح للعميل",
  "finalLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  }
}
```

**ملاحظة:** إذا لم يتم إرسال `finalLocation` في الـ Payload، سيتم استخدام `deliveryCoordinates` كاحتياطي

---

### curl Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/delivered \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "تم التسليم بنجاح للعميل",
    "finalLocation": {
      "lat": 33.5138,
      "lng": 36.2765
    }
  }'
```

---

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "customerId": 1,
  "ownerId": 1,
  "paymentMethod": "CASH",
  "status": "DELIVERED",
  "deliveryDeadline": "2024-01-15T14:30:00.000Z",
  "mealPreparationTime": 15,
  "deliveryTime": 30,
  "deliveryCoordinates": {
    "latitude": 33.5138,
    "longitude": 36.2765,
    "address": "Al-Hamra Street, Building 5",
    "landmark": "Next to the park",
    "specialInstructions": "Call upon arrival"
  },
  "finalLocation": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "items": [
    {
      "id": 1,
      "productId": 10,
      "productName": "شاورما دجاج",
      "quantity": 2,
      "originalUnitPrice": 7000,
      "unitPrice": 7500,
      "totalPrice": 15000
    },
    {
      "id": 2,
      "productId": 15,
      "productName": "عصير برتقال",
      "quantity": 1,
      "originalUnitPrice": 2500,
      "unitPrice": 2500,
      "totalPrice": 2500
    }
  ],
  "priceBeforeDiscount": 20000,
  "discountAmount": 3000,
  "priceAfterProductDiscount": 17500,
  "tipAmount": 500,
  "platformCommission": 1450,
  "ownerRevenue": 13050,
  "deliveryFee": 1500,
  "totalAmount": 19000,
  "totalCommissionAmount": 1450,
  "currencyCode": "SAR",
  "exchangeRate": 1,
  "deliveryAssignment": {
    "id": 1,
    "orderId": 123,
    "deliveryId": 5,
    "assignedAt": "2024-01-15T14:05:00.000Z",
    "acceptedAt": "2024-01-15T14:05:00.000Z",
    "pickedAt": "2024-01-15T14:10:00.000Z",
    "deliveredAt": "2024-01-15T14:35:00.000Z",
    "groupIndex": 0,
    "notifiedAt": "2024-01-15T14:00:00.000Z",
    "status": "DELIVERED"
  },
  "createdAt": "2024-01-15T13:45:00.000Z",
  "updatedAt": "2024-01-15T14:35:00.000Z"
}
```

---

### 🗺️ آلية تعيين finalLocation

عند تغيير حالة الطلب إلى `DELIVERED`، يمكن تعيين `finalLocation` بطريقتين:

**الأولوية الأولى: من الـ Payload (إذا تم إرساله)**

```typescript
// إذا أرسل السائق finalLocation في الـ Payload
if (context.finalLocation) {
  order.finalLocation = context.finalLocation;
}
```

**الاحتياطي: من deliveryCoordinates (إذا لم يُرسل في الـ Payload)**

```typescript
// otherwise use deliveryCoordinates as fallback
else if (order.deliveryCoordinates) {
  order.finalLocation = {
    lat: order.deliveryCoordinates.latitude,
    lng: order.deliveryCoordinates.longitude,
  };
}
```

**الجدول الزمني للتعيين:**

| الخطوة | الإجراء                                                  |
| ------ | -------------------------------------------------------- |
| 1      | العميل يُنشئ الطلب مع `deliveryCoordinates`              |
| 2      | يتم تخزين `deliveryCoordinates` في قاعدة البيانات        |
| 3      | السائق يُسلّم الطلب ويرسل `finalLocation` في الـ Payload |
| 4      | النظام يُعيّن `finalLocation`                            |

---

### 📊 مقارنة deliveryCoordinates vs finalLocation

| الحقل                 | المصدر                      | الوصف                  |
| --------------------- | --------------------------- | ---------------------- |
| `deliveryCoordinates` | من العميل (عند إنشاء الطلب) | الموقع المطلوب للتسليم |
| `finalLocation`       | من السائق (عند التسليم)     | الموقع الفعلي للتسليم  |

**لماذا قد يختلفان؟**

- قد يصل السائق إلى موقع مختلف قليلاً عن الموقع المطلوب
- قد يختار العميل موقعاً مختلفاً عند وصول السائق

---

### Response (Error - 400 Bad Request)

إذا كان الانتقال غير صالح (مثلاً من PENDING):

```json
{
  "message": "Cannot transition from \"PENDING\" to \"DELIVERED\". Allowed transitions: CONFIRMED, REJECTED, CANCELLED",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

### Response (Error - 403 Forbidden)

إذا لم يكن لدى المستخدم صلاحية:

```json
{
  "message": "Role \"MERCHANT\" cannot change status to \"DELIVERED\"",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

### Response (Error - 404 Not Found)

إذا كان الطلب غير موجود:

```json
{
  "message": "Order with ID 123 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

### Response (Error - 400 Bad Request - تم التسليم مسبقاً)

```json
{
  "message": "Order already delivered",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

### 💡 ملاحظات مهمة

1. **finalLocation**: يُرسَل في الـ Payload ويجب تحديده عند التسليم
2. **إذا لم يُرسل**: يتم استخدام `deliveryCoordinates` كاحتياطي
3. **هذه حالة نهائية**: لا يمكن الانتقال منها إلى أي حالة أخرى
4. **deliveryAssignment.deliveredAt**: يتم تعيينه أيضاً مع وقت التسليم الفعلي
5. **الصلاحيات**: فقط السائق المكلف أو ADMIN يمكنهم تنفيذ هذا الإجراء

---

### 📊 مقارنة deliveryCoordinates vs finalLocation

| الحقل                 | الوصف                          | متى يُعين                      |
| --------------------- | ------------------------------ | ------------------------------ |
| `deliveryCoordinates` | موقع التسليم المطلوب من العميل | عند إنشاء الطلب                |
| `finalLocation`       | الموقع الفعلي للتسليم          | عند تغيير الحالة إلى DELIVERED |

---

#### 9️⃣ CANCELLED (ملغى) {#cancelled}

**الوصف:** تم إلغاء الطلب

**الحالات التي يمكن الإلغاء منها:**

- PENDING (أي مستخدم بصلاحية)
- CONFIRMED (MERCHANT/ADMIN)
- PREPARING (MERCHANT/ADMIN)
- READY_FOR_PICKUP (MERCHANT/ADMIN)
- ASSIGNED (ADMIN فقط)

**Request - إلغاء الطلب (من العميل):**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/cancel \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تغيير في الخطط"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "CANCELLED",
  "updatedAt": "2024-01-15T13:55:00.000Z"
}
```

**ملاحظة:** عند الإلغاء، يتم إعادة المخزون المستهلك للمنتجات تلقائياً عبر `UpdateOrderPipeline`.

---

#### 🔟 REJECTED (مرفوض) {#rejected}

**الوصف:** رفض المطعم الطلب

**الحالة:** يمكن الرفض فقط من PENDING

**Request - رفض الطلب (من صاحب المطعم):**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/reject \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "المنتج غير متوفر حالياً"}'
```

**Response:**

```json
{
  "id": 123,
  "status": "REJECTED",
  "updatedAt": "2024-01-15T13:50:00.000Z"
}
```

**ملاحظة:** عند الرفض، يتم إعادة المخزون المستهلك للمنتجات تلقائياً عبر `UpdateOrderPipeline`.

---

#### 🔄 استعادة طلب ملغى (Restore Cancelled Order)

**الوصف:** السماح باستعادة طلب تم إلغاؤه خلال 3 دقائق من الإلغاء

**الشروط:**

- خلال 3 دقائق فقط من وقت الإلغاء
- فقط ADMIN أو MERCHANT (صاحب المطعم)
- إذا كان هناك مخزون للمنتجات يتم خصمه مرة أخرى

**Request - استعادة إلى PENDING:**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/pending \
  -H "Authorization: Bearer <access_token>"
```

**أو استعادة إلى CONFIRMED:**

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/confirmed \
  -H "Authorization: Bearer <access_token>"
```

**Response (Success - 200 OK):**

```json
{
  "id": 123,
  "status": "PENDING",
  "previousStatus": null,
  "cancelledAt": null,
  "updatedAt": "2024-01-15T14:00:00.000Z"
}
```

**Response (Error - 400 Bad Request - انتهت المدة):**

```json
{
  "message": "Cannot restore order - the 3-minute window has expired",
  "error": "Bad Request",
  "statusCode": 400
}
```

**Response (Error - 400 Bad Request - مخزون غير كافٍ):**

```json
{
  "message": "Cannot restore order - insufficient stock for some products",
  "error": "Bad Request",
  "statusCode": 400
}
```

**Response (Error - 403 Forbidden):**

```json
{
  "message": "You do not have permission to restore this order",
  "error": "Forbidden",
  "statusCode": 403
}
```

**ملاحظات:**

- عند الاستعادة، يتم خصم المخزون مرة أخرى
- يتم مسح حقول `previousStatus` و `cancelledAt` بعد الاستعادة
- إذا فشل خصم المخزون، لا يتم استعادة الطلب

---

### ملخص مسارات تدفق الطلب

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         مسار الطلب الناجح                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   CUSTOMER                    MERCHANT                   DELIVERY           │
│     │                           │                           │                │
│     │──── POST /orders ───────►│                           │                │
│     │◄──── 201 Created ────────│                           │                │
│     │     (PENDING)            │                           │                │
│     │                           │                           │                │
│     │                           │──── PATCH /confirm ─────►│                │
│     │                           │◄──── 200 OK ─────────────│                │
│     │                           │     (CONFIRMED)          │                │
│     │                           │                           │                │
│     │                           │──── PATCH /preparing ───►│                │
│     │                           │◄──── 200 OK ─────────────│                │
│     │                           │     (PREPARING)          │                │
│     │                           │                           │                │
│     │                           │──── PATCH /ready───────►│                │
│     │                           │◄──── 200 OK ─────────────│                │
│     │                           │  (READY_FOR_PICKUP)      │                │
│     │                           │                           │                │
│     │                           │    (إشعارات تلقائية)     │                │
│     │                           │                           │                │
│     │                           │                     ◄───┤──── POST /accept
│     │                           │                     ────►│ 200 OK         │
│     │                           │                     (ASSIGNED)            │
│     │                           │                           │                │
│     │                           │                           │──── PATCH /picked-up
│     │                           │                           │◄──── 200 OK    │
│     │                           │                           │  (PICKED_UP)  │
│     │                           │                           │                │
│     │                           │                           │──── PATCH /on-the-way
│     │                           │                           │◄──── 200 OK    │
│     │                           │                           │(ON_THE_WAY)   │
│     │                           │                           │                │
│     │                           │                           │──── PATCH /delivered
│     │                           │                           │◄──── 200 OK    │
│     │                           │                           │ (DELIVERED)   │
│     │                           │                           │                │
│     ▼                           ▼                           ▼                │
│  (DELIVERED)                (DELIVERED)                 (DELIVERED)        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                       مسار إلغاء الطلب                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   CUSTOMER                         MERCHANT                                  │
│     │                                │                                       │
│     │──── PATCH /cancel ────────────►│                                       │
│     │◄──── 200 OK ───────────────────│                                       │
│     │     (CANCELLED)                │                                       │
│     │                                │                                       │
│     │         (RESTORE STOCK)        │                                       │
│     │                                │                                       │
└─────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                       مسار رفض الطلب                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         MERCHANT                                            │
│                           │                                                 │
│     PENDING ─────────────►│──── PATCH /reject ────► REJECTED               │
│                           │     (RESTORE STOCK)                             │
│                           │                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. الصلاحيات حسب الدور

### أدوار المستخدمين (UserRole)

| الدور          | الوصف           |
| -------------- | --------------- |
| `CUSTOMER`     | العميل          |
| `MERCHANT`     | صاحب المتجر     |
| `DELIVERY`     | سائق التوصيل    |
| `ADMIN`        | مدير النظام     |
| `OFFICE_OWNER` | صاحب مكتب توصيل |
| `SUPPORT`      | الدعم الفني     |

### صلاحيات تعديل حالة الطلب حسب الدور

| الدور          | الحالات المسموح بتعديلها                                                                    |
| -------------- | ------------------------------------------------------------------------------------------- |
| `CUSTOMER`     | CANCELLED (فقط للطلبات PENDING)                                                             |
| `MERCHANT`     | CONFIRMED, PREPARING, READY_FOR_PICKUP, REJECTED, CANCELLED, PENDING, CONFIRMED (للاستعادة) |
| `DELIVERY`     | PICKED_UP, ON_THE_WAY, DELIVERED                                                            |
| `ADMIN`        | جميع الحالات                                                                                |
| `OFFICE_OWNER` | لا يوجد صلاحيات                                                                             |
| `SUPPORT`      | لا يوجد صلاحيات                                                                             |

### صلاحيات عرض الطلبات

| الدور      | الوصول                      |
| ---------- | --------------------------- |
| `ADMIN`    | يرى جميع الطلبات            |
| `MERCHANT` | يرى فقط طلبات مطاعمه الخاصة |
| `CUSTOMER` | يرى فقط طلباته الشخصية      |
| `DELIVERY` | يرى فقط الطلبات المكلفة له  |

---

## 3. إنشاء طلب جديد

إنشاء طلب جديد مع التحقق من المخزون وحساب الأسعار.

- **URL:** `/orders`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Payload (Request Body)

| الحقل                                     | النوع  | مطلوب  | الوصف                                                           |
| ----------------------------------------- | ------ | ------ | --------------------------------------------------------------- |
| `ownerId`                                 | number | نعم    | معرف صاحب المطعم (التاجر)                                       |
| `items`                                   | array  | **لا** | قائمة المنتجات (اختياري - يمكن إنشاء طلب بعروض فقط بدون منتجات) |
| `items[].productId`                       | number | نعم    | معرف المنتج                                                     |
| `items[].quantity`                        | number | نعم    | الكمية (يجب أن تكون ≥ 1)                                        |
| `offers`                                  | array  | **لا** | قائمة العروض مع الكميات المطلوبة                                |
| `offers[].offerId`                        | number | نعم    | معرف العرض                                                      |
| `offers[].quantity`                       | number | نعم    | الكمية المطلوبة من هذا العرض (≥ 1)                              |
| `deliveryCoordinates`                     | object | نعم    | إحداثيات التوصيل                                                |
| `deliveryCoordinates.latitude`            | number | نعم    | خط العرض                                                        |
| `deliveryCoordinates.longitude`           | number | نعم    | خط الطول                                                        |
| `deliveryCoordinates.address`             | string | لا     | العنوان التفصيلي                                                |
| `deliveryCoordinates.landmark`            | string | لا     | علامة مميزة                                                     |
| `deliveryCoordinates.specialInstructions` | string | لا     | تعليمات خاصة                                                    |
| `deliveryFee`                             | number | لا     | رسوم التوصيل                                                    |
| `tipAmount`                               | number | لا     | مبلغ البقشيش                                                    |
| `cityId`                                  | number | لا     | معرف المدينة                                                    |
| `paymentMethod`                           | string | نعم    | طريقة الدفع (CASH, WALLET, ONLINE)                              |

> **ملاحظة مهمة:** يجب توفير `items` أو `offers` أو كليهما. لا يمكن أن يكون كلاهما فارغين.

### ملاحظة حول العروض (offers)

عند إضافة عرض، يتم أخذ **جميع المنتجات** الموجودة في العرض بالكمية المحددة. مثال:

- إذا كان العرض يحتوي على [منتج A، منتج B، منتج C]
- وأضفت `{ offerId: 1, quantity: 2 }`
- سيتم إضافة منتج A×2، منتج B×2، منتج C×2 للطلب

### Request Example

#### مثال 1: طلب بمنتجات وعروض

```json
{
  "ownerId": 1,
  "items": [
    {
      "productId": 10,
      "quantity": 2
    },
    {
      "productId": 15,
      "quantity": 1
    }
  ],
  "offers": [
    { "offerId": 1, "quantity": 2 },
    { "offerId": 3, "quantity": 1 }
  ],
  "deliveryCoordinates": {
    "latitude": 33.5138,
    "longitude": 36.2765,
    "address": "Al-Hamra Street, Building 5",
    "landmark": "Next to the park",
    "specialInstructions": "Call upon arrival"
  },
  "deliveryFee": 1500,
  "tipAmount": 500,
  "cityId": 1,
  "paymentMethod": "CASH"
}
```

#### مثال 2: طلب بعروض فقط (بدون منتجات)

```json
{
  "ownerId": 1,
  "offers": [
    { "offerId": 1, "quantity": 1 },
    { "offerId": 2, "quantity": 2 }
  ],
  "deliveryCoordinates": {
    "latitude": 33.5138,
    "longitude": 36.2765,
    "address": "Al-Hamra Street, Building 5"
  },
  "deliveryFee": 0,
  "paymentMethod": "ONLINE"
}
```

#### مثال 3: طلب بمنتجات فقط (بدون عروض)

```json
{
  "ownerId": 1,
  "items": [
    {
      "productId": 10,
      "quantity": 1
    }
  ],
  "deliveryCoordinates": {
    "latitude": 33.5138,
    "longitude": 36.2765,
    "address": "Al-Hamra Street"
  },
  "deliveryFee": 1500,
  "paymentMethod": "WALLET"
}
```

### Response (Success - 201 Created)

```json
{
  "order": {
    "id": 123,
    "customerId": 1,
    "customer": {
      "id": 1,
      "firstName": "أحمد",
      "lastName": "محمد",
      "phone": "+963912345678",
      "email": "ahmed@example.com"
    },
    "ownerId": 1,
    "owner": {
      "id": 1,
      "firstName": "محمد",
      "lastName": "علي",
      "phone": "+963911111111"
    },
    "paymentMethod": "CASH",
    "status": "PENDING",
    "deliveryDeadline": "2024-01-15T14:30:00.000Z",
    "mealPreparationTime": 15,
    "deliveryTime": 30,
    "deliveryCoordinates": {
      "latitude": 33.5138,
      "longitude": 36.2765,
      "address": "Al-Hamra Street, Building 5"
    },
    "finalLocation": null,
    "items": [
      {
        "id": 1,
        "productId": 10,
        "productName": "شاورما دجاج",
        "quantity": 2,
        "unitPrice": 7500,
        "totalPrice": 15000,
        "product": {
          "id": 10,
          "name": "شاورما دجاج",
          "images": [
            {
              "id": 1,
              "url": "products/10/image.webp",
              "mobileUrl": "products/10/image_mobile.webp",
              "thumbnailUrl": "products/10/image_thumb.webp",
              "isMain": true
            }
          ]
        }
      }
    ],
    "offers": [
      {
        "id": 1,
        "name": "خصم 10%",
        "discountType": "PERCENTAGE",
        "discountValue": 10
      }
    ],
    "priceBeforeDiscount": 20000,
    "discountAmount": 3000,
    "priceAfterProductDiscount": 17500,
    "tipAmount": 500,
    "platformCommission": 1450,
    "ownerRevenue": 13050,
    "deliveryFee": 1500,
    "totalAmount": 19000,
    "totalCommissionAmount": 1450,
    "currencyCode": "SAR",
    "exchangeRate": 1,
    "createdAt": "2024-01-15T13:45:00.000Z",
    "updatedAt": "2024-01-15T13:45:00.000Z"
  }
}
```

### Response (Error - 400 Bad Request)

#### رسائل الخطأ الشائعة

| الرمز | الرسالة                               | الوصف                          |
| ----- | ------------------------------------- | ------------------------------ |
| 4024  | معرف التاجر مطلوب                     | يجب تحديد ownerId              |
| 4022  | الطلب يجب أن يحتوي على منتجات أو عروض | يجب إضافة items أو offers      |
| 4011  | معرف المنتج غير صالح                  | productId غير صالح             |
| 4023  | الكمية يجب أن تكون أكبر من صفر        | quantity < 1                   |
| 4016  | معرف العرض غير صالح                   | offerId غير صالح               |
| 4031  | إحداثيات التوصيل مطلوبة               | يجب تحديد latitude و longitude |
| 4051  | طريقة الدفع مطلوبة                    | يجب تحديد paymentMethod        |
| 4032  | رسوم التوصيل يجب أن تكون قيمة موجبة   | deliveryFee < 0                |
| 4033  | الإكرامية يجب أن تكون قيمة موجبة      | tipAmount < 0                  |

#### رسائل خطأ المنتجات

| الرمز | الرسالة                                                          | الوصف              |
| ----- | ---------------------------------------------------------------- | ------------------ |
| 4012  | المنتج غير موجود (معرف: X)                                       | المنتج غير موجود   |
| 4015  | المنتج "X" (معرف: Y) لا ينتمي لهذا التاجر                        | المنتج من تاجر آخر |
| 4013  | المنتج "X" غير متاح حالياً                                       | المنتج غير متاح    |
| 4014  | الكمية المطلوبة من المنتج "X" غير متوفرة. المتوفر: Y، المطلوب: Z | مخزون غير كافٍ     |

#### رسائل خطأ العروض

| الرمز | الرسالة                                      | الوصف                  |
| ----- | -------------------------------------------- | ---------------------- |
| 4017  | العروض غير موجودة: [X, Y]                    | العرض غير موجود        |
| 4018  | العرض "X" غير نشط حالياً                     | العرض غير نشط          |
| 4019  | العرض "X" لا ينتمي لهذا التاجر               | العرض من تاجر آخر      |
| 4020  | المنتج "X" في العرض "Y" لا ينتمي لهذا التاجر | منتج العرض من تاجر آخر |

#### أمثلة على رسائل الخطأ

```json
{
  "message": "معرف التاجر مطلوب",
  "error": "Bad Request",
  "statusCode": 400
}
```

```json
{
  "message": "المنتج \"شاورما دجاج\" (معرف: 10) لا ينتمي لهذا التاجر",
  "error": "Bad Request",
  "statusCode": 400
}
```

```json
{
  "message": "الكمية المطلوبة من المنتج \"كبسة دجاج\" غير متوفرة. المتوفر: 3، المطلوب: 5",
  "error": "Bad Request",
  "statusCode": 400
}
```

```json
{
  "message": "العرض \"خصم الصيف\" لا ينتمي لهذا التاجر",
  "error": "Bad Request",
  "statusCode": 400
}
```

```json
{
  "message": "إحداثيات التوصيل مطلوبة",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

## 4. استرجاع جميع الطلبات

استرجاع قائمة الطلبات مع دعم الفلترة والترقيم.

- **URL:** `/orders`
- **Method:** `GET`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Query Parameters

| المعامل      | النوع  | مطلوب | الوصف                                       |
| ------------ | ------ | ----- | ------------------------------------------- |
| `page`       | number | لا    | رقم الصفحة (الافتراضي: 1)                   |
| `limit`      | number | لا    | عدد العناصر في الصفحة (الافتراضي: 10)       |
| `search`     | string | لا    | البحث برقم الطلب أو اسم العميل              |
| `status`     | string | لا    | فلترة حسب الحالة (PENDING, CONFIRMED, etc.) |
| `ownerId`    | number | لا    | فلترة حسب صاحب المطعم (للمدير)              |
| `categoryId` | number | لا    | فلترة حسب قسم المنتجات                      |

### Request Example

```bash
curl -X GET "http://localhost:3000/api/v1/orders?page=1&limit=10&status=PENDING" \
  -H "Authorization: Bearer <access_token>"
```

### Response (Success - 200 OK)

```json
{
  "data": [
    {
      "id": 123,
      "customerId": 1,
      "customer": {
        "id": 1,
        "firstName": "أحمد",
        "lastName": "محمد",
        "phone": "+963912345678"
      },
      "ownerId": 1,
      "owner": {
        "id": 1,
        "firstName": "محمد",
        "lastName": "علي"
      },
      "paymentMethod": "CASH",
      "status": "PENDING",
      "deliveryDeadline": "2024-01-15T14:30:00.000Z",
      "mealPreparationTime": 15,
      "deliveryTime": 30,
      "deliveryCoordinates": {
        "latitude": 33.5138,
        "longitude": 36.2765,
        "address": "Al-Hamra Street"
      },
      "finalLocation": null,
      "items": [
        {
          "id": 1,
          "productId": 10,
          "productName": "شاورما دجاج",
          "quantity": 2,
          "unitPrice": 7500,
          "totalPrice": 15000
        }
      ],
      "offers": [],
    "priceBeforeDiscount": 20000,
    "discountAmount": 3000,
    "priceAfterProductDiscount": 17500,
    "tipAmount": 500,
    "platformCommission": 1450,
    "ownerRevenue": 13050,
    "deliveryFee": 1500,
    "totalAmount": 19000,
    "totalCommissionAmount": 1450,
    "currencyCode": "SAR",
    "exchangeRate": 1,
    "createdAt": "2024-01-15T13:45:00.000Z",
    "updatedAt": "2024-01-15T13:45:00.000Z"
  }
}
  ],
  "total": 1,
  "page": 1,
  "limit": 10
}
```

### Response (Error - 401 Unauthorized)

```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```

---

## 5. استرجاع طلب واحد

استرجاع تفاصيل طلب محدد بواسطة رقم الطلب مع جميع تفاصيل المنتجات والعروض.

- **URL:** `/orders/:id`
- **Method:** `GET`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### URL Parameters

| المعامل | النوع  | الوصف     |
| ------- | ------ | --------- |
| `id`    | number | رقم الطلب |

### Request Example

```bash
curl -X GET http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer <access_token>"
```

### Response (Success - 200 OK)

```json
{
  "id": 12,
  "customerId": 52,
  "customer": {
    "id": 52,
    "firstName": "Sama",
    "lastName": "Customer",
    "phone": "+963970000001",
    "email": "samacustomer@jeeb.com",
    "address": "Damascus, Syria"
  },
  "ownerId": 30114,
  "owner": {
    "id": 30114,
    "firstName": "haidar nasser",
    "lastName": "habib",
    "phone": "646464664",
    "email": "khderhabib2016@gmail.com",
    "address": "address"
  },
  "paymentMethod": "CASH",
  "status": "CANCELLED",
  "deliveryDeadline": "2026-03-23T06:17:27.183Z",
  "deliveryCoordinates": {
    "address": "123 Customer Street, Damascus, Syria",
    "landmark": "Near the big mosque",
    "latitude": 33.5138,
    "longitude": 36.2765,
    "specialInstructions": "Please call when arrive"
  },
  "finalLocation": null,
  "items": [
    {
      "id": 11,
      "productId": 5112,
      "product": {
        "id": 5112,
        "merchantId": 30114,
        "categoryId": 10,
        "name": "test 2",
        "shortDescription": "delicious food item",
        "description": "food description",
        "personCount": 2,
        "price": 100,
        "discount": 10,
        "discountType": "PERCENTAGE",
        "isAvailable": true,
        "hasStock": true,
        "stockQuantity": 3,
        "isExternal": false,
        "externalProvider": null,
        "externalId": null,
        "externalMetadata": null,
        "commissionRate": 5,
        "commissionConfirmed": true,
        "images": [
          {
            "id": 1,
            "url": "https://storage.example.com/images/product1.jpg",
            "mobileUrl": "https://storage.example.com/mobile/product1.jpg",
            "thumbnailUrl": "https://storage.example.com/thumb/product1.jpg",
            "isMain": true
          }
        ],
        "createdAt": "2026-03-23T05:09:21.379Z",
        "updatedAt": "2026-03-23T09:23:24.647Z"
      },
      "quantity": 2,
      "originalUnitPrice": 100,
      "unitPrice": 95,
      "totalPrice": 190,
      "commissionRate": 5,
      "commissionAmount": 5,
      "totalCommissionAmount": 10,
      "productDiscountValue": 10,
      "totalProductDiscountValue": 20
    }
  ],
  "offers": [
    {
      "id": 29,
      "name": "عرض الصيف الخاص",
      "description": "خصم كبير على المنتجات المختارة",
      "discountType": "PERCENTAGE",
      "discountValue": 25,
      "isActive": true,
      "merchantId": 30114,
      "createdAt": "2026-03-23T05:11:49.436Z",
      "updatedAt": "2026-03-23T05:11:49.436Z",
      "products": [
        {
          "id": 16,
          "productId": 5112,
          "product": {
            "id": 5112,
            "merchantId": 30114,
            "categoryId": 10,
            "name": "test 2",
            "shortDescription": "delicious food item",
            "description": "food description",
            "personCount": 2,
            "price": 100,
            "discount": 10,
            "discountType": "PERCENTAGE",
            "isAvailable": true,
            "hasStock": true,
            "stockQuantity": 3,
            "isExternal": false,
            "externalProvider": null,
            "externalId": null,
            "externalMetadata": null,
            "commissionRate": 5,
            "commissionConfirmed": true,
            "images": [
              {
                "id": 1,
                "url": "https://storage.example.com/images/product1.jpg",
                "mobileUrl": "https://storage.example.com/mobile/product1.jpg",
                "thumbnailUrl": "https://storage.example.com/thumb/product1.jpg",
                "isMain": true
              }
            ],
            "createdAt": "2026-03-23T05:09:21.379Z",
            "updatedAt": "2026-03-23T09:23:24.647Z"
          },
          "quantity": 2,
          "originalUnitPrice": 100,
          "discount": 10,
          "discountType": "PERCENTAGE",
          "unitPrice": 95,
          "totalPrice": 190,
          "commissionRate": 5,
          "commissionAmount": 5,
          "productDiscountValue": 10
        }
      ],
      "totalQuantity": 2,
      "productInternalQuantity": 2,
      "subtotal": 400,
      "productDiscount": 40,
      "offerDiscount": 95,
      "total": 285,
      "commissionRate": 5,
      "totalCommissionAmount": 20,
      "totalProductDiscountValue": 40,
      "images": []
    }
  ],
  "itemsTotal": 190,
  "offersTotal": 190,
  "subtotal": 380,
  "priceBeforeDiscount": 420,
  "discountAmount": 47,
  "priceAfterProductDiscount": 420,
  "productDiscount": 40,
  "offerDiscount": 47,
  "tipAmount": 0,
  "platformCommission": 30,
  "ownerRevenue": 350,
  "deliveryFee": 0,
  "totalAmount": 380,
  "totalCommissionAmount": 30,
  "currencyCode": "SAR",
  "createdAt": "2026-03-23T05:32:27.182Z",
  "updatedAt": "2026-03-23T06:32:27.263Z"
}
```

### تفاصيل هيكل الاستجابة

#### Items (عناصر الطلب)

كل عنصر في الطلب يحتوي على:

| الحقل                       | النوع  | الوصف                                               |
| --------------------------- | ------ | --------------------------------------------------- |
| `id`                        | number | معرف عنصر الطلب                                     |
| `productId`                 | number | معرف المنتج                                         |
| `product`                   | object | تفاصيل كاملة للمنتج                                 |
| `quantity`                  | number | الكمية المطلوبة                                     |
| `originalUnitPrice`         | number | السعر الأصلي قبل أي خصومات                          |
| `unitPrice`                 | number | السعر بعد خصم المنتج والعمولة                       |
| `totalPrice`                | number | السعر الإجمالي للكمية المطلوبة                      |
| `commissionRate`            | number | نسبة العمولة                                        |
| `commissionAmount`          | number | مبلغ العمولة للوحدة                                 |
| `totalCommissionAmount`     | number | إجمالي العمولة = commissionAmount × quantity        |
| `productDiscountValue`      | number | قيمة خصم المنتج للوحدة                              |
| `totalProductDiscountValue` | number | إجمالي خصم المنتج = productDiscountValue × quantity |

#### Product (تفاصيل المنتج الكاملة)

| الحقل                 | النوع          | الوصف                        |
| --------------------- | -------------- | ---------------------------- |
| `id`                  | number         | معرف المنتج                  |
| `merchantId`          | number \| null | معرف التاجر                  |
| `categoryId`          | number \| null | معرف القسم                   |
| `category`            | object         | تفاصيل القسم                 |
| `name`                | string         | اسم المنتج                   |
| `shortDescription`    | string \| null | وصف مختصر                    |
| `description`         | string \| null | الوصف الكامل                 |
| `personCount`         | number \| null | عدد الأشخاص                  |
| `price`               | number         | السعر الأصلي                 |
| `discount`            | number \| null | قيمة الخصم على المنتج        |
| `discountType`        | string \| null | نوع الخصم (PERCENTAGE/FIXED) |
| `isAvailable`         | boolean        | هل المنتج متاح               |
| `hasStock`            | boolean        | هل المنتج له مخزون           |
| `stockQuantity`       | number \| null | كمية المخزون                 |
| `isExternal`          | boolean        | هل منتج خارجي                |
| `externalProvider`    | string \| null | المزود الخارجي               |
| `externalId`          | string \| null | معرف المنتج الخارجي          |
| `externalMetadata`    | object \| null | بيانات إضافية خارجية         |
| `commissionRate`      | number \| null | نسبة العمولة                 |
| `commissionConfirmed` | boolean        | هل تم تأكيد العمولة          |
| `images`              | array          | مصفوفة صور المنتج            |
| `createdAt`           | Date           | تاريخ الإنشاء                |
| `updatedAt`           | Date           | تاريخ التحديث                |

#### Offers (العروض)

| الحقل                       | النوع          | الوصف                             |
| --------------------------- | -------------- | --------------------------------- |
| `id`                        | number         | معرف العرض                        |
| `name`                      | string         | اسم العرض                         |
| `description`               | string \| null | وصف العرض                         |
| `discountType`              | string \| null | نوع الخصم (PERCENTAGE/FIXED)      |
| `discountValue`             | number \| null | قيمة الخصم                        |
| `isActive`                  | boolean        | هل العرض نشط                      |
| `merchantId`                | number \| null | معرف التاجر                       |
| `createdAt`                 | Date           | تاريخ الإنشاء                     |
| `updatedAt`                 | Date           | تاريخ التحديث                     |
| `products`                  | array          | المنتجات المشمولة في العرض        |
| `totalQuantity`             | number         | إجمالي الكمية من هذا العرض        |
| `productInternalQuantity`   | number         | مجموع الكميات الداخلية للمنتجات   |
| `subtotal`                  | number         | المجموع قبل خصم العرض             |
| `productDiscount`           | number         | إجمالي خصومات المنتجات داخل العرض |
| `offerDiscount`             | number         | قيمة خصم العرض نفسه               |
| `total`                     | number         | المجموع النهائي لهذا العرض        |
| `commissionRate`            | number         | نسبة العمولة                      |
| `totalCommissionAmount`     | number         | إجمالي العمولة                    |
| `totalProductDiscountValue` | number         | إجمالي خصم المنتجات               |
| `images`                    | array          | صور العرض                         |

#### Offer Products (منتجات العرض)

كل منتج في العرض يحتوي على نفس تفاصيل المنتج الكاملة بالإضافة إلى:

| الحقل                  | النوع          | الوصف                    |
| ---------------------- | -------------- | ------------------------ |
| `id`                   | number         | معرف منتج العرض          |
| `productId`            | number         | معرف المنتج              |
| `product`              | object         | تفاصيل المنتج الكاملة    |
| `quantity`             | number         | الكمية الداخلية في العرض |
| `originalUnitPrice`    | number         | السعر الأصلي             |
| `discount`             | number         | قيمة الخصم               |
| `discountType`         | string \| null | نوع الخصم                |
| `unitPrice`            | number         | السعر بعد الخصم          |
| `totalPrice`           | number         | السعر الإجمالي           |
| `commissionRate`       | number         | نسبة العمولة             |
| `commissionAmount`     | number         | مبلغ العمولة             |
| `productDiscountValue` | number         | قيمة خصم المنتج          |

#### حساب المجاميع

```
=== حساب عناصر الطلب (Items) ===
- originalUnitPrice = السعر الأصلي للمنتج
- productDiscountValue =
    - إذا PERCENTAGE: (originalPrice × productDiscount) / 100
    - إذا FIXED: productDiscount (قيمة ثابتة)
- priceAfterProductDiscount = originalUnitPrice - productDiscountValue
- commissionAmount = (originalPrice × commissionRate) / 100  ← العمولة تحسب على السعر الأصلي قبل أي خصم
- unitPrice = priceAfterProductDiscount
- totalPrice = (priceAfterProductDiscount + commissionAmount) × quantity
- totalCommissionAmount = commissionAmount × quantity

=== حساب العروض (Offers) ===
- productInternalQuantity = مجموع الكميات الداخلية للمنتجات
- subtotal = مجموع (originalUnitPrice × quantity) × totalQuantity
- productDiscount = مجموع (productDiscountValue × quantity) × totalQuantity
- offerDiscount =
    - إذا PERCENTAGE: (subtotalAfterProductDiscount × discountValue) / 100
    - إذا FIXED: discountValue × totalQuantity
- totalCommissionAmount = مجموع (commissionAmount × quantity) × totalQuantity
- total = subtotalAfterProductDiscount - offerDiscount + totalCommissionAmount  ← يشمل العمولة

=== حساب الطلب الكلي ===
- itemsTotal = مجموع totalPrice من الـ items (يشمل العمولة)
- offersTotal = مجموع total من الـ offers (يشمل العمولة)
- subtotal = itemsTotal + offersTotal
- totalCommissionAmount = مجموع عمولة الـ items + مجموع عمولة الـ offers
- platformCommission = totalCommissionAmount
- totalAmount = itemsTotal + offersTotal (المجموع الصحيح)
- ownerRevenue = itemsTotal + offersTotal - totalCommissionAmount
```

### مثال حسابي

```
مثال: منتج بسعر 100، خصم 50%، عمولة 5%، كمية 10

=== الحساب ===
- originalUnitPrice = 100
- productDiscountValue = 100 × 50% = 50
- priceAfterProductDiscount = 100 - 50 = 50
- commissionAmount = 100 × 5% = 5  ← تحسب على السعر الأصلي
- unitPrice = 50
- totalPrice = (50 + 5) × 10 = 550
- totalCommissionAmount = 5 × 10 = 50

=== في قسم الـ offers ===
- subtotal = 100 × 10 = 1000
- offerDiscount (50%) = 1000 × 50% = 500
- total = 1000 - 500 + 50 = 550  ← يشمل العمولة
```

### Response (Error - 404 Not Found)

```json
{
  "message": "Order with ID 123 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

### Response (Error - 403 Forbidden)

```json
{
  "message": "Access denied: insufficient permissions for this order",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

## 6. تحديث حالة الطلب

تحديث حالة طلب ديناميكياً مع التحقق من الصحة والإشعارات.

- **URL:** `/orders/:id/:status`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### URL Parameters

| المعامل  | النوع  | مطلوب | الوصف                                                                                                                   |
| -------- | ------ | ----- | ----------------------------------------------------------------------------------------------------------------------- |
| `id`     | number | نعم   | رقم الطلب                                                                                                               |
| `status` | string | نعم   | الحالة الجديدة (pending, confirmed, preparing, ready-for-pickup, picked-up, on-the-way, delivered, cancelled, rejected) |

### Request Body (Optional)

| الحقل    | النوع  | الوصف            |
| -------- | ------ | ---------------- |
| `reason` | string | سبب تغيير الحالة |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/preparing \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم بدء تحضير الطلب"}'
```

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "customerId": 1,
  "ownerId": 1,
  "paymentMethod": "CASH",
  "status": "PREPARING",
  "deliveryDeadline": "2024-01-15T14:30:00.000Z",
  "mealPreparationTime": 15,
  "deliveryTime": 30,
  "deliveryCoordinates": {
    "latitude": 33.5138,
    "longitude": 36.2765,
    "address": "Al-Hamra Street"
  },
  "finalLocation": null,
  "items": [...],
  "offers": [],
  "priceBeforeDiscount": 20000,
  "discountAmount": 3000,
  "priceAfterProductDiscount": 17500,
  "tipAmount": 500,
  "platformCommission": 1450,
  "ownerRevenue": 13050,
  "deliveryFee": 1500,
  "totalAmount": 19000,
  "totalCommissionAmount": 1450,
  "currencyCode": "SYP",
  "exchangeRate": 1,
  "createdAt": "2024-01-15T13:45:00.000Z",
  "updatedAt": "2024-01-15T13:50:00.000Z"
}
```

### Response (Error - 400 Bad Request)

إذا كان الانتقال بين الحالات غير صالح:

```json
{
  "message": "Cannot transition from \"PENDING\" to \"DELIVERED\". Allowed transitions: CONFIRMED, REJECTED, CANCELLED",
  "error": "Bad Request",
  "statusCode": 400
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن لدى المستخدم صلاحية:

```json
{
  "message": "Role \"CUSTOMER\" cannot change status to \"PREPARING\"",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

## 7. تعديل أصناف الطلب (خاص بالزبون)

يسمح للزبون بتعديل محتويات الطلب (إضافة، حذف، أو تغيير كميات) فقط عندما يكون الطلب في حالة `PENDING`. يجب أن تكون جميع الأصناف تابعة لنفس المطعم. سيتم تحديث إجمالي الطلب ومراجعة المخزون تلقائياً.

- **URL:** `/orders/:id/items`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token> (Role: CUSTOMER)`

### Payload (Request Body)

| الحقل               | النوع  | مطلوب | الوصف                                                |
| ------------------- | ------ | ----- | ---------------------------------------------------- |
| `items`             | array  | نعم   | قائمة العناصر (عنصر واحد على الأقل بكمية أكبر من 0)  |
| `items[].productId` | number | نعم   | معرف المنتج                                          |
| `items[].quantity`  | number | نعم   | الكمية (0 = إزالة العنصر، 1+ = تعيين الكمية الجديدة) |

### مثال: إضافة وتعديل كميات

```json
{
  "items": [
    { "productId": 5, "quantity": 2 },
    { "productId": 8, "quantity": 1 }
  ]
}
```

### مثال: إزالة عنصر من الطلب

لإزالة عنصر، أرسل `quantity: 0` مع الاحتفاظ بعنصر واحد على الأقل بكمية أكبر من 0:

```json
{
  "items": [
    { "productId": 5, "quantity": 2 },
    { "productId": 8, "quantity": 0 }
  ]
}
```

### Response (Success - 200 OK)

يعيد تفاصيل الطلب مع المجاميع المالية المحدثة والمحتويات الجديدة.

### Response (Error - 400 Bad Request)

محاولة إزالة جميع العناصر:

```json
{
  "message": "Cannot remove all items from the order. At least one item must remain.",
  "error": "Bad Request",
  "statusCode": 400
}
```

الطلب ليس في حالة PENDING:

```json
{
  "message": "Cannot modify items when order is in status: CONFIRMED. Modification is only allowed for PENDING orders.",
  "error": "Bad Request",
  "statusCode": 400
}
```

### ملاحظات

- عند إرسال `quantity: 0`، يتم إزالة العنصر من الطلب واستعادة المخزون تلقائياً
- يجب أن يبقى عنصر واحد على الأقل بكمية أكبر من 0 في الطلب
- العناصر غير الموجودة في القائمة الجديدة يتم حذفها تلقائياً واستعادة مخزونها
- يتم إعادة حساب المجاميع المالية تلقائياً بعد التعديل

---

## 8. تأكيد الطلب

تأكيد الطلب من قبل المطعم مع تحديد وقت التحضير والتوصيل.

- **URL:** `/orders/:id/confirm`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Payload (Request Body)

| الحقل                 | النوع  | مطلوب | الوصف                       |
| --------------------- | ------ | ----- | --------------------------- |
| `mealPreparationTime` | number | لا    | وقت تحضير الطعام (بالدقائق) |
| `deliveryTime`        | number | لا    | وقت التوصيل (بالدقائق)      |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/confirm \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "mealPreparationTime": 15,
    "deliveryTime": 30
  }'
```

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "status": "CONFIRMED",
  "mealPreparationTime": 15,
  "deliveryTime": 30,
  "deliveryDeadline": "2024-01-15T14:30:00.000Z",
  "updatedAt": "2024-01-15T13:50:00.000Z"
}
```

### ملاحظات

- عند إرسال `mealPreparationTime` و `deliveryTime` (بالدقائق)، يقوم النظام تلقائياً بتحديث الحقلين في الكائن
- يتم حساب `deliveryDeadline` = الوقت الحالي + (وقت التحضير + وقت التوصيل)
- هذه العملية تتم داخل `UpdateOrderPipeline` لضمان اتساق البيانات

---

## 8. بدء التحضير

بدء تحضير الطلب من قبل المطعم.

- **URL:** `/orders/:id/preparing`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف           |
| -------- | ------ | --------------- |
| `reason` | string | سبب بدء التحضير |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/preparing \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم بدء تحضير الطلب"}'
```

---

## 9. تحديد جاهز للاستلام

تحديد أن الطلب جاهز لاستلامه من قبل السائق.

- **URL:** `/orders/:id/ready-for-pickup`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف                |
| -------- | ------ | -------------------- |
| `reason` | string | سبب التحديد للجاهزية |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/ready-for-pickup \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "الطلب جاهز للاستلام"}'
```

---

## 10. استلام الطلب من قبل السائق

تحديد أن السائق استلم الطلب من المطعم.

- **URL:** `/orders/:id/picked-up`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف        |
| -------- | ------ | ------------ |
| `reason` | string | سبب الاستلام |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/picked-up \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تم استلام الطلب من المطعم"}'
```

---

## 11. الطلب في الطريق

تحديد أن السائق في الطريق إلى عنوان العميل.

- **URL:** `/orders/:id/on-the-way`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف       |
| -------- | ------ | ----------- |
| `reason` | string | سبب التحديد |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/on-the-way \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "في الطريق إلى العميل"}'
```

---

## 12. تأكيد التسليم

تحديد أن الطلب تم تسليمه للعميل بنجاح.

- **URL:** `/orders/:id/delivered`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل               | النوع  | الوصف                  |
| ------------------- | ------ | ---------------------- |
| `reason`            | string | سبب التسليم            |
| `finalLocation`     | object | الموقع النهائي للتسليم |
| `finalLocation.lat` | number | خط العرض               |
| `finalLocation.lng` | number | خط الطول               |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/delivered \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "تم التسليم بنجاح",
    "finalLocation": {
      "lat": 33.5138,
      "lng": 36.2765
    }
  }'
```

---

## 13. استعادة الطلب الملغى

استعادة طلب تم إلغاؤه خلال 3 دقائق.

- **URL:** `/orders/:id/pending`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <access_token>`

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/pending \
  -H "Authorization: Bearer <access_token>"
```

---

## 14. إلغاء الطلب

إلغاء الطلب من قبل العميل أو المطعم.

- **URL:** `/orders/:id/cancel`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف       |
| -------- | ------ | ----------- |
| `reason` | string | سبب الإلغاء |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/cancel \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "تغيير في الخطط"}'
```

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "status": "CANCELLED",
  ...
}
```

### ملاحظات

- إذا كان المنتج يحتوي على مخزون، يتم إعادة المخزون المُستهلك عند الإلغاء
- العملاء يمكنهم إلغاء الطلبات فقط إذا كانت الحالة `PENDING`
- المالكون والتجار يمكنهم إلغاء الطلبات في أي حالة (ما لم تكن `DELIVERED` أو `CANCELLED` أو `REJECTED`)

---

## 9. رفض الطلب

رفض الطلب من قبل المطعم.

- **URL:** `/orders/:id/reject`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف     |
| -------- | ------ | --------- |
| `reason` | string | سبب الرفض |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123/reject \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "المنتج غير متوفر حالياً"}'
```

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "status": "REJECTED",
  ...
}
```

### ملاحظات

- يتم إعادة المخزون المُستهلك عند الرفض
- يمكن رفض الطلبات فقط إذا كانت الحالة `PENDING`

---

## 10. إرسال إشعارات التوصيل

إرسال إشعارات للسائقين المتاحين när الطلب يصبح جاهز للاستلام.

- **URL:** `/orders/:id/send-delivery-notifications`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Example

```bash
curl -X POST http://localhost:3000/api/v1/orders/123/send-delivery-notifications \
  -H "Authorization: Bearer <access_token>"
```

### Response (Success - 200 OK)

```json
{
  "message": "Delivery notifications sent successfully"
}
```

### ملاحظات

- يتم إرسال الإشعارات تلقائياً عند تغيير الحالة إلى `READY_FOR_PICKUP`
- يتم اختيار أقرب 3 سائقين متاحين بناءً على الإحداثيات
- إذا لم يكن هناك سائقين متاحين، يتم جدولة إعادة المحاولة

---

## 11. قبول التوصيل

قبول السائق لطلب التوصيل.

- **URL:** `/orders/:id/accept-delivery`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Example

```bash
curl -X POST http://localhost:3000/api/v1/orders/123/accept-delivery \
  -H "Authorization: Bearer <access_token>"
```

### Response (Success - 200 OK)

```json
{
  "id": 1,
  "orderId": 123,
  "deliveryId": 5,
  "status": "ACCEPTED",
  "assignedAt": "2024-01-15T13:50:00.000Z",
  "acceptedAt": "2024-01-15T13:50:00.000Z"
}
```

### Response (Error - 400 Bad Request)

```json
{
  "message": "Delivery already assigned",
  "error": "Bad Request",
  "statusCode": 400
}
```

### Response (Error - 403 Forbidden)

```json
{
  "message": "Only delivery drivers can accept assignments",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

## 12. رفض التوصيل

رفض السائق لطلب التوصيل.

- **URL:** `/orders/:id/reject-delivery`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Request Body (Optional)

| الحقل    | النوع  | الوصف     |
| -------- | ------ | --------- |
| `reason` | string | سبب الرفض |

### Request Example

```bash
curl -X POST http://localhost:3000/api/v1/orders/123/reject-delivery \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "بعيد جداً عن موقعي"}'
```

### Response (Success - 200 OK)

```json
{
  "message": "Delivery rejected successfully"
}
```

---

## 13. كائنات البيانات (Entities)

### Order (الطلب)

```typescript
{
  id: number;                    // رقم الطلب
  customerId: number;            // رقم العميل
  customer: User;                // بيانات العميل
  ownerId: number;                // رقم صاحب المطعم
  owner: User;                   // بيانات صاحب المطعم
  totalAmount: number;           // المبلغ الإجمالي (بأصغر وحدة)
  deliveryFee: number;           // رسوم التوصيل
  discountAmount: number;        // مبلغ الخصم (منتجات وعروض)
  offers: Offer[];               // العروض المطبقة على الطلب
  tipAmount: number;             // مبلغ البقشيش
  platformCommission: number;    // عمولة المنصة
  ownerRevenue: number;          // إيراد صاحب المطعم
  currencyCode: string;          // رمز العملة
  exchangeRate: number;          // سعر الصرف
  paymentMethod: PaymentMethod;  // طريقة الدفع
  status: OrderStatus;          // حالة الطلب
  deliveryDeadline: Date;        // الموعد النهائي للتوصيل
  mealPreparationTime: number | null;  // وقت تجهيز الوجبة (بالدقائق)
  deliveryTime: number | null;   // وقت التوصيل (بالدقائق)
  deliveryCoordinates: {          // إحداثيات التوصيل
    latitude: number;
    longitude: number;
    address?: string;
    landmark?: string;
    specialInstructions?: string;
  };
  finalLocation: { lat: number; lng: number } | null; // الموقع النهائي (يُملأ عند التسليم)
  items: OrderItem[];            // عناصر الطلب
  deliveryAssignment: DeliveryAssignment | null; // تعيين التوصيل
  createdAt: Date;               // تاريخ الإنشاء
  updatedAt: Date;               // تاريخ التحديث

  // حقول محسوبة (تُرجع في الاستجابة فقط)
  priceBeforeDiscount: number;          // السعر قبل الخصم
  priceAfterProductDiscount: number;    // السعر بعد خصم المنتجات
}
```

### Offer (العرض)

```typescript
{
  id: number;              // رقم العرض
  name: string;            // اسم العرض (يخزن كـ JSON: { ar: string, en: string })
  description: string | null; // وصف العرض
  discountType: 'PERCENTAGE' | 'FIXED'; // نوع الخصم
  discountValue: number;   // قيمة الخصم
  startDate: Date | null;  // تاريخ بدء العرض
  endDate: Date | null;   // تاريخ انتهاء العرض
  isActive: boolean;       // هل العرض نشط
  merchantId: number | null; // رقم صاحب المطعم
  products: Product[];     // المنتجات المشمولة في العرض
  createdAt: Date;        // تاريخ الإنشاء
  updatedAt: Date;        // تاريخ التحديث
}
```

### OrderItem (عنصر الطلب)

```typescript
{
  id: number; // رقم العنصر
  orderId: number; // رقم الطلب
  productId: number | null; // رقم المنتج
  productName: string; // اسم المنتج
  quantity: number; // الكمية
  originalUnitPrice: number; // السعر الأصلي للمنتج
  unitPrice: number; // سعر الوحدة (بعد أي تعديلات)
  totalPrice: number; // السعر الإجمالي للعنصر
}
```

### DeliveryAssignment (تعيين التوصيل)

```typescript
{
  id: number; // رقم التعيين
  orderId: number; // رقم الطلب
  order: Order; // بيانات الطلب
  deliveryId: number; // رقم السائق
  delivery: User; // بيانات السائق
  assignedAt: Date; // وقت التعيين
  acceptedAt: Date | null; // وقت القبول
  pickedAt: Date | null; // وقت الاستلام
  deliveredAt: Date | null; // وقت التسليم
  groupIndex: number; // مجموعة الإشعارات
  notifiedAt: Date | null; // وقت الإشعار
  status: DeliveryStatus; // حالة التوصيل
}
```

### PaymentMethod (طرق الدفع)

| القيمة   | الوصف               |
| -------- | ------------------- |
| `CASH`   | نقداً عند الاستلام  |
| `WALLET` | المحفظة الإلكترونية |
| `ONLINE` | دفع إلكتروني        |

### PaymentProvider (مزودو الدفع الإلكتروني)

| القيمة                | الوصف           |
| --------------------- | --------------- |
| `STRIPE`              | Stripe          |
| `PAYPAL`              | PayPal          |
| `MTN_CASH`            | MTN Cash        |
| `SYRIATEL_CASH`       | Syriatel Cash   |
| `USDT`                | USDT            |
| `LOCAL_BANK_TRANSFER` | تحويل بنكي محلي |
| `UNKNOWN`             | غير معروف       |

### DeliveryStatus (حالات التوصيل)

| القيمة       | الوصف       |
| ------------ | ----------- |
| `ASSIGNED`   | تم التعيين  |
| `ACCEPTED`   | تم القبول   |
| `PICKED_UP`  | تم الاستلام |
| `ON_THE_WAY` | في الطريق   |
| `DELIVERED`  | تم التسليم  |
| `CANCELLED`  | ملغى        |
| `FAILED`     | فشل         |

---

## أكواد الخطأ (Error Codes)

### أكواد أخطاء إنشاء الطلب (4000-4099)

| الرمز | الكود                               | الرسالة                                           |
| ----- | ----------------------------------- | ------------------------------------------------- |
| 4001  | INVALID_RESTAURANT_ID               | Invalid restaurant ID                             |
| 4002  | RESTAURANT_NOT_FOUND                | Restaurant not found                              |
| 4003  | RESTAURANT_NOT_AVAILABLE            | Restaurant is not available                       |
| 4011  | INVALID_PRODUCT_ID                  | Invalid product ID                                |
| 4012  | PRODUCT_NOT_FOUND                   | Product not found                                 |
| 4013  | PRODUCT_NOT_AVAILABLE               | Product is not available                          |
| 4014  | INSUFFICIENT_STOCK                  | Insufficient stock for product                    |
| 4015  | PRODUCT_NOT_OWNED_BY_MERCHANT       | Product does not belong to this merchant          |
| 4016  | INVALID_OFFER_ID                    | Invalid offer ID                                  |
| 4017  | OFFER_NOT_FOUND                     | Offer not found                                   |
| 4018  | OFFER_NOT_ACTIVE                    | Offer is not active                               |
| 4019  | OFFER_NOT_OWNED_BY_MERCHANT         | Offer does not belong to this merchant            |
| 4020  | OFFER_PRODUCT_NOT_OWNED_BY_MERCHANT | Product in offer does not belong to this merchant |
| 4021  | INVALID_ORDER_ITEMS                 | Invalid order items                               |
| 4022  | EMPTY_ORDER_ITEMS                   | Order must have at least one item                 |
| 4023  | INVALID_QUANTITY                    | Quantity must be greater than zero                |
| 4024  | OWNER_ID_REQUIRED                   | Owner ID is required                              |
| 4031  | INVALID_DELIVERY_COORDINATES        | Delivery coordinates are required                 |
| 4032  | INVALID_DELIVERY_FEE                | Invalid delivery fee                              |
| 4033  | INVALID_TIP_AMOUNT                  | Tip amount cannot be negative                     |
| 4041  | INVALID_COUPON                      | Invalid coupon code                               |
| 4051  | PAYMENT_METHOD_REQUIRED             | Payment method is required                        |

### أكواد أخطاء الطلب (4100-4199)

| الرمز | الكود                      | الرسالة                          |
| ----- | -------------------------- | -------------------------------- |
| 4101  | ORDER_NOT_FOUND            | Order not found                  |
| 4102  | INVALID_ORDER_ID           | Invalid order ID                 |
| 4111  | INVALID_STATUS_TRANSITION  | Invalid status transition        |
| 4112  | UNAUTHORIZED_STATUS_CHANGE | Unauthorized status change       |
| 4113  | ORDER_ALREADY_DELIVERED    | Order has already been delivered |
| 4114  | ORDER_ALREADY_CANCELLED    | Order has already been cancelled |

### أكواد أخطاء عام

| الرمز | الكود                 | الرسالة               |
| ----- | --------------------- | --------------------- |
| 4301  | INTERNAL_SERVER_ERROR | Internal server error |
| 4302  | VALIDATION_ERROR      | Validation error      |

---

## ملاحظات مهمة

1. **الوحدات المالية**: جميع المبالغ المالية تُخزن وتُرجع بأصغر وحدة عملة (مثل: هللات أو halalas). مثال: 1500 = 15.00 SAR

2. **المخزون**: عند إنشاء طلب، يتم خصم الكمية من المخزون تلقائياً. عند إلغاء أو رفض الطلب، يتم إعادة الكمية إلى المخزون.
   - للمنتجات التي لها `hasStock: true` فقط
   - المنتجات التي لها `hasStock: false` لا تتأثر

3. **منحنيات التسعير**:
   - `subtotal`: مجموع الأسعار الأصلية لجميع العناصر (بعد خصم المنتج والعمولة)
   - `productDiscount`: مجموع خصومات المنتجات فقط
   - `offerDiscount`: مجموع خصومات العروض
   - `totalAmount`: السعر النهائي = subtotal - offerDiscount + deliveryFee + tipAmount

4. **الإشعارات**: يتم إرسال إشعارات للسائقين تلقائياً عند تحوّل الطلب إلى حالة `READY_FOR_PICKUP`

5. **finalLocation**: هذا الحقل يُملأ فقط عند تغيير حالة الطلب إلى `DELIVERED`، ويحمل قيمة `deliveryCoordinates`

6. **المنتجات والعروض**: يجب أن تنتمي جميع المنتجات والعروض لنفس التاجر (`ownerId`). إذا حاولت إضافة منتجات أو عروض من تاجر آخر، ستظهر رسالة خطأ.

7. **الصور**: يتم تحميل صور المنتجات والعروض تلقائياً عند استرجاع تفاصيل الطلب

---

## 6. تحديث الطلب (تعديل العناصر والعروض)

تحديث عناصر وعروض طلب موجود مع دعم ثلاث طرق مختلفة للتعديل.

- **URL:** `/orders/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### ملاحظات مهمة

- **الحالة**: يمكن تعديل العناصر والعروض فقط عندما يكون الطلب في حالة `PENDING`
- **على الأقل عنصر واحد**: يجب أن يبقى عنصر واحد على الأقل في الطلب
- **المخزون**: يتم تحديث المخزون تلقائياً عند إضافة أو إزالة عناصر

### طرق التحديث المدعومة

#### الطريقة الأولى: by productId

تعديل العناصر باستخدام معرف المنتج:

```json
{
  "itemsByProductId": [
    { "productId": 10, "quantity": 3 },
    { "productId": 15, "quantity": 2 }
  ]
}
```

#### الطريقة الثانية: by order item id

تعديل العناصر باستخدام معرف عنصر الطلب:

```json
{
  "itemsById": [
    { "id": 100, "quantity": 5 },
    { "id": 101, "quantity": 0 }
  ]
}
```

#### الطريقة الثالثة: by deleted arrays

حذف عناصر وعروض محددة:

```json
{
  "deletedProducts": [10, 15],
  "deletedOffers": [1, 2]
}
```

### جميع الحقول المتاحة

| الحقل              | النوع | مطلوب | الوصف                          |
| ------------------ | ----- | ----- | ------------------------------ |
| `itemsByProductId` | array | لا    | تعديل العناصر by productId     |
| `itemsById`        | array | لا    | تعديل العناصر by order item ID |
| `offersByOfferId`  | array | لا    | تعديل العروض by offerId        |
| `offersById`       | array | لا    | تعديل العروض by ID             |
| `deletedProducts`  | array | لا    | حذف منتجات by productId        |
| `deletedOffers`    | array | لا    | حذف عروض by offerId            |

### بنية itemsByProductId

| الحقل       | النوع  | مطلوب | الوصف          |
| ----------- | ------ | ----- | -------------- |
| `productId` | number | نعم   | معرف المنتج    |
| `quantity`  | number | نعم   | الكمية الجديدة |

### بنية itemsById

| الحقل      | النوع  | مطلوب | الوصف                    |
| ---------- | ------ | ----- | ------------------------ |
| `id`       | number | نعم   | معرف عنصر الطلب          |
| `quantity` | number | نعم   | الكمية الجديدة (0 للحذف) |

### بنية offersByOfferId

| الحقل      | النوع  | مطلوب | الوصف          |
| ---------- | ------ | ----- | -------------- |
| `offerId`  | number | نعم   | معرف العرض     |
| `quantity` | number | نعم   | الكمية الجديدة |

### بنية offersById

| الحقل      | النوع  | مطلوب | الوصف               |
| ---------- | ------ | ----- | ------------------- |
| `id`       | number | نعم   | معرف العرض في الطلب |
| `quantity` | number | نعم   | الكمية الجديدة      |

### Request Examples

#### مثال 1: تعديل العناصر by productId

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "itemsByProductId": [
      { "productId": 10, "quantity": 3 },
      { "productId": 15, "quantity": 2 }
    ]
  }'
```

#### مثال 2: تعديل العناصر by order item id

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "itemsById": [
      { "id": 100, "quantity": 5 },
      { "id": 101, "quantity": 0 }
    ]
  }'
```

#### مثال 3: حذف المنتجات والعروض

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "deletedProducts": [10, 15],
    "deletedOffers": [1, 2]
  }'
```

#### مثال 4: دمج طرق متعددة

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "itemsByProductId": [
      { "productId": 10, "quantity": 3 }
    ],
    "itemsById": [
      { "id": 100, "quantity": 5 }
    ],
    "deletedProducts": [15],
    "deletedOffers": [1]
  }'
```

### Response (Success - 200 OK)

```json
{
  "id": 123,
  "customerId": 1,
  "ownerId": 1,
  "paymentMethod": "CASH",
  "status": "PENDING",
  "items": [
    {
      "id": 100,
      "productId": 10,
      "productName": "شاورما دجاج",
      "quantity": 3,
      "unitPrice": 7500,
      "totalPrice": 22500
    },
    {
      "id": 102,
      "productId": 15,
      "productName": "عصير برتقال",
      "quantity": 2,
      "unitPrice": 2500,
      "totalPrice": 5000
    }
  ],
  "offers": [
    {
      "id": 2,
      "name": "خصم 10%",
      "discountType": "PERCENTAGE",
      "discountValue": 10
    }
  ],
  "subtotal": 27500,
  "discountAmount": 1000,
  "deliveryFee": 1500,
  "totalAmount": 28000,
  "updatedAt": "2024-01-15T14:00:00.000Z"
}
```

### Response (Error - 400 Bad Request)

#### حالة الطلب غير صحيحة

```json
{
  "message": "Cannot modify items when order is in status: CONFIRMED. Modification is only allowed for PENDING orders.",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### حذف جميع العناصر

```json
{
  "message": "Cannot remove all items from the order. At least one item must remain.",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### منتج غير موجود

```json
{
  "message": "Product with ID 999 not found",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### منتج غير موجود في الطلب

```json
{
  "message": "Product with ID 15 not found in order",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### منتج غير متوفر

```json
{
  "message": "Product شاورما دجاج is not available",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### مخزون غير كافٍ

```json
{
  "message": "Insufficient stock for product \"شاورما دجاج\". Required additional: 2, Available: 1",
  "error": "Bad Request",
  "statusCode": 400
}
```

#### عرض غير موجود في الطلب

```json
{
  "message": "Offers with IDs 5 not found in order",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

(End of file - total 782 lines)
