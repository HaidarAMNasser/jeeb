# Customers API Documentation

Base URL: `http://localhost:3000/api/v1`

### نظرة عامة ودور الصلاحيات

- **ADMIN:** يمتلك صلاحيات كاملة على إدارة العملاء (إنشاء، عرض، تعديل، وحذف).
- **CUSTOMER / MERCHANT / DELIVERY:** لا يمكنهم الوصول إلى هذه الـ endpoints. إدارة الملف الشخصي للعميل تتم عبر [Auth API](Auth_API.md).

جميع الـ endpoints تتطلب صلاحية `ADMIN` فقط، وهي محمية بـ `AuthGuard` و `RolesGuard`.

المسارات معرفة في `src/common/constants/api-routes.constants.ts`.

---

## 1. Create Customer

إنشاء عميل جديد (للمدراء فقط). يتم التحقق من البريد الإلكتروني لمنع التكرار.

- **URL:** `/users/customers`
- **Method:** `POST`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Payload (Request Body)

| Field | Type | Required | Description |
| :-------------------- | :----- | :------- | :------------------------------------------------------ |
| `email` | String | Yes | البريد الإلكتروني (فريد). Validation: `@IsEmail()` |
| `password` | String | Yes | كلمة المرور. Validation: `@MinLength(6)` |
| `firstName` | String | Yes | الاسم الأول. Validation: `@IsString()` `@IsNotEmpty()` |
| `lastName` | String | Yes | الشهرة. Validation: `@IsString()` `@IsNotEmpty()` |
| `phone` | String | Yes | رقم الهاتف. Validation: `@IsString()` `@IsNotEmpty()` |
| `countryId` | Number | No | معرف الدولة. Validation: `@IsNumber()` |
| `cityId` | Number | No | معرف المدينة. Validation: `@IsNumber()` |
| `areaId` | Number | No | معرف المنطقة. Validation: `@IsNumber()` |
| `notificationChannel` | Enum | No | قناة الإشعارات. Validation: `@IsEnum(NotificationChannel)`. القيم: `EMAIL`, `SMS`, `WHATSAPP`, `FIREBASE` |
| `address` | String | No | العنوان بالتفصيل. Validation: `@IsString()` |

### Request Example

```json
{
  "email": "customer@example.com",
  "password": "strongPassword123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+963912345678",
  "countryId": 1,
  "cityId": 1,
  "areaId": 1,
  "notificationChannel": "EMAIL",
  "address": "Damascus, Mazzeh"
}
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "email": "customer@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "isOnline": false,
    "isActive": true,
    "verifiedAt": "2026-03-19T10:00:00.000Z",
    "countryId": 1,
    "cityId": 1,
    "areaId": null,
    "area": null,
    "address": "Damascus, Mazzeh",
    "notificationChannel": "EMAIL",
    "createdAt": "2026-03-19T10:00:00.000Z",
    "updatedAt": "2026-03-19T10:00:00.000Z"
  },
  "timestamp": "2026-03-19T10:00:00.000Z",
  "path": "/api/v1/users/customers"
}
```

### Response (Error - 400 Bad Request)

في حال نقص البيانات المطلوبة أو عدم صحتها:

```json
{
  "statusCode": 400,
  "message": [
    "email must be an email",
    "password must be longer than or equal to 6 characters"
  ],
  "error": "Bad Request"
}
```

### Response (Error - 409 Conflict)

في حال كان البريد الإلكتروني أو رقم الهاتف مسجلاً مسبقاً:

```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "error": "Conflict"
}
```

### ملاحظات التنفيذ

- يتم تشفير كلمة المرور تلقائياً باستخدام `bcrypt.hash(password, 10)` قبل الحفظ.
- يتم تفعيل الحساب تلقائياً (`verifiedAt: new Date()`).
- يتم إرسال بريد ترحيبي للعميل عبر `NotificationsService.sendWelcomeEmail()`.

---

## 2. Get All Customers

جلب قائمة بجميع العملاء مع إمكانية التصفية والبحث والترقيم.

