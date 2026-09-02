# Delivery Drivers API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة ودور الصلاحيات

### Office Owner (صاحب المكتب)

- إنشاء سائق توصيل جديد تابع له
- عرض جميع سائقي التوصيل التابعين له مع البحث والتصفية
- عرض تفاصيل سائق توصيل محدد
- تعديل بيانات سائق توصيل تابع له
- حذف سائق توصيل تابع له (حذف نهائي - Hard Delete)

### ADMIN

- ✅ عرض جميع سائقي التوصيل في النظام (من جميع المكاتب)
- ✅ البحث والتصفية في جميع سائقي التوصيل
- ✅ عرض تفاصيل أي سائق توصيل
- ✅ فلترة حسب المكتب (officeOwnerId) والدولة والمدينة
- ✅ **إنشاء سائق توصيل جديد** وتعيينه لأي صاحب مكتب
- ✅ **تعديل بيانات أي سائق توصيل**
- ✅ **حذف أي سائق توصيل** (حذف نهائي - Hard Delete)
- ✅ **تفعيل سائق توصيل** (Confirm)

**ملاحظة أمنية:**

- Office Owner يمكنه فقط إدارة سائقي التوصيل التابعين له
- **ADMIN يمكنه رؤية وإدارة جميع سائقي التوصيل** (CRUD كامل)

المسارات معرفة في `src/common/constants/api-routes.constants.ts`.

---

## جدول محتويات ENDPOINTS

| #   | العملية | Office Owner | ADMIN | Endpoint |
| --- | ------- | ------------ | ----- | -------- |
| 1   | إنشاء سائق | ✅ | ✅ | `POST /users/deliveries` |
| 2   | عرض الكل | ✅ (خاصته) | ✅ (الكل) | `GET /users/deliveries` |
| 3   | عرض واحد | ✅ (خاصته) | ✅ (أي سائق) | `GET /users/deliveries/:id` |
| 4   | تعديل | ✅ (خاصته) | ✅ (أي سائق) | `PATCH /users/deliveries/:id` |
| 5   | حذف | ✅ (خاصته) | ✅ (أي سائق) | `DELETE /users/deliveries/:id` |
| 6   | تفعيل سائق | ❌ | ✅ | `PATCH /users/deliveries/:id/confirm` |
| 7   | إعادة تعيين كلمة المرور | ❌ | ✅ | `PATCH /users/deliveries/:id/reset-password` |

---

## 1. Create Delivery Driver (Office Owner & ADMIN)

إنشاء سائق توصيل جديد.

**Office Owner:** ينشئ سائقاً تابعاً له مباشرة (`officeOwnerId` اختياري — إذا لم يتم توفيره يستخدم معرف المستخدم الحالي).

**ADMIN:** ينشئ سائقاً ويعيّنه لأي صاحب مكتب عبر `officeOwnerId` في payload (اختياري).

- **URL:** `/users/deliveries`
- **Method:** `POST`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `OFFICE_OWNER` أو `ADMIN`
- **Content-Type:** `multipart/form-data`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Payload (Form Data)

| Field | Type | Required | Description |
| :-------------------- | :------ | :------- | :---------------------------------------------------------------------------------------- |
| `email` | String | Yes | البريد الإلكتروني (فريد). Validation: `@IsEmail()` |
| `password` | String | Yes | كلمة المرور. Validation: `@MinLength(6)` |
| `firstName` | String | Yes | الاسم الأول. Validation: `@IsString()` |
| `lastName` | String | Yes | اسم العائلة. Validation: `@IsString()` |
| `phone` | String | Yes | رقم الهاتف. Validation: `@IsString()` |
| `countryId` | Number | No | معرف الدولة. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `cityId` | Number | No | معرف المدينة. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `areaId` | Number | No | معرف المنطقة. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `address` | String | No | العنوان. Validation: `@IsString()` |
| `notificationChannel` | Enum | No | قناة الإشعارات. Validation: `@IsEnum(NotificationChannel)`. القيم: `EMAIL`, `SMS`, `WHATSAPP`, `FIREBASE` |
| `birthday` | String | No | تاريخ الميلاد (YYYY-MM-DD). Validation: `@IsString()` |
| `officeOwnerId` | Number | No | معرف صاحب المكتب لتعيين السائق له. لـ ADMIN: يمكن تعيين لأي صاحب مكتب. لـ Office Owner: إذا لم يتم توفيره يستخدم معرف المستخدم الحالي. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `location` | String | No | الموقع الجغرافي (JSON string: `{"lat": 33.5138, "lng": 36.2765}`) |
| `image` | File | No | صورة الملف الشخصي. الأنواع المدعومة: `jpeg`, `png`, `gif`, `webp`. الحد الأقصى: 5MB. تتم معالجة الصورة تلقائياً إلى عدة أحجام (original, mobile, thumbnail) |

