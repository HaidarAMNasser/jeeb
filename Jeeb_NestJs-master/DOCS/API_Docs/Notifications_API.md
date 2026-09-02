# Notifications API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## نظرة عامة

نظام الإشعارات يتيح إرسال الإشعارات للمستخدمين عبر قنوات متعددة (Firebase, WhatsApp, Email, SMS) مع دعم الإشعارات الفردية والجماعية والمواضيع.

- **Base URL:** `/notifications`
- **Authentication:** Required (Bearer Token)

---

## 1. Send Notification to User

إرسال إشعار لمستخدم محدد.

- **URL:** `/notifications/send-to-user`
- **Method:** `POST`
- **Authentication:** Required

### Request Body

| Parameter  | Type   | Required | Description                      |
| ---------- | ------ | -------- | -------------------------------- |
| `userId`   | number | Yes      | ID المستخدم المرسل إليه          |
| `type`     | enum   | Yes      | نوع الإشعار                      |
| `title`    | string | Yes      | عنوان الإشعار                    |
| `body`     | string | Yes      | محتوى الإشعار                    |
| `channel`  | enum   | No       | قناة الإشعار (افتراضي: FIREBASE) |
| `metadata` | object | No       | بيانات إضافية                    |

### NotificationType Values

#### 1. إشعارات التحقق والحسابات

| Value     | Description      | المستلم |
| --------- | ---------------- | ------- |
| `OTP`     | رمز التحقق (OTP) | العميل  |
| `WELCOME` | رسالة ترحيبية    | العميل  |

#### 2. إشعارات الطلبات (Orders)

| Value              | Description         | المستلم         |
| ------------------ | ------------------- | --------------- |
| `ORDER_CREATED`    | طلب جديد تم إنشاؤه  | التاجر (المطعم) |
| `ORDER_CONFIRMED`  | تم تأكيد الطلب      | العميل          |
| `ORDER_SEARCHING`  | البحث عن سائق       | العميل          |
| `ORDER_ASSIGNED`   | تم تعيين سائق       | السائق          |
| `ORDER_READY`      | الطلب جاهز للاستلام | السائق          |
| `ORDER_PICKED_UP`  | تم استلام الطلب     | العميل          |
| `ORDER_ON_THE_WAY` | الطلب في الطريق     | العميل          |
| `ORDER_DELIVERED`  | تم توصيل الطلب      | العميل          |
| `ORDER_CANCELLED`  | تم إلغاء الطلب      | العميل          |
| `ORDER_UPDATE`     | تحديث عام للطلب     | -               |

#### 3. إشعارات الحسابات (Auth)

| Value                   | Description     | المستلم                |
| ----------------------- | --------------- | ---------------------- |
| `DELIVERY_REGISTRATION` | تسجيل سائق جديد | المدير (جميع المديرين) |
| `DELIVERY_VERIFIED`     | تحقق حساب سائق  | المدير (جميع المديرين) |
| `MERCHANT_REGISTRATION` | تسجيل مطعم جديد | المدير (جميع المديرين) |
| `MERCHANT_VERIFIED`     | تحقق حساب مطعم  | المدير (جميع المديرين) |
| `MERCHANT_ACCOUNT_STATUS` | تغيير حالة حساب التاجر | التاجر               |

#### 4. إشعارات تسويقية

| Value       | Description |
| ----------- | ----------- |
| `OFFER`     | عرض خاص     |
| `COUPON`    | كoupon خصم  |
| `MARKETING` | تسويقي      |
| `ALERT`     | تنبيه       |
| `CUSTOM`    | مخصص        |

### NotificationChannel Values

| Value      | Description          |
| ---------- | -------------------- |
| `WHATSAPP` | واتساب               |
| `EMAIL`    | بريد إلكتروني        |
| `SMS`      | رسالة نصية           |
| `FIREBASE` | إشعار فوري (افتراضي) |

### Request Example