- **URL:** `/users/customers`
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
| `page` | Number | No | `1` | رقم الصفحة. Validation: `@IsPositive()` |
| `limit` | Number | No | `10` | عدد العناصر في الصفحة. Validation: `@IsPositive()` |
| `search` | String | No | - | بحث غير حساس لحالة الأحرف في `firstName`, `lastName`, `email`, `phone` |
| `countryId` | Number | No | - | فلترة حسب الدولة. Validation: `@IsNumber()` |
| `cityId` | Number | No | - | فلترة حسب المدينة. Validation: `@IsNumber()` |

### Request Example

```
GET /api/v1/users/customers?page=1&limit=10&search=john&countryId=1
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 15,
      "email": "customer@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+963912345678",
      "role": "CUSTOMER",
      "isOnline": false,
      "isActive": true,
      "verifiedAt": "2026-03-19T10:00:00.000Z",
      "countryId": 1,
      "cityId": 1,
      "areaId": null,
      "area": null,
      "address": "Damascus, Mazzeh",
      "notificationChannel": "EMAIL",
      "birthday": null,
      "lastLoginAt": null,
      "createdAt": "2026-03-19T10:00:00.000Z",
      "updatedAt": "2026-03-19T10:00:00.000Z",
      "country": {
        "id": 1,
        "name": { "ar": "سوريا", "en": "Syria" },
        "code": "SY"
      },
      "city": {
        "id": 1,
        "name": { "ar": "دمشق", "en": "Damascus" },
        "countryId": 1
      }
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "timestamp": "2026-03-19T10:00:00.000Z",
  "path": "/api/v1/users/customers"
}
```

### Response (Error - 401 Unauthorized)

في حال عدم وجود توكن أو صلاحية كافية:

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "Unauthorized"
}
```

---

## 3. Get One Customer

جلب بيانات عميل محدد باستخدام الـ ID. تشمل الاستجابة العلاقات (الدولة، المدينة، الصور).

- **URL:** `/users/customers/:id`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "email": "customer@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "isOnline": true,
    "isActive": true,
    "verifiedAt": "2026-03-19T10:00:00.000Z",
    "countryId": 1,
    "cityId": 1,
    "areaId": null,
    "area": null,
    "address": "Damascus, Mazzeh",
    "notificationChannel": "EMAIL",
    "birthday": null,
    "lastLoginAt": null,
    "createdAt": "2026-03-19T10:00:00.000Z",
    "updatedAt": "2026-03-19T10:00:00.000Z",
    "images": [],
    "country": {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY"
    },
    "city": {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    }
  },
  "timestamp": "2026-03-19T10:00:00.000Z",
  "path": "/api/v1/users/customers/15"
}
```

### Response (Error - 404 Not Found)

في حال عدم وجود العميل:

```json
{
  "statusCode": 404,
  "message": "User not found",
  "error": "Not Found"
}
```

---

## 4. Update Customer

تحديث بيانات عميل محدد. جميع الحقول اختيارية. يتم إرجاع كامل بيانات المستخدم بعد التحديث.

- **URL:** `/users/customers/:id`
- **Method:** `PATCH`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Payload (Request Body)

| Field | Type | Description |
| :-------------------- | :----- | :------------------------------------------------------ |
| `email` | String | بريد إلكتروني جديد (يجب أن يكون فريد). |
| `password` | String | كلمة مرور جديدة (6 أحرف على الأقل). |
| `firstName` | String | الاسم الأول. |
| `lastName` | String | الشهرة. |
| `phone` | String | رقم هاتف جديد. |
| `countryId` | Number | معرف الدولة. |
| `cityId` | Number | معرف المدينة. |
| `notificationChannel` | Enum | قناة الإشعارات: `EMAIL`, `SMS`, `WHATSAPP`, `FIREBASE`. |
| `address` | String | العنوان بالتفصيل. |

### Request Example