### Office Owner Example

```bash
curl -X POST http://localhost:3000/api/v1/users/deliveries \
  -H "Authorization: Bearer <office_owner_token>" \
  -F "email=delivery1@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=Ahmed" \
  -F "lastName=Ali" \
  -F "phone=+966501234567" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Riyadh, Saudi Arabia" \
  -F "birthday=1990-05-15" \
  -F "notificationChannel=WHATSAPP" \
  -F "image=@/path/to/profile.jpg"
```

### ADMIN Example (with officeOwnerId)

```bash
curl -X POST http://localhost:3000/api/v1/users/deliveries \
  -H "Authorization: Bearer <admin_token>" \
  -F "email=delivery_admin@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=Ahmed" \
  -F "lastName=Ali" \
  -F "phone=+966509998877" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Riyadh, Saudi Arabia" \
  -F "birthday=1990-05-15" \
  -F "notificationChannel=WHATSAPP" \
  -F "officeOwnerId=5" \
  -F "image=@/path/to/profile.jpg"
```

### ADMIN Example (without officeOwnerId)

```bash
curl -X POST http://localhost:3000/api/v1/users/deliveries \
  -H "Authorization: Bearer <admin_token>" \
  -F "email=delivery_unassigned@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=Ahmed" \
  -F "lastName=Ali" \
  -F "phone=+966509998888" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Riyadh, Saudi Arabia" \
  -F "birthday=1990-05-15" \
  -F "notificationChannel=WHATSAPP" \
  -F "image=@/path/to/profile.jpg"
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Delivery driver created successfully",
  "data": {
    "id": 15,
    "firstName": "Ahmed",
    "lastName": "Ali",
    "email": "delivery1@example.com",
    "phone": "+966501234567",
    "role": "DELIVERY",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY",
      "callingCode": "+963",
      "currencyCode": "SYP",
      "currencySymbol": "£",
      "currencySmallestUnit": "Piastre",
      "currencyFactor": 100,
      "isActive": true
    },
    "cityId": 1,
    "areaId": null,
    "area": null,
    "city": {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    },
    "address": "Riyadh, Saudi Arabia",
    "isOnline": true,
    "isActive": false,
    "verifiedAt": "2026-02-28T06:01:16.471Z",
    "currentLat": null,
    "currentLng": null,
    "birthday": "1990-05-15",
    "createdAt": "2026-02-28T06:01:16.482Z",
    "updatedAt": "2026-02-28T06:01:16.482Z",
    "deletedAt": null,
    "officeOwner": null,
    "officeOwnerId": 5,
    "images": [
      {
        "id": 5,
        "entityType": "USER",
        "entityId": 15,
        "url": "users/15/1772259304792_profile.webp",
        "mobileUrl": "users/15/1772259304792_profile_mobile.webp",
        "thumbnailUrl": "users/15/1772259304792_profile_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-02-28T06:01:16.500Z",
        "updatedAt": "2026-02-28T06:01:16.500Z"
      }
    ]
  },
  "timestamp": "2026-02-28T06:01:16.824Z",
  "path": "/api/v1/users/deliveries"
}
```

### ملاحظات التنفيذ

- يتم تشفير كلمة المرور تلقائياً باستخدام `bcrypt.hash(password, 10)` قبل الحفظ.
- يتم تفعيل الحساب تلقائياً (`verifiedAt: new Date()`).
- `isActive` تكون `false` افتراضياً — يجب على ADMIN تفعيل السائق عبر endpoint التفعيل.
- صورة الملف الشخصي تُعالج إلى ثلاثة أحجام: original, mobile, thumbnail.
- إذا تم تقديم `officeOwnerId`، يتم تعيين السائق لذلك المكتب. إذا لم يتم تقديمه (والمستخدم Office Owner)، يتم استخدام معرف المستخدم الحالي.