```bash
POST /api/v1/notifications/send-to-user
Authorization: Bearer <token>
Content-Type: application/json

{
  "userId": 5,
  "type": "ORDER_UPDATE",
  "title": "تم تأكيد طلبك",
  "body": "تم تأكيد طلبك #123 وهو قيد التجهيز",
  "channel": "FIREBASE",
  "metadata": {
    "orderId": 123,
    "orderStatus": "CONFIRMED"
  }
}
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 45,
    "userId": 5,
    "recipient": "fcm_token_xxx",
    "channel": "FIREBASE",
    "type": "ORDER_UPDATE",
    "title": "تم تأكيد طلبك",
    "body": "تم تأكيد طلبك #123 وهو قيد التجهيز",
    "topic": null,
    "status": "SENT",
    "orderId": 123,
    "sentAt": "2024-01-15T10:30:00Z",
    "createdAt": "2024-01-15T10:29:00Z"
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications/send-to-user"
}
```

### Response Example (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found for notification",
  "data": {},
  "timestamp": "2024-01-15T10:29:00Z",
  "path": "/api/v1/notifications/send-to-user"
}
```

---

## 2. Send Notification to All

إرسال إشعار لجميع المستخدمين في موضوع محدد أو للجميع.

- **URL:** `/notifications/send-to-all`
- **Method:** `POST`
- **Authentication:** Required

### Request Body

| Parameter     | Type   | Required | Description                      |
| ------------- | ------ | -------- | -------------------------------- |
| `topic`       | enum   | No       | الموضوع (لإشعار جماعي)           |
| `type`        | enum   | Yes      | نوع الإشعار                      |
| `title`       | string | Yes      | عنوان الإشعار                    |
| `body`        | string | Yes      | محتوى الإشعار                    |
| `channel`     | enum   | No       | قناة الإشعار (افتراضي: FIREBASE) |
| `metadata`    | object | No       | بيانات إضافية                    |
| `scheduledAt` | string | No       | وقت الإشعار المجدول (ISO 8601)   |

### NotificationTopic Values

| Value               | Description                 |
| ------------------- | --------------------------- |
| `ALL_USERS`         | جميع المستخدمين             |
| `ALL_DRIVERS`       | جميع سائقي التوصيل          |
| `ALL_MERCHANTS`     | جميع التجار                 |
| `ALL_CUSTOMERS`     | جميع العملاء                |
| `ALL_OFFICE_OWNERS` | جميع أصحاب المكاتب          |
| `ALL_OFFERS`        | إشعارات العروض (للعملاء)    |
| `ALL_COUPONS`       | إشعارات الكوبونات (للعملاء) |

### Request Example

```bash
POST /api/v1/notifications/send-to-all
Authorization: Bearer <token>
Content-Type: application/json

{
  "topic": "ALL_CUSTOMERS",
  "type": "OFFER",
  "title": "عرض جديد",
  "body": "خصم 20% على جميع الطلبات اليوم",
  "channel": "FIREBASE",
  "metadata": {
    "offerId": 15,
    "discount": "20%"
  }
}
```

### Request Example (Scheduled Notification)

```bash
POST /api/v1/notifications/send-to-all
Authorization: Bearer <token>
Content-Type: application/json

