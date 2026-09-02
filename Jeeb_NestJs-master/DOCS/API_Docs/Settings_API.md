# Settings API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة

- **جميع عمليات الكتابة (Update, Delete)** محصورة فقط بدور **المدير (ADMIN)**.
- **جميع عمليات القراءة** متاحة لأي دور.

---

## 1. Get All Settings

الحصول على قائمة جميع الإعدادات.

- **URL:** `/settings`
- **Method:** `GET`
- **Roles:** جميع الأدوار (ADMIN, MERCHANT, CUSTOMER, DELIVERY)

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "defaultProductCommissionRate": {
      "id": 7,
      "key": "defaultProductCommissionRate",
      "value": 10,
      "description": "Default commission rate for products",
      "isActive": true,
      "createdAt": "2026-03-10T06:43:59.482Z",
      "updatedAt": "2026-03-10T06:43:59.482Z"
    },
    "productsAutoConfirmed": {
      "id": 8,
      "key": "productsAutoConfirmed",
      "value": true,
      "description": "Auto-confirm products for customers",
      "isActive": true,
      "createdAt": "2026-03-10T06:43:59.482Z",
      "updatedAt": "2026-03-10T06:43:59.482Z"
    },
    "supportPhone": {
      "id": 9,
      "key": "supportPhone",
      "value": "+963912345678",
      "description": "Customer support phone",
      "isActive": true,
      "createdAt": "2026-03-10T06:43:59.482Z",
      "updatedAt": "2026-03-10T06:43:59.482Z"
    },
    "supportEmail": {
      "id": 10,
      "key": "supportEmail",
      "value": "support@jeeb.com",
      "description": "Customer support email",
      "isActive": true,
      "createdAt": "2026-03-10T06:43:59.482Z",
      "updatedAt": "2026-03-10T06:43:59.482Z"
    },
    "whatsappNumber": {
      "id": 11,
      "key": "whatsappNumber",
      "value": "+963912345678",
      "description": "WhatsApp contact number",
      "isActive": true,
      "createdAt": "2026-03-10T06:43:59.482Z",
      "updatedAt": "2026-03-10T06:43:59.482Z"
    }
  }
}
```

---

## 2. Get Setting By Key

تحديث عدة إعدادات دفعة واحدة.

- **URL:** `/settings`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: application/json`
- **Roles:** `ADMIN` فقط

### Payload (Request Body)

```json
[
  {
    "key": "defaultProductCommissionRate",
    "value": 15
  },
  {
    "key": "supportPhone",
    "value": "+963911111111"
  },
  {
    "key": "whatsappNumber",
    "value": "+963922222222"
  }
]
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 2,
      "key": "defaultProductCommissionRate",
      "value": 15,
      "description": "Default commission rate for products",
      "isActive": true,
      "createdAt": "2026-03-10T10:00:00.000Z",
      "updatedAt": "2026-03-10T12:00:00.000Z"
    },
    {
      "id": 3,
      "key": "supportPhone",
      "value": "+963911111111",
      "description": "Customer support phone",
      "isActive": true,
      "createdAt": "2026-03-10T10:00:00.000Z",
      "updatedAt": "2026-03-10T12:00:00.000Z"
    }
  ]
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "data": {}
}
```

---

## 3. Delete Setting

حذف إعداد.

- **URL:** `/settings/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
- **Roles:** `ADMIN` فقط

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/settings/someKey"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Setting with ID \"someKey\" not found",
  "data": {}
}
```

---

## قائمة الإعدادات الافتراضية

### إعدادات التوصيل (Delivery Settings)

| المفتاح                       | النوع  | القيمة الافتراضية | الوصف                                |
| ----------------------------- | ------ | ----------------- | ------------------------------------ |
| `driverRequestTimeoutSeconds` | number | 180               | وقت الانتظار بالسؤال للتوصيل (ثانية) |
| `driverRequestBatchSize`      | number | 3                 | عدد السائقين في كل دفعة              |
| `initialSearchRadius`         | number | 5.0               | نصف البحث الابتدائي (كم)             |
| `searchRadiusIncrement`       | number | 2.0               | زيادة نصف البحث لكل دفعة             |
| `maxSearchRadius`             | number | 20.0              | أقصى نصف بحث                         |
| `deliveryTipPerKilometer`     | number | 500               | مبلغ البقشيش لكل كيلومتر             |

### إعدادات المنتجات (Products Settings)

| المفتاح                        | النوع   | القيمة الافتراضية | الوصف                            |
| ------------------------------ | ------- | ----------------- | -------------------------------- |
| `externalOrderMarkupRate`      | number  | 0.0               | نسبة العمولة للطلبات الخارجية    |
| `defaultProductCommissionRate` | number  | 10.0              | نسبة العمولة الافتراضية للمنتجات |
| `productsAutoConfirmed`        | boolean | true              | تأكيد المنتجات تلقائياً          |

### إعدادات الدعم (Support Settings)

| المفتاح              | النوع  | القيمة الافتراضية | الوصف                   |
| -------------------- | ------ | ----------------- | ----------------------- |
| `supportPhone`       | string | +963912345678     | رقم الدعم               |
| `supportEmail`       | string | support@jeeb.com  | البريد الإلكتروني للدعم |
| `whatsappNumber`     | string | +963912345678     | رقم الواتساب            |
| `websiteUrl`         | string | https://jeeb.com  | رابط الموقع             |
| `address`            | string | Damascus, Syria   | العنوان                 |
| `termsAndConditions` | string |                   | الشروط والأحكام         |
| `privacyPolicy`      | string |                   | سياسة الخصوصية          |
| `aboutUs`            | string |                   | من نحن                  |

### إعدادات نظام الولاء (Loyalty System Settings)

| المفتاح                         | النوع  | القيمة الافتراضية | الوصف                                        |
| ------------------------------- | ------ | ----------------- | -------------------------------------------- |
| `global_loyalty_threshold`      | number | 5                 | عدد الطلبات المطلوبة للحصول على النقاط       |
| `global_loyalty_points`         | number | 100               | عدد النقاط الممنوحة عند الوصول للـ threshold |
| `global_loyalty_redeem_points`  | number | 100               | النقاط المطلوبة لاستبدال النقاط بخصم         |
| `global_loyalty_discount_value` | number | 1000              | قيمة الخصم عند استبدال النقاط                |

**ملاحظة:** نظام الولاء يعمل بشكل عالمي عبر جميع المتاجر. العميل يحصل على نقاط عند إكماله لعدد معين من الطلبات (threshold).

---

## ملاحظات

1. يمكن إضافة إعدادات جديدة ديناميكياً دون الحاجة لتعديل قاعدة البيانات
2. قيمة الإعداد يمكن أن تكون أي نوع (string, number, boolean, object)
3. الإعدادات محفوظة في جدول واحد مع هيكل key-value