### Response (Error - 409 Conflict)

إذا كان البريد الإلكتروني موجود مسبقاً:

```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "error": "Conflict"
}
```

### Response (Error - 422 Unprocessable Entity)

إذا كانت الصورة غير صالحة (نوع أو حجم):

```json
{
  "statusCode": 422,
  "message": "Validation failed (expected type is /(jpg|jpeg|png|webp)/)",
  "error": "Unprocessable Entity"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن للمستخدم الدور المطلوب:

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden"
}
```

---

## 2. Get All Delivery Drivers (Office Owner - Own Drivers Only)

إرجاع قائمة سائقي التوصيل التابعين لصاحب المكتب مع دعم الفلترة والبحث والترقيم.

- **URL:** `/users/deliveries`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `OFFICE_OWNER`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Query Parameters

| Parameter | Type | Required | Default | Description |
| :-------- | :--- | :------- | :------ | :---------- |
| `page` | Number | No | `1` | رقم الصفحة |
| `limit` | Number | No | `10` | عدد العناصر في الصفحة |
| `search` | String | No | - | بحث بالاسم أو البريد الإلكتروني أو الهاتف. Validation: case-insensitive على `firstName`, `lastName`, `email`, `phone` |
| `status` | Enum | No | - | فلترة حسب حالة التفعيل. القيم: `ACTIVE`, `INACTIVE` |
| `cityId` | Number | No | - | فلترة حسب المدينة |

### Example URL

```
GET /users/deliveries?page=1&limit=10&search=ahmed&status=ACTIVE
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 15,
      "firstName": "Ahmed",
      "lastName": "Ali",
      "email": "delivery1@example.com",
      "phone": "+966501234567",
      "role": "DELIVERY",
      "notificationChannel": "WHATSAPP",
      "countryId": 1,
      "country": {
        "id": 1,
        "name": { "ar": "سوريا", "en": "Syria" },
        "code": "SY",
        "callingCode": "+963",
        "currencyCode": "SYP",
        "currencySymbol": "£",
        "currencySmallestUnit": "Piastre",
        "currencyFactor": 100,
        "isActive": true
      },
      "cityId": 1,
      "areaId": null,
      "area": null,
      "city": {
        "id": 1,
        "name": { "ar": "دمشق", "en": "Damascus" },
        "countryId": 1
      },
      "address": "Riyadh, Saudi Arabia",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-02-28T06:01:16.471Z",
      "currentLat": null,
      "currentLng": null,
      "birthday": "1990-05-15",
      "createdAt": "2026-02-28T06:01:16.482Z",
      "updatedAt": "2026-02-28T06:01:16.482Z",
      "deletedAt": null,
      "officeOwner": null,
      "officeOwnerId": 5,
      "images": [
        {
          "id": 5,
          "entityType": "USER",
          "entityId": 15,
          "url": "users/15/1772259304792_profile.webp",
          "mobileUrl": "users/15/1772259304792_profile_mobile.webp",
          "thumbnailUrl": "users/15/1772259304792_profile_thumb.webp",
          "isMain": true,
          "displayOrder": 0,
          "createdAt": "2026-02-28T06:01:16.500Z",
          "updatedAt": "2026-02-28T06:01:16.500Z"
        }
      ]
    }
  ],
  "pagination": {
    "total": 5,
    "page": 1,
    "limit": 10,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "timestamp": "2026-02-28T06:01:16.824Z",
  "path": "/api/v1/users/deliveries"
}
```

---

## 3. Get All Delivery Drivers (ADMIN - All Drivers)

إرجاع قائمة جميع سائقي التوصيل في النظام مع دعم الفلترة والبحث والترقيم (ADMIN فقط).

- **URL:** `/users/deliveries`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Query Parameters