{
  "topic": "ALL_CUSTOMERS",
  "type": "MARKETING",
  "title": "عرض خاص",
  "body": "خصم نهاية الأسبوع",
  "channel": "FIREBASE",
  "scheduledAt": "2024-01-20T09:00:00Z"
}
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 46,
    "channel": "FIREBASE",
    "type": "OFFER",
    "title": "عرض جديد",
    "body": "خصم 20% على جميع الطلبات اليوم",
    "topic": "ALL_CUSTOMERS",
    "status": "SENT",
    "sentAt": "2024-01-15T10:30:00Z",
    "scheduledAt": null,
    "createdAt": "2024-01-15T10:29:00Z"
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications/send-to-all"
}
```

---

## 3. Send Notification to All Customers

إرسال إشعار لجميع العملاء (CUSTOMER topic) عبر Firebase مباشرة.

- **URL:** `/notifications/send-to-customers`
- **Method:** `POST`
- **Authentication:** Required

### Request Body

| Parameter | Type   | Required | Description   |
| --------- | ------ | -------- | ------------- |
| `title`   | string | Yes      | عنوان الإشعار |
| `body`    | string | Yes      | محتوى الإشعار |

> النوع (`type`) مُعيّن تلقائياً إلى `CUSTOM` والقناة (`channel`) إلى `FIREBASE`.

### Request Example

```bash
POST /api/v1/notifications/send-to-customers
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "عرض خاص للعملاء",
  "body": "خصم 15% على طلبك القادم"
}
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
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
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications/send-to-customers"
}
```

---

## 4. Get User Notifications

الحصول على إشعارات المستخدم الحالي.

- **URL:** `/notifications`
- **Method:** `GET`
- **Authentication:** Required

### Query Parameters

| Parameter | Type   | Required | Description               |
| --------- | ------ | -------- | ------------------------- |
| `page`    | number | No       | رقم الصفحة (افتراضي: 1)   |
| `limit`   | number | No       | عدد العناصر (افتراضي: 20) |

### Request Example

```bash
GET /api/v1/notifications?page=1&limit=20
Authorization: Bearer <token>
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "data": [
      {
        "id": 45,
        "type": "ORDER_UPDATE",
        "title": "تم تأكيد طلبك",
        "body": "تم تأكيد طلبك #123 وهو قيد التجهيز",
        "topic": null,
        "channel": "FIREBASE",
        "status": "SENT",
        "readAt": null,
        "createdAt": "2024-01-15T10:29:00Z"
      },
      {
        "id": 44,
        "type": "OFFER",
        "title": "عرض جديد",
        "body": "خصم 20% على جميع الطلبات",
        "topic": "ALL_CUSTOMERS",
        "channel": "FIREBASE",
        "status": "SENT",
        "readAt": "2024-01-14T15:00:00Z",
        "createdAt": "2024-01-14T10:00:00Z"
      }
    ],
    "total": 45
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications?page=1&limit=20"
}
```

### Response Example (Empty)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "data": [],
    "total": 0
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications"
}
```

---

## 5. Get Notification by ID

الحصول على إشعار محدد.

- **URL:** `/notifications/:id`
- **Method:** `GET`
- **Authentication:** Required

### URL Parameters

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| `id`      | number | ID الإشعار  |

### Request Example

```bash
GET /api/v1/notifications/45
Authorization: Bearer <token>
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 45,
    "type": "ORDER_UPDATE",
    "title": "تم تأكيد طلبك",
    "body": "تم تأكيد طلبك #123 وهو قيد التجهيز",
    "topic": null,
    "channel": "FIREBASE",
    "status": "SENT",
    "readAt": null,
    "createdAt": "2024-01-15T10:29:00Z"
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications/45"
}
```

### Response Example (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Notification recipient not found",
  "data": {},
  "timestamp": "2024-01-15T10:29:00Z",
  "path": "/api/v1/notifications/999"
}
```

---

## 6. Mark Notifications as Read

تعليم عدة إشعارات كمقروءة.

- **URL:** `/notifications/mark-read`
- **Method:** `POST`
- **Authentication:** Required

### Request Body

| Parameter         | Type     | Required | Description             |
| ----------------- | -------- | -------- | ----------------------- |
| `notificationIds` | number[] | Yes      | مصفوفة من IDs الإشعارات |

### Request Example

```bash
POST /api/v1/notifications/mark-read
Authorization: Bearer <token>
Content-Type: application/json

{
  "notificationIds": [45, 44, 43]
}
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Notifications marked as read",
  "data": {},
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications/mark-read"
}
```

### Response Example (Error - 400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "notificationIds must be a non-empty array",
  "data": {},
  "timestamp": "2024-01-15T10:29:00Z",
  "path": "/api/v1/notifications/mark-read"
}
```

---

## 7. Update Firebase Token

تحديث Firebase Token للمستخدم الحالي.

- **URL:** `/auth/firebase-token`
- **Method:** `POST`
- **Authentication:** Required

### Request Body

| Parameter       | Type   | Required | Description                     |
| --------------- | ------ | -------- | ------------------------------- |
| `firebaseToken` | string | No*      | Firebase Token الجديد           |
| `token`         | string | No*      | بديل لـ firebaseToken           |

