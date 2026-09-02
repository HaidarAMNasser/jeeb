# Users Admin API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة ودور الصلاحيات

- **ADMIN:** يمتلك صلاحيات كاملة لإدارة جميع المستخدمين (عملاء، تجار، سائقين):
  - إنشاء مستخدم جديد
  - عرض جميع المستخدمين مع الفلترة والبحث
  - عرض تفاصيل مستخدم محدد
  - تعديل بيانات المستخدم
  - حذف المستخدم (Soft Delete)
  - تفعيل حساب التاجر (`PATCH /users/merchants/:id/confirm`)

- **Roles Supported:** يمكن للـ ADMIN إنشاء مستخدمين بأي دور:
  - `CUSTOMER` - عميل
  - `MERCHANT` - تاجر (صاحب مطعم)
  - `DELIVERY` - سائق توصيل
  - `ADMIN` - مدير

**ملاحظة أمنية:** جميع endpoints الخاصة بإدارة المستخدمين تتطلب صلاحية **ADMIN** فقط.

المسارات معرفة في [api-routes.constants.ts](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/common/constants/api-routes.constants.ts#L52-L61).

---

## 1. Create User (ADMIN only)

إنشاء مستخدم جديد بأي دور (CUSTOMER, MERCHANT, DELIVERY, ADMIN).

- **URL:** `/users`
- **Method:** `POST`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: multipart/form-data`

### Payload (Request Body - Form Data)

| Field                 | Type   | Required | Description                                                  |
| --------------------- | ------ | -------- | ------------------------------------------------------------ |
| `email`               | string | Yes      | البريد الإلكتروني (فريد)                                     |
| `password`            | string | Yes      | كلمة المرور (6 أحرف على الأقل)                               |
| `firstName`           | string | Yes      | الاسم الأول                                                  |
| `lastName`            | string | Yes      | اسم العائلة                                                  |
| `phone`               | string | Yes      | رقم الهاتف (فريد)                                            |
| `role`                | string | No       | الدور (CUSTOMER/MERCHANT/DELIVERY/ADMIN) - افتراضي: CUSTOMER |
| `countryId`           | number | No       | معرف الدولة                                                  |
| `cityId`              | number | No       | معرف المدينة                                                 |
| `areaId`              | number | No       | معرف المنطقة                                                 |
| `address`             | string | No       | العنوان                                                      |
| `notificationChannel` | string | No       | قناة الإشعارات (EMAIL/WHATSAPP/SMS/FIREBASE) - افتراضي: FIREBASE |
| `birthday`            | string | No       | تاريخ الميلاد (YYYY-MM-DD)                                   |
| `image`               | file   | No       | صورة الملف الشخصي (JPG, PNG, WebP, max 5MB)                  |

### Request Example (multipart/form-data)

```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer <admin_token>" \
  -F "email=user@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=John" \
  -F "lastName=Doe" \
  -F "phone=+963912345678" \
  -F "role=CUSTOMER" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Damascus, User Street 123" \
  -F "birthday=1990-05-15" \
  -F "image=@/path/to/profile.jpg"
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "User created successfully",
  "data": {
    "id": 15,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "countryId": 1,
    "cityId": 1,
    "areaId": null,
    "area": null,
    "address": "Damascus, User Street 123",
    "notificationChannel": "FIREBASE",
    "birthday": "1990-05-15",
    "isOnline": true,
    "verifiedAt": "2026-02-26T10:00:00.000Z",
    "createdAt": "2026-02-26T10:00:00.000Z",
    "updatedAt": "2026-02-26T10:00:00.000Z",
    "country": {
      "id": 1,
      "name": {
        "ar": "سوريا",
        "en": "Syria"
      },
      "code": "SY"
    },
    "city": {
      "id": 1,
      "name": {
        "ar": "دمشق",
        "en": "Damascus"
      },
      "countryId": 1
    },
    "image": {
      "id": 1,
      "url": "users/15/1234567890_profile.webp",
      "mobileUrl": "users/15/1234567890_profile_mobile.webp",
      "thumbnailUrl": "users/15/1234567890_profile_thumb.webp",
      "isMain": true
    }
  },
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users"
}
```

### Response (Error - 409 Conflict)

إذا كان البريد الإلكتروني أو الهاتف موجود مسبقاً:

```json
{
  "statusCode": 409,
  "message": "Email or phone already exists",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن المستخدم ADMIN:

```json
{
  "message": "Forbidden resource",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

## 2. Get All Users (Filter, Search & Pagination)

إرجاع قائمة المستخدمين مع دعم الفلترة والبحث الشامل والصفحات. يتطلب صلاحية ADMIN.

**ملاحظة:** البحث تم دمجه في endpoint العرض الكل. لا يوجد endpoint منفصل للبحث.

- **URL:** `/users`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <admin_token>`

### Query Parameters

| Parameter    | Type    | Required | Description                                          |
| ------------ | ------- | -------- | ---------------------------------------------------- |
| `page`       | number  | No       | رقم الصفحة (افتراضي: 1)                              |
| `limit`      | number  | No       | عدد العناصر في الصفحة (افتراضي: 10)                  |
| `search`     | string  | No       | البحث الشامل بالاسم أو البريد أو الهاتف              |
| `countryId`  | number  | No       | الفلترة حسب الدولة                                   |
| `cityId`     | number  | No       | الفلترة حسب المدينة                                  |
| `role`       | string  | No       | الفلترة حسب الدور (CUSTOMER/MERCHANT/DELIVERY/ADMIN) |
| `isVerified` | boolean | No       | الفلترة حسب حالة التحقق                              |
| `isOnline`   | boolean | No       | الفلترة حسب حالة الاتصال                             |

### البحث الشامل

عند استخدام `search`، يتم البحث في الحقول التالية:

- `firstName` (الاسم الأول)
- `lastName` (اسم العائلة)
- `email` (البريد الإلكتروني)
- `phone` (رقم الهاتف)

### Example URLs

```
# عرض كل المستخدمين
GET /users

# بحث مع فلترة
GET /users?search=john&role=CUSTOMER&countryId=1

# صفحة محددة مع عدد عناصر
GET /users?page=1&limit=10&search=john
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 15,
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+963912345678",
      "role": "CUSTOMER",
      "countryId": 1,
      "cityId": 1,
      "areaId": null,
      "area": null,
      "address": "Damascus, User Street 123",
      "birthday": "1990-05-15",
      "isOnline": true,
      "verifiedAt": "2026-02-26T10:00:00.000Z",
      "createdAt": "2026-02-26T10:00:00.000Z",
      "updatedAt": "2026-02-26T10:00:00.000Z",
      "country": {
        "id": 1,
        "name": {
          "ar": "سوريا",
          "en": "Syria"
        },
        "code": "SY"
      },
      "city": {
        "id": 1,
        "name": {
          "ar": "دمشق",
          "en": "Damascus"
        },
        "countryId": 1
      },
      "image": {
        "id": 1,
        "url": "users/15/1234567890_profile.webp",
        "mobileUrl": "users/15/1234567890_profile_mobile.webp",
        "thumbnailUrl": "users/15/1234567890_profile_thumb.webp",
        "isMain": true
      }
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
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users"
}
```

---

## 3. Get One User

الحصول على تفاصيل مستخدم محدد.

- **URL:** `/users/:id`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <admin_token>`

### URL Parameters

| Parameter | Type   | Description        |
| --------- | ------ | ------------------ |
| `id`      | number | معرف المستخدم (ID) |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 15,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "countryId": 1,
    "cityId": 1,
    "areaId": null,
    "area": null,
    "address": "Damascus, User Street 123",
    "notificationChannel": "FIREBASE",
    "birthday": "1990-05-15",
    "isOnline": true,
    "verifiedAt": "2026-02-26T10:00:00.000Z",
    "createdAt": "2026-02-26T10:00:00.000Z",
    "updatedAt": "2026-02-26T10:00:00.000Z",
    "country": {
      "id": 1,
      "name": {
        "ar": "سوريا",
        "en": "Syria"
      },
      "code": "SY"
    },
    "city": {
      "id": 1,
      "name": {
        "ar": "دمشق",
        "en": "Damascus"
      },
      "countryId": 1
    },
    "image": {
      "id": 1,
      "url": "users/15/1234567890_profile.webp",
      "mobileUrl": "users/15/1234567890_profile_mobile.webp",
      "thumbnailUrl": "users/15/1234567890_profile_thumb.webp",
      "isMain": true
    }
  },
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/15"
}
```

### Response (Error - 404 Not Found)

```json
{
  "message": "User with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## 4. Update User

تحديث بيانات مستخدم موجود. جميع الحقول اختيارية.

- **URL:** `/users/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: multipart/form-data`

### URL Parameters

| Parameter | Type   | Description        |
| --------- | ------ | ------------------ |
| `id`      | number | معرف المستخدم (ID) |

### Payload (Request Body - Form Data)

| Field                 | Type   | Description                                     |
| --------------------- | ------ | ----------------------------------------------- |
| `firstName`           | string | الاسم الأول الجديد                              |
| `lastName`            | string | اسم العائلة الجديد                              |
| `phone`               | string | رقم الهاتف الجديد                               |
| `password`            | string | كلمة المرور الجديدة (6 أحرف على الأقل)          |
| `role`                | string | الدور الجديد (CUSTOMER/MERCHANT/DELIVERY/ADMIN) |
| `countryId`           | number | معرف الدولة الجديد                              |
| `cityId`              | number | معرف المدينة الجديد                             |
| `address`             | string | العنوان الجديد                                  |
| `notificationChannel` | string | قناة الإشعارات الجديدة                          |
| `birthday`            | string | تاريخ الميلاد (YYYY-MM-DD)                      |
| `image`               | file   | صورة الملف الشخصي الجديدة (سيتم حذف القديمة)    |

### Request Example (multipart/form-data)

```bash
curl -X PATCH http://localhost:3000/api/v1/users/15 \
  -H "Authorization: Bearer <admin_token>" \
  -F "firstName=John Updated" \
  -F "lastName=Doe Updated" \
  -F "phone=+963987654321" \
  -F "role=MERCHANT" \
  -F "image=@/path/to/new_profile.jpg"
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "User updated successfully",
  "data": {
    "id": 15,
    "email": "user@example.com",
    "firstName": "John Updated",
    "lastName": "Doe Updated",
    "phone": "+963987654321",
    "role": "MERCHANT",
    "countryId": 2,
    "cityId": 3,
    "areaId": null,
    "area": null,
    "address": "New Address Street",
    "notificationChannel": "EMAIL",
    "birthday": "1990-05-15",
    "isOnline": true,
    "verifiedAt": "2026-02-26T10:00:00.000Z",
    "createdAt": "2026-02-26T10:00:00.000Z",
    "updatedAt": "2026-02-26T10:05:00.000Z",
    "image": {
      "id": 2,
      "url": "users/15/1234567891_updated.webp",
      "mobileUrl": "users/15/1234567891_updated_mobile.webp",
      "thumbnailUrl": "users/15/1234567891_updated_thumb.webp",
      "isMain": true
    }
  },
  "timestamp": "2026-02-26T10:05:00.000Z",
  "path": "/api/v1/users/15"
}
```

### Response (Error - 404 Not Found)

```json
{
  "message": "User with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## 5. Delete User (Soft Delete)

حذف مستخدم (حذف ناعم - يمكن استعادته لاحقاً).

- **URL:** `/users/:id`
- **Method:** `DELETE`
- **Headers:** `Authorization: Bearer <admin_token>`

### URL Parameters

| Parameter | Type   | Description        |
| --------- | ------ | ------------------ |
| `id`      | number | معرف المستخدم (ID) |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "User deleted successfully",
  "data": {},
  "timestamp": "2026-02-26T10:10:00.000Z",
  "path": "/api/v1/users/15"
}
```

### Response (Error - 404 Not Found)

```json
{
  "message": "User with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## تفاصيل تقنية إضافية

- **المتحكم:** [UsersAdminController](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/controllers/users-admin.controller.ts)
  - جميع endpoints محمية بـ `AuthGuard` و `RolesGuard` و `@Roles(UserRole.ADMIN)`
  - الإنشاء: `POST /users`
  - العرض (الكل مع البحث): `GET /users?search=` - البحث مدمج في نفس endpoint
  - العرض (واحد): `GET /users/:id`
  - التعديل: `PATCH /users/:id`
  - الحذف: `DELETE /users/:id`

- **الخدمة:** [UsersAdminService](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/services/users-admin.service.ts)
  - التحقق من وجود البريد/الهاتف: قبل الإنشاء
  - تشفير كلمة المرور: bcrypt
  - حذف الصورة: عند حذف المستخدم أو تحديث صورته
  - البحث الشامل: يبحث في firstName, lastName, email, phone
  - الفلترة والـ Pagination: دعم كامل لل paginated results
  - المستخدمون المُنشأون من الـ ADMIN: يتم التحقق منهم تلقائياً (verifiedAt = now)

- **DTOs:**
  - [CreateUserDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/create-user.dto.ts)
  - [UpdateUserAdminDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/update-user-admin.dto.ts)
  - [FilterUserDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/filter-user.dto.ts)

- **ملف Postman:** [Delivery Jeeb - Users Admin Module](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/DOCS/ApprovedPostman/Delivery Jeeb - Users Admin Module.postman_collection.json)

---

## ملاحظات أمان

1. **صلاحية ADMIN فقط:** جميع endpoints تتطلب صلاحية ADMIN
2. **جميع الأدوار متاحة:** يمكن للـ ADMIN إنشاء مستخدمين بأي دور (CUSTOMER, MERCHANT, DELIVERY, ADMIN)
3. **التحقق من البريد والهاتف:** يجب أن يكونا فريدين في النظام
4. **تشفير كلمة المرور:** جميع كلمات المرور تُخزن مشفرة باستخدام bcrypt
5. **الحذف الناعم:** عند حذف مستخدم، يتم soft delete (يمكن استعادته لاحقاً)
6. **حذف الصور:** عند حذف مستخدم أو تحديث صورته، يتم حذف الصور من التخزين
7. **التحقق التلقائي:** المستخدمون المُنشأون من الـ ADMIN يتم التحقق منهم تلقائياً