| Parameter | Type | Required | Default | Description |
| :-------- | :--- | :------- | :------ | :---------- |
| `page` | Number | No | `1` | رقم الصفحة |
| `limit` | Number | No | `10` | عدد العناصر في الصفحة |
| `search` | String | No | - | بحث بالاسم أو البريد الإلكتروني أو الهاتف |
| `countryId` | Number | No | - | فلترة حسب الدولة |
| `cityId` | Number | No | - | فلترة حسب المدينة |
| `isOnline` | Boolean | No | - | فلترة حسب حالة الاتصال |
| `officeOwnerId` | Number | No | - | فلترة حسب صاحب المكتب |

### Example URL

```
GET /users/deliveries?page=1&limit=10&officeOwnerId=5&isOnline=true&search=ahmed
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 15,
      "email": "delivery1@example.com",
      "firstName": "Ahmed",
      "lastName": "Ali",
      "phone": "+966501234567",
      "role": "DELIVERY",
      "notificationChannel": "WHATSAPP",
      "countryId": 1,
      "cityId": 1,
      "address": "Riyadh, Saudi Arabia",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-02-28T06:01:16.471Z",
      "currentLat": null,
      "currentLng": null,
      "birthday": "1990-05-15",
      "createdAt": "2026-02-28T06:01:16.482Z",
      "updatedAt": "2026-02-28T06:01:16.482Z",
      "deletedAt": null,
      "officeOwnerId": 5,
      "officeOwner": {
        "id": 5,
        "firstName": "Mohammed",
        "lastName": "Office",
        "email": "office@example.com"
      },
      "images": [
        {
          "id": 5,
          "entityType": "USER",
          "entityId": 15,
          "url": "users/15/1772259304792_profile.webp",
          "mobileUrl": "users/15/1772259304792_profile_mobile.webp",
          "thumbnailUrl": "users/15/1772259304792_profile_thumb.webp",
          "isMain": true,
          "displayOrder": 0,
          "createdAt": "2026-02-28T06:01:16.500Z",
          "updatedAt": "2026-02-28T06:01:16.500Z"
        }
      ]
    }
  ],
  "pagination": {
    "total": 25,
    "page": 1,
    "limit": 10,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPreviousPage": false
  },
  "timestamp": "2026-02-28T06:01:16.824Z",
  "path": "/api/v1/users/deliveries"
}
```

---

## 4. Get One Delivery Driver (Office Owner)

الحصول على تفاصيل سائق توصيل محدد تابع لصاحب المكتب.

- **URL:** `/users/deliveries/:id`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `OFFICE_OWNER`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "firstName": "Ahmed",
    "lastName": "Ali",
    "email": "delivery1@example.com",
    "phone": "+966501234567",
    "role": "DELIVERY",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY",
      "callingCode": "+963",
      "currencyCode": "SYP",
      "currencySymbol": "£",
      "currencySmallestUnit": "Piastre",
      "currencyFactor": 100,
      "isActive": true
    },
    "cityId": 1,
    "areaId": null,
    "area": null,
    "city": {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    },
    "address": "Riyadh, Saudi Arabia",
    "isOnline": true,
    "isActive": true,
    "verifiedAt": "2026-02-28T06:01:16.471Z",
    "currentLat": null,
    "currentLng": null,
    "birthday": "1990-05-15",
    "createdAt": "2026-02-28T06:01:16.482Z",
    "updatedAt": "2026-02-28T06:01:16.482Z",
    "deletedAt": null,
    "officeOwner": null,
    "officeOwnerId": 5,
    "images": [
      {
        "id": 5,
        "entityType": "USER",
        "entityId": 15,
        "url": "users/15/1772259304792_profile.webp",
        "mobileUrl": "users/15/1772259304792_profile_mobile.webp",
        "thumbnailUrl": "users/15/1772259304792_profile_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-02-28T06:01:16.500Z",
        "updatedAt": "2026-02-28T06:01:16.500Z"
      }
    ]
  },
  "timestamp": "2026-02-28T06:01:16.824Z",
  "path": "/api/v1/users/deliveries/15"
}
```

### Response (Error - 404 Not Found)

إذا لم يكن السائق موجوداً أو لا يتبع لصاحب المكتب:

```json
{
  "statusCode": 404,
  "message": "Delivery driver with ID 99 not found",
  "error": "Not Found"
}
```

---

## 5. Get One Delivery Driver (ADMIN)

الحصول على تفاصيل أي سائق توصيل في النظام (ADMIN فقط).

- **URL:** `/users/deliveries/:id`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "firstName": "Ahmed",
    "lastName": "Ali",
    "email": "delivery1@example.com",
    "phone": "+966501234567",
    "role": "DELIVERY",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY",
      "callingCode": "+963",
      "currencyCode": "SYP",
      "currencySymbol": "£",
      "currencySmallestUnit": "Piastre",
      "currencyFactor": 100,
      "isActive": true
    },
    "cityId": 1,
    "areaId": null,
    "area": null,
    "city": {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    },
    "address": "Riyadh, Saudi Arabia",
    "isOnline": true,
    "isActive": true,
    "verifiedAt": "2026-02-28T06:01:16.471Z",
    "currentLat": null,
    "currentLng": null,
    "birthday": "1990-05-15",
    "createdAt": "2026-02-28T06:01:16.482Z",
    "updatedAt": "2026-02-28T06:01:16.482Z",
    "deletedAt": null,
    "officeOwner": {
      "id": 5,
      "firstName": "Mohammed",
      "lastName": "Office",
      "email": "office@example.com"
    },
    "officeOwnerId": 5,
    "images": [
      {
        "id": 5,
        "entityType": "USER",
        "entityId": 15,
        "url": "users/15/1772259304792_profile.webp",
        "mobileUrl": "users/15/1772259304792_profile_mobile.webp",
        "thumbnailUrl": "users/15/1772259304792_profile_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-02-28T06:01:16.500Z",
        "updatedAt": "2026-02-28T06:01:16.500Z"
      }
    ]
  },
  "timestamp": "2026-02-28T06:01:16.824Z",
  "path": "/api/v1/users/deliveries/15"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found",
  "error": "Not Found"
}
```

