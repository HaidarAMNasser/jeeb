# دليل الإدارة (Admin Panel) - إدارة التجار والسائقين

تاريخ التحديث: 2026-06-29

---

## 1. إعادة تعيين كلمة المرور (Admin Password Reset)

### 1.1 الوصف

يمكن للأدمن **إعادة تعيين كلمة مرور أي تاجر أو سائق** مباشرة بدون الحاجة لكلمة المرور القديمة.

### 1.2 الـ Endpoints

| الـ Endpoint | الوصف |
|---|---|
| `PATCH /users/merchants/:id/reset-password` | إعادة تعيين كلمة مرور تاجر |
| `PATCH /users/deliveries/:id/reset-password` | إعادة تعيين كلمة مرور سائق |

### 1.3 الـ Request

**Method:** `PATCH`

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Body:**
```json
{
  "password": "newStrongPassword123"
}
```

| الحقل | النوع | مطلوب | الوصف |
|---|---|---|---|
| `password` | string | ✅ | كلمة المرور الجديدة (6 أحرف كحد أدنى) |

### 1.4 الـ Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Password reset successfully",
  "data": {
    "id": 10,
    "firstName": "Ahmed",
    "lastName": "Mohammed",
    "email": "merchant@example.com",
    "phone": "+966501234567",
    "role": "MERCHANT",
    "isActive": true,
    "createdAt": "2026-01-01T00:00:00.000Z",
    "updatedAt": "2026-06-29T00:00:00.000Z"
  },
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/users/merchants/10/reset-password"
}
```

### 1.5 الأخطاء

| الحالة | `message` | السبب |
|---|---|---|
| 401 | Unauthorized | التوكن غير صالح أو منتهي |
| 403 | Forbidden | الـ user ليس أدمن |
| 404 | User with ID X not found | المستخدم غير موجود |

---

## 2. إنشاء تاجر (Admin Create MERCHANT)

### 2.1 الوصف

يمكن للأدمن إنشاء حساب تاجر جديد مباشرة عبر هذا الـ endpoint. الحساب يتم إنشاؤه **موثّق تلقائيًا** و **نشط**.

### 2.2 الـ Endpoint

```
POST /users/merchants
```

### 2.3 الـ Request

**Method:** `POST`

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Body:**
```json
{
  "email": "merchant@example.com",
  "password": "password123",
  "firstName": "Ahmed",
  "lastName": "Mohammed",
  "phone": "+966501234567",
  "countryId": 1,
  "cityId": 1,
  "areaId": 1,
  "address": "Riyadh, Saudi Arabia",
  "notificationChannel": "EMAIL"
}
```

| الحقل | النوع | مطلوب | الوصف |
|---|---|---|---|
| `email` | string | ✅ | البريد الإلكتروني |
| `password` | string | ✅ | كلمة المرور (6 أحرف كحد أدنى) |
| `firstName` | string | ✅ | الاسم الأول |
| `lastName` | string | ✅ | اسم العائلة |
| `phone` | string | ✅ | رقم الهاتف |
| `countryId` | number | ❌ | معرف الدولة |
| `cityId` | number | ❌ | معرف المدينة |
| `areaId` | number | ❌ | معرف المنطقة |
| `address` | string | ❌ | العنوان |
| `notificationChannel` | enum | ❌ | `EMAIL`, `WHATSAPP`, `FIREBASE`, `SMS` |

### 2.4 الـ Response (201 Created)

```json
{
  "id": 10,
  "firstName": "Ahmed",
  "lastName": "Mohammed",
  "email": "merchant@example.com",
  "phone": "+966501234567",
  "role": "MERCHANT",
  "verifiedAt": "2026-06-29T12:00:00.000Z",
  "createdAt": "2026-06-29T12:00:00.000Z",
  "updatedAt": "2026-06-29T12:00:00.000Z"
}
```

### 2.5 الأخطاء

| الحالة | `message` | السبب |
|---|---|---|
| 400 | Validation error | أحد الحقول المطلوبة ناقص أو غير صالح |
| 401 | Unauthorized | التوكن غير صالح أو منتهي |
| 403 | Forbidden | الـ user ليس أدمن |
| 409 | Email already exists | البريد الإلكتروني مسجل مسبقًا |

---

## 3. إنشاء سائق (Admin Create DELIVERY)

### 3.1 الوصف

يمكن للأدمن إنشاء حساب سائق توصيل جديد. الحساب يتم إنشاؤه **موثّق تلقائيًا** ويصبح جاهزًا للعمل.

### 3.2 الـ Endpoint

```
POST /users/deliveries
```

### 3.3 الـ Request

**Method:** `POST`

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Body:**
```json
{
  "email": "delivery@example.com",
  "password": "password123",
  "firstName": "Khalid",
  "lastName": "Ali",
  "phone": "+966501234568",
  "countryId": 1,
  "cityId": 1,
  "areaId": 1,
  "address": "Riyadh, Saudi Arabia",
  "isActive": true,
  "isOnline": true,
  "notificationChannel": "FIREBASE",
  "currentLat": 24.7136,
  "currentLng": 46.6753,
  "location": {
    "lat": 24.7136,
    "lng": 46.6753
  },
  "birthday": "1990-05-15",
  "firebaseToken": "fcm_device_token_here"
}
```

| الحقل | النوع | مطلوب | الوصف |
|---|---|---|---|
| `email` | string | ✅ | البريد الإلكتروني |
| `password` | string | ✅ | كلمة المرور (6 أحرف كحد أدنى) |
| `firstName` | string | ✅ | الاسم الأول |
| `lastName` | string | ✅ | اسم العائلة |
| `phone` | string | ✅ | رقم الهاتف |
| `countryId` | number | ❌ | معرف الدولة |
| `cityId` | number | ❌ | معرف المدينة |
| `areaId` | number | ❌ | معرف المنطقة |
| `address` | string | ❌ | العنوان |
| `isActive` | boolean | ❌ | حالة التفعيل (افتراضي: false) |
| `isOnline` | boolean | ❌ | حالة الاتصال (افتراضي: false) |
| `notificationChannel` | enum | ❌ | `EMAIL`, `WHATSAPP`, `FIREBASE`, `SMS` |
| `currentLat` | number | ❌ | خط العرض الحالي |
| `currentLng` | number | ❌ | خط الطول الحالي |
| `location` | object | ❌ | `{ "lat": number, "lng": number }` |
| `birthday` | string | ❌ | تاريخ الميلاد (YYYY-MM-DD) |
| `firebaseToken` | string | ❌ | Firebase Cloud Messaging token |

### 3.4 الـ Response (201 Created)

```json
{
  "id": 20,
  "firstName": "Khalid",
  "lastName": "Ali",
  "email": "delivery@example.com",
  "phone": "+966501234568",
  "role": "DELIVERY",
  "isActive": true,
  "isOnline": true,
  "verifiedAt": "2026-06-29T12:00:00.000Z",
  "createdAt": "2026-06-29T12:00:00.000Z",
  "updatedAt": "2026-06-29T12:00:00.000Z"
}
```

### 3.5 الأخطاء

| الحالة | `message` | السبب |
|---|---|---|
| 400 | Validation error | أحد الحقول المطلوبة ناقص أو غير صالح |
| 401 | Unauthorized | التوكن غير صالح أو منتهي |
| 403 | Forbidden | الـ user ليس أدمن |
| 409 | Email already exists | البريد الإلكتروني مسجل مسبقًا |

---

## 4. جدول الـ Endpoints الموجزة

| الـ Endpoint | Method | الوصف |
|---|---|---|
| `/users/merchants` | POST | إنشاء تاجر جديد |
| `/users/merchants/:id/reset-password` | PATCH | إعادة تعيين كلمة مرور تاجر |
| `/users/merchants/:id` | PATCH | تحديث بيانات تاجر |
| `/users/merchants/:id` | DELETE | حذف تاجر |
| `/users/merchants/:id/confirm` | PATCH | تفعيل حساب تاجر |
| `/users/deliveries` | POST | إنشاء سائق جديد |
| `/users/deliveries/:id/reset-password` | PATCH | إعادة تعيين كلمة مرور سائق |
| `/users/deliveries/:id` | PATCH | تحديث بيانات سائق |
| `/users/deliveries/:id` | DELETE | حذف سائق |
| `/users/deliveries/:id/confirm` | PATCH | تفعيل حساب سائق |

> **ملاحظة:** جميع الـ endpoints تتطلب `Authorization: Bearer <admin_token>` ودور `ADMIN`.