```json
{
  "firstName": "John Updated",
  "address": "New Damascus Address"
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "email": "customer@example.com",
    "firstName": "John Updated",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "isOnline": false,
    "isActive": true,
    "verifiedAt": "2026-03-19T10:00:00.000Z",
    "countryId": 1,
    "cityId": 1,
    "areaId": null,
    "area": null,
    "address": "New Damascus Address",
    "notificationChannel": "EMAIL",
    "birthday": null,
    "lastLoginAt": null,
    "createdAt": "2026-03-19T10:00:00.000Z",
    "updatedAt": "2026-03-19T10:05:00.000Z"
  },
  "timestamp": "2026-03-19T10:05:00.000Z",
  "path": "/api/v1/users/customers/15"
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

### ملاحظات التنفيذ

- `UpdateCustomerDto` يستخدم `PartialType(CreateCustomerDto)`، مما يجعل جميع الحقول اختيارية.
- إذا تم تمرير `password`، يتم تشفيره تلقائياً باستخدام `bcrypt.hash()` قبل الحفظ.
- يتم استخدام `Object.assign(user, updateDto)` لتحديث الحقول ثم `userRepository.save(user)`.

---

## 5. Delete Customer

حذف عميل محدد. على الرغم من أن المتحكم يستدعي `softDelete()`، إلا أن الخدمة تقوم بـ **الحذف النهائي (Hard Delete)** للعملاء عبر معاملة (Transaction) في قاعدة البيانات — حيث يتم حذف العميل وجميع البيانات المرتبطة به بشكل نهائي.

- **URL:** `/users/customers/:id`
- **Method:** `DELETE`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** `ADMIN`

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### ما يتم حذفه:

| العنصر | الوصف |
| --------------- | ---------------------------------------- |
| صور العميل | جميع صور الملف الشخصي |
| الطلبات المعلقة | الطلبات بالحالات `PENDING` و `CONFIRMED` |
| المفضلة | جميع المفضلات المرتبطة بالعميل |
| بيانات العميل | الحذف النهائي من قاعدة البيانات |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-03-19T10:06:00.000Z",
  "path": "/api/v1/users/customers/15"
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

### ملاحظات التنفيذ

- المتحكم يستدعي `usersService.softDelete(id)`.
- بالنسبة لدور `CUSTOMER`، تقوم الخدمة بتنفيذ **Hard Delete** عبر `QueryRunner` مع معاملة تتضمن:
  1. حذف صور المستخدم من قاعدة البيانات والتخزين.
  2. حذف الطلبات المعلقة (`PENDING`, `CONFIRMED`).
  3. حذف المفضلة.
  4. حذف المستخدم بشكل نهائي.
- بالنسبة للأدوار الأخرى (`MERCHANT`, `ADMIN`)، يتم تطبيق `Soft Delete` فقط.

---

## Error Codes

| الكود | الرسالة | الوصف |
| :---- | :---------------------------- | :---------------------------------- |
| `2001` | `User not found` | العميل غير موجود. |
| `2003` | `Email already registered` | البريد الإلكتروني مسجل مسبقاً. |
| `2004` | `Phone number already registered` | رقم الهاتف مسجل مسبقاً. |
| `2009` | `Invalid user role` | دور المستخدم غير صالح. |

---

## Enums Reference

### NotificationChannel

| القيمة | الوصف |
| :------ | :---- |
| `EMAIL` | إشعار عبر البريد الإلكتروني |
| `SMS` | إشعار عبر الرسائل النصية |
| `WHATSAPP` | إشعار عبر واتساب |
| `FIREBASE` | إشعار عبر Firebase (القيمة الافتراضية) |

---

## تفاصيل تقنية

- **المتحكم:** `UsersController` (`src/modules/users/users.controller.ts`)
- **الخدمة:** `UsersService` (`src/modules/users/users.service.ts`)
- **الكائن (Entity):** `User` (`src/database/entities/user.entity.ts`)
- **DTOs:**
  - `CreateCustomerDto` (`src/modules/users/dto/create-customer.dto.ts`)
  - `UpdateCustomerDto` (`src/modules/users/dto/update-customer.dto.ts`)
  - `CustomerFilterDto` (`src/modules/users/dto/customer-filter.dto.ts`)

### الملاحظات الأساسية:

- **تحويل البيانات (ValidationPipe):** يستخدم المتحكم `ValidationPipe({ transform: true, whitelist: true })` مع `enableImplicitConversion: true`، مما يعني تحويل أنواع البيانات تلقائياً وتجاهل الحقول غير المصرح بها.
- **الحذف نهائي (Hard Delete):** للعملاء فقط. باقي الأدوار تستخدم Soft Delete.
- **كلمة المرور:** يتم تشفيرها تلقائياً عند الإنشاء أو التعديل باستخدام `bcrypt` مع 10 جولات.
- **البريد الترحيبي:** يتم إرسال بريد ترحيبي عند إنشاء العميل من قبل الإدارة عبر `NotificationsService`.