\* يجب توفير واحد على الأقل من `firebaseToken` أو `token`

### Request Example

```bash
POST /api/v1/auth/firebase-token
Authorization: Bearer <token>
Content-Type: application/json

{
  "firebaseToken": "fcm_token_new_xxx"
}
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Firebase token updated successfully",
  "data": {
    "fcmTokenUpdated": true
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/auth/firebase-token"
}
```

**ملاحظة:** لدور `DELIVERY`، يتم أيضاً إرجاع `customToken` و `firebaseUid` بالإضافة إلى `fcmTokenUpdated`.

---

## 8. Pagination Structure

### Pagination Response

عند استخدام endpoint مع paginated result (مثل `GET /notifications`)، يكون الـ response بالشكل التالي (بعد معالجة `TransformInterceptor`):

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "data": [...],
    "total": 45
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "path": "/api/v1/notifications?page=1&limit=20"
}
```

| Field             | Type    | Description          |
| ----------------- | ------- | -------------------- |
| `data.data`       | array   | مصفوفة البيانات      |
| `data.total`      | number  | إجمالي عدد العناصر   |

**ملاحظة:** حقل `total` فقط هو المتاح حالياً. يتم تحديد `page` و `limit` عبر query parameters فقط.

---

## 9. Notification Status

### NotificationStatus Values

| Value       | Description  |
| ----------- | ------------ |
| `PENDING`   | قيد الانتظار |
| `SENT`      | تم الإرسال   |
| `FAILED`    | فشل الإرسال  |
| `DELIVERED` | تم التسليم   |

### RecipientStatus Values

| Value      | Description  |
| ---------- | ------------ |
| `PENDING`  | قيد الانتظار |
| `RECEIVED` | تم الاستلام  |
| `READ`     | تم القراءة   |

---

## 10. الإشعارات التلقائية (Automatic Notifications)

يرسل النظام إشعارات تلقائية في الحالات التالية:

### 10.1 إشعارات الطلبات (Order Notifications)

| نوع الإشعار        | الوصف         | المستلم         | التوقيت                        |
| ------------------ | ------------- | --------------- | ------------------------------ |
| `ORDER_CREATED`    | طلب جديد      | التاجر (المطعم) | عند إنشاء طلب جديد             |
| `ORDER_CONFIRMED`  | تأكيد الطلب   | العميل          | عند تأكيد الطلب من قبل التاجر  |
| `ORDER_SEARCHING`  | البحث عن سائق | العميل          | عند بدء البحث عن سائق          |
| `ORDER_ASSIGNED`   | تعيين سائق    | السائق          | عند تعيين سائق للطلب           |
| `ORDER_READY`      | الطلب جاهز    | السائق          | عند جاهزية الطلب للاستلام      |
| `ORDER_PICKED_UP`  | استلام الطلب  | العميل          | عند استلام الطلب من قبل السائق |
| `ORDER_ON_THE_WAY` | في الطريق     | العميل          | عند بدء توصيل الطلب            |
| `ORDER_DELIVERED`  | تم التسليم    | العميل          | عند وصول الطلب للعميل          |
| `ORDER_CANCELLED`  | إلغاء الطلب   | العميل          | عند إلغاء الطلب                |

### 10.2 إشعارات الحسابات (Auth Notifications)

| نوع الإشعار             | الوصف      | المستلم                | التوقيت                 |
| ----------------------- | ---------- | ---------------------- | ----------------------- |
| `DELIVERY_REGISTRATION` | تسجيل سائق | المدير (جميع المديرين) | عند تسجيل سائق جديد     |
| `DELIVERY_VERIFIED`     | تحقق سائق  | المدير (جميع المديرين) | عند التحقق من حساب سائق |
| `MERCHANT_REGISTRATION` | تسجيل مطعم | المدير (جميع المديرين) | عند تسجيل مطعم جديد     |
| `MERCHANT_VERIFIED`     | تحقق مطعم  | المدير (جميع المديرين) | عند التحقق من حساب مطعم |
| `OTP`                   | رمز التحقق | العميل                 | عند طلب التحقق بح OTP   |
| `WELCOME`               | ترحيب      | العميل                 | بعد التحقق من الحساب    |

---

## 11. Error Codes

### Notification Error Codes

| Code | Error Key                           | Description              |
| ---- | ----------------------------------- | ------------------------ |
| 5101 | NOTIFICATION_FAILED                 | فشل إرسال الإشعار        |
| 5102 | NOTIFICATION_FIREBASE_ERROR         | خطأ في خدمة Firebase     |
| 5103 | NOTIFICATION_FIREBASE_TOKEN_INVALID | Firebase Token غير صالح  |
| 5104 | NOTIFICATION_FIREBASE_TOKEN_MISSING | Firebase Token مفقود     |
| 5105 | NOTIFICATION_EMAIL_ERROR            | فشل إرسال البريد         |
| 5106 | NOTIFICATION_WHATSAPP_ERROR         | فشل إرسال الواتساب       |
| 5107 | NOTIFICATION_SMS_ERROR              | فشل إرسال SMS            |
| 5110 | NOTIFICATION_TOPIC_INVALID          | موضوع الإشعار غير صالح   |
| 5111 | NOTIFICATION_TYPE_INVALID           | نوع الإشعار غير صالح     |
| 5112 | NOTIFICATION_RECIPIENT_NOT_FOUND    | مستلم الإشعار غير موجود  |
| 5113 | NOTIFICATION_ALREADY_READ           | الإشعار مقروء سابقاً     |
| 5114 | NOTIFICATION_MARK_READ_FAILED       | فشل تعليم الإشعار كمقروء |
| 5115 | NOTIFICATION_TITLE_REQUIRED         | عنوان الإشعار مطلوب      |
| 5116 | NOTIFICATION_BODY_REQUIRED          | محتوى الإشعار مطلوب      |
| 5117 | NOTIFICATION_USER_NOT_FOUND         | المستخدم غير موجود       |

### User Error Codes Related to Notifications

| Code | Error Key                    | Description             |
| ---- | ---------------------------- | ----------------------- |
| 2007 | USER_FIREBASE_TOKEN_REQUIRED | Firebase Token مطلوب    |
| 2008 | USER_FIREBASE_TOKEN_UPDATED  | تم تحديث Firebase Token |

---

## 12. Entity Relationships

### NotificationLog Entity

```
notification_logs
├── id (PK)
├── userId (FK → users)
├── recipient (string)
├── channel (enum)
├── type (enum)
├── title (string)
├── body (text)
├── topic (enum, nullable)
├── content (text, nullable)
├── otpCode (varchar, nullable)
├── isUsed (boolean)
├── expiresAt (timestamp)
├── usedAt (timestamp)
├── status (enum)
├── orderId (int, nullable)
├── metadata (jsonb)
├── scheduledAt (timestamp)
├── sentAt (timestamp)
└── createdAt (timestamp)
```

### NotificationRecipient Entity

```
notification_recipients
├── id (PK)
├── notificationId (FK → notification_logs)
├── userId (FK → users)
├── receivedAt (timestamp)
├── readAt (timestamp)
├── status (enum)
└── createdAt (timestamp)
```

### Relationships Diagram

```
NotificationLog (1)
    │
    └── (OneToMany) ──→ NotificationRecipient (N)
                              │
                              └── (ManyToOne) ──→ User (N)
```

---

## 13. Notes

1. **التوثيق:** يتطلب توكن وصول صالح (Bearer Token)
2. **قنوات الإشعار:** Firebase هو الافتراضي والأكثر استخداماً
3. **الإشعارات المجدولة:** يمكن جدولة الإشعار لوقت لاحق باستخدام `scheduledAt`
4. **المواضيع:** تسمح بإرسال إشعار جماعي لمجموعة محددة من المستخدمين
5. **القراءة:** يمكن تعليم عدة إشعارات كمقروءة دفعة واحدة
6. **Firebase Token:** يجب تحديثه عند تسجيل دخول المستخدم الجديد