---

## 6. Update Delivery Driver (Office Owner & ADMIN)

تحديث بيانات سائق توصيل.

**Office Owner:** يمكنه تعديل سائقيه فقط.

**ADMIN:** يمكنه تعديل أي سائق في النظام.

- **URL:** `/users/deliveries/:id`
- **Method:** `PATCH`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `OFFICE_OWNER` أو `ADMIN`
- **Content-Type:** `multipart/form-data`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### Payload (Form Data)

| Field | Type | Description |
| :-------------------- | :------ | :------------------------------------------------------ |
| `email` | String | بريد إلكتروني جديد (يجب أن يكون فريد). Validation: `@IsEmail()` |
| `firstName` | String | الاسم الأول الجديد. Validation: `@IsString()` |
| `lastName` | String | اسم العائلة الجديد. Validation: `@IsString()` |
| `phone` | String | رقم الهاتف الجديد. Validation: `@IsString()` |
| `password` | String | كلمة المرور الجديدة. Validation: `@MinLength(6)` |
| `countryId` | Number | معرف الدولة الجديد. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `cityId` | Number | معرف المدينة الجديد. Validation: `@IsNumber()` مع `@Type(() => Number)` |
| `address` | String | العنوان الجديد. Validation: `@IsString()` |
| `notificationChannel` | Enum | قناة الإشعارات. Validation: `@IsEnum(NotificationChannel)`. القيم: `EMAIL`, `SMS`, `WHATSAPP`, `FIREBASE` |
| `birthday` | String | تاريخ الميلاد (YYYY-MM-DD) |
| `isActive` | String | حالة التفعيل (`true`/`false`). يتطلب دور ADMIN. Validation: `@IsString()` |
| `isOnline` | String | حالة الاتصال (`true`/`false`). Validation: `@IsString()` |
| `location` | String | الموقع الجغرافي (JSON string: `{"lat": 33.5138, "lng": 36.2765}`) |
| `image` | File | صورة الملف الشخصي الجديدة. سيتم حذف الصورة القديمة تلقائياً. الأنواع المدعومة: `jpeg`, `png`, `gif`, `webp`. الحد الأقصى: 5MB |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/users/deliveries/15 \
  -H "Authorization: Bearer <office_owner_token>" \
  -F "firstName=Ahmed Updated" \
  -F "lastName=Ali Updated" \
  -F "phone=+966509876543" \
  -F "image=@/path/to/new_profile.jpg"
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Delivery driver updated successfully",
  "data": {
    "id": 15,
    "firstName": "Ahmed Updated",
    "lastName": "Ali Updated",
    "email": "delivery1@example.com",
    "phone": "+966509876543",
    "role": "DELIVERY",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY",
      "callingCode": "+963",
      "currencyCode": "SYP",
      "currencySymbol": "£",
      "currencySmallestUnit": "Piastre",
      "currencyFactor": 100,
      "isActive": true
    },
    "cityId": 1,
    "areaId": null,
    "area": null,
    "city": {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    },
    "address": "Riyadh, Saudi Arabia",
    "isOnline": true,
    "isActive": true,
    "verifiedAt": "2026-02-28T06:01:16.471Z",
    "currentLat": null,
    "currentLng": null,
    "birthday": "1990-05-15",
    "createdAt": "2026-02-28T06:01:16.482Z",
    "updatedAt": "2026-02-28T06:05:00.000Z",
    "deletedAt": null,
    "officeOwner": null,
    "officeOwnerId": 5,
    "images": [
      {
        "id": 6,
        "entityType": "USER",
        "entityId": 15,
        "url": "users/15/1234567891_updated.webp",
        "mobileUrl": "users/15/1234567891_updated_mobile.webp",
        "thumbnailUrl": "users/15/1234567891_updated_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-02-28T06:05:00.100Z",
        "updatedAt": "2026-02-28T06:05:00.100Z"
      }
    ]
  },
  "timestamp": "2026-02-28T06:05:00.200Z",
  "path": "/api/v1/users/deliveries/15"
}
```

### ملاحظات التنفيذ

- `isActive` يمكن تغييره فقط من قبل ADMIN. عند تمريره من Office Owner، قد يتم تجاهله.
- إذا تم تمرير `password`، يتم تشفيره تلقائياً باستخدام `bcrypt.hash()` قبل الحفظ.
- إذا تم تقديم صورة جديدة، يتم حذف الصورة القديمة تلقائياً ورفع الجديدة مع معالجتها إلى ثلاثة أحجام.
- يتم استخدام `Object.assign(user, updateDto)` لتحديث الحقول ثم `userRepository.save(user)`.

### Response (Error - 404 Not Found)

إذا لم يكن السائق موجوداً أو لا يتبع لصاحب المكتب:

```json
{
  "statusCode": 404,
  "message": "Delivery driver with ID 99 not found",
  "error": "Not Found"
}
```

### Response (Error - 409 Conflict)

إذا كان البريد الإلكتروني موجود مسبقاً:

```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "error": "Conflict"
}
```

---

## 7. Delete Delivery Driver (Office Owner & ADMIN)

حذف سائق توصيل (حذف نهائي - Hard Delete).

**Office Owner:** يمكنه حذف سائقيه فقط.

**ADMIN:** يمكنه حذف أي سائق في النظام.

**ملاحظة:** لا يمكن حذف سائق توصيل إذا كان لديه مهمة توصيل نشطة (ASSIGNED, NOTIFIED, ACCEPTED, PICKED).

- **URL:** `/users/deliveries/:id`
- **Method:** `DELETE`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `OFFICE_OWNER` أو `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### ما يتم حذفه:

| العنصر | الوصف |
| ------------- | ------------------------------- |
| صور السائق | جميع صور الملف الشخصي |
| بيانات السائق | الحذف النهائي من قاعدة البيانات |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Delivery driver deleted successfully",
  "data": {},
  "timestamp": "2026-02-26T10:10:00.000Z",
  "path": "/api/v1/users/deliveries/15"
}
```

### Response (Error - 400 Bad Request)

إذا كان السائق لديه مهمة توصيل نشطة:

```json
{
  "statusCode": 400,
  "message": "Cannot delete account while on active delivery mission. Active orders: #123 (PENDING)",
  "error": "Bad Request"
}
```

### Response (Error - 404 Not Found)

إذا لم يكن السائق موجوداً أو لا يتبع لصاحب المكتب:

```json
{
  "statusCode": 404,
  "message": "Delivery driver with ID 99 not found",
  "error": "Not Found"
}
```

### ملاحظات التنفيذ

- بالنسبة لدور `DELIVERY`، يتم تنفيذ **Hard Delete** عبر `QueryRunner` مع معاملة تتضمن:
  1. التحقق من عدم وجود مهمات توصيل نشطة (ASSIGNED, NOTIFIED, ACCEPTED, PICKED).
  2. حذف صور المستخدم من قاعدة البيانات والتخزين.
  3. حذف المستخدم بشكل نهائي.
- بالنسبة للأدوار الأخرى (`MERCHANT`, `ADMIN`)، يتم تطبيق `Soft Delete` فقط.

---

## 8. Confirm/Activate Delivery Driver (ADMIN only)

تفعيل/تأكيد حساب سائق التوصيل. هذا الـ endpoint يقوم بتغيير قيمة `isActive` إلى `true` مباشرة دون الحاجة لـ payload.

- **URL:** `/users/deliveries/:id/confirm`
- **Method:** `PATCH`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### Request Example

```bash
curl -X PATCH http://localhost:3000/api/v1/users/deliveries/75/confirm \
  -H "Authorization: Bearer <admin_token>"
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Delivery driver activated successfully",
  "data": {
    "id": 75,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+966509876543",
    "role": "DELIVERY",
    "isActive": true,
    "isOnline": false,
    "isVerified": true,
    "createdAt": "2026-04-03T10:00:00.000Z",
    "updatedAt": "2026-04-03T19:00:00.000Z"
  },
  "timestamp": "2026-04-03T19:00:00.000Z",
  "path": "/api/v1/users/deliveries/75/confirm"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Delivery driver with ID 999 not found",
  "error": "Not Found"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden"
}
```

---

## 9. Reset Delivery Driver Password (ADMIN only)

إعادة تعيين كلمة مرور سائق التوصيل **بدون الحاجة لكلمة المرور القديمة**.

- **URL:** `/users/deliveries/:id/reset-password`
- **Method:** `PATCH`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |
| `Content-Type` | Yes | `application/json` |

### URL Parameters

| Parameter | Type | Description |
| --------- | :--- | :---------- |
| `id` | Number | معرف سائق التوصيل (ID). Validation: `ParseIntPipe` |

### Payload (JSON)

| Field | Type | Required | Description |
| :---- | :--- | :------- | :---------- |
| `password` | String | Yes | كلمة المرور الجديدة (6 أحرف كحد أدنى). Validation: `@MinLength(6)` |

### Request Example

```json
{
  "password": "newStrongPassword123"
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Password reset successfully",
  "data": {
    "id": 75,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+966509876543",
    "role": "DELIVERY",
    "isActive": true,
    "createdAt": "2026-04-03T10:00:00.000Z",
    "updatedAt": "2026-06-29T12:00:00.000Z"
  },
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/users/deliveries/75/reset-password"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User with ID 999 not found",
  "error": "Not Found"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden"
}
```

### ملاحظات التنفيذ

- يتم تشفير كلمة المرور تلقائياً باستخدام `bcrypt.hash(password, 10)` قبل الحفظ.
- **لا حاجة** لكلمة المرور القديمة — الأدمن لديه صلاحية كاملة.
- يتم البحث عن المستخدم بأي دور (DELIVERY, MERCHANT, CUSTOMER...).

---

## Error Codes

| الكود | الرسالة | الوصف |
| :---- | :---------------------------- | :---------------------------------------- |
| `2001` | `User not found` | السائق غير موجود. |
| `2003` | `Email already registered` | البريد الإلكتروني مسجل مسبقاً عند الإنشاء أو التعديل. |
| `2004` | `Phone number already registered` | رقم الهاتف مسجل مسبقاً. |
| `2009` | `Invalid user role` | دور المستخدم غير صالح للعملية المطلوبة. |

---

## Enums Reference

### NotificationChannel

| القيمة | الوصف |
| :------ | :---- |
| `EMAIL` | إشعار عبر البريد الإلكتروني |
| `SMS` | إشعار عبر الرسائل النصية |
| `WHATSAPP` | إشعار عبر واتساب |
| `FIREBASE` | إشعار عبر Firebase (القيمة الافتراضية في الكيان) |

### UserRole

| القيمة | الوصف |
| :------ | :---- |
| `OFFICE_OWNER` | صاحب مكتب — يدير سائقي التوصيل التابعين له |
| `ADMIN` | مدير النظام — صلاحية كاملة على جميع السائقين |
| `DELIVERY` | سائق توصيل |

---

## تفاصيل تقنية

### المتحكمات

- **OfficeOwnersController** (`src/modules/auth/controllers/office-owners.controller.ts`)
  - جميع endpoints محمية بـ `AuthGuard` و `RolesGuard` و `@Roles(UserRole.OFFICE_OWNER)`
  - صاحب المكتب يمكنه فقط إدارة سائقي التوصيل التابعين له
  - الإنشاء: `POST /users/deliveries` (multipart/form-data مع صورة)
  - العرض (الكل): `GET /users/deliveries`
  - العرض (واحد): `GET /users/deliveries/:id`
  - التعديل: `PATCH /users/deliveries/:id` (multipart/form-data مع صورة)
  - الحذف: `DELETE /users/deliveries/:id`

- **UsersAdminController** (`src/modules/auth/controllers/users-admin.controller.ts`)
  - جميع endpoints محمية بـ `AuthGuard` و `RolesGuard` و `@Roles(UserRole.ADMIN)`
  - ADMIN يمكنه رؤية جميع سائقي التوصيل
  - العرض (الكل): `GET /users/deliveries`
  - العرض (واحد): `GET /users/deliveries/:id`
  - الإنشاء: `POST /users/deliveries` (multipart/form-data مع صورة)
  - التعديل: `PATCH /users/deliveries/:id` (multipart/form-data مع صورة)
  - الحذف: `DELETE /users/deliveries/:id`
  - التفعيل: `PATCH /users/deliveries/:id/confirm`

### الخدمات

- **OfficeOwnersService** (`src/modules/auth/services/office-owners.service.ts`)
  - التحقق من الملكية: التأكد من أن السائق يتبع لصاحب المكتب
  - الفلترة والبحث: دعم كامل لل paginated results مع فلترة حسب `status` و `isOnline`
  - معالجة الصور: رفع، تحديث، وحذف الصور

- **UsersAdminService** (`src/modules/auth/services/users-admin.service.ts`)
  - عرض جميع سائقي التوصيل في النظام
  - دعم الفلترة حسب `officeOwnerId` و `countryId` و `cityId` و `isOnline`

### DTOs

- `CreateDeliveryByOfficeDto` (`src/modules/auth/dto/create-delivery-by-office.dto.ts`)
- `UpdateDeliveryByOfficeDto` (`src/modules/auth/dto/update-delivery-by-office.dto.ts`)
- `DeliveryFilterDto` (`src/modules/users/dto/delivery-filter.dto.ts`)

### Entity

- **User** (`src/database/entities/user.entity.ts`)
  - جميع السائقين (بالإضافة إلى العملاء والتجار) مخزنين في جدول `users` مع `role = 'DELIVERY'`

### ملاحظات أمان

1. **الدور يتم تعيينه تلقائياً:** عند إنشاء سائق توصيل، يتم تعيين الدور `DELIVERY` تلقائياً
2. **التحقق من البريد:** يجب أن يكون البريد الإلكتروني فريداً في النظام
3. **تشفير كلمة المرور:** جميع كلمات المرور تُخزن مشفرة باستخدام `bcrypt` مع 10 جولات
4. **الحذف النهائي (Hard Delete):** عند حذف سائق، يتم الحذف النهائي من قاعدة البيانات (للمستخدمين بدور `DELIVERY`)
5. **التحقق من الملكية:** Office Owner يمكنه فقط إدارة سائقي التوصيل التابعين له
6. **معالجة الصور:** عند التحديث، يتم حذف الصورة القديمة تلقائياً ورفع الصورة الجديدة مع معالجتها إلى ثلاثة أحجام
7. **فحص المهمات النشطة:** لا يمكن حذف سائق لديه مهمة توصيل نشطة (ASSIGNED, NOTIFIED, ACCEPTED, PICKED)
8. **تحويل البيانات (ValidationPipe):** يتم استخدام `@Type(() => Number)` لتحويل أنواع الحقول الرقمية في multipart/form-data
