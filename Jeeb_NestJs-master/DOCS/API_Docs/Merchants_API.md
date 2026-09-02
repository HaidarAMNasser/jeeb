# Merchants API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة ودور الصلاحيات

- **ADMIN:** يمتلك صلاحيات كاملة لإدارة التجار (أصحاب المطاعم):
  - إنشاء تاجر جديد
  - عرض جميع التجار مع الفلترة والبحث
  - عرض تفاصيل تاجر محدد
  - تعديل بيانات التاجر
  - حذف التاجر (حذف نهائي - Hard Delete)
- **MERCHANT:** الدور يتم تعيينه تلقائياً عند الإنشاء، لا يحتاج لإرساله في الـ payload

**ملاحظة أمنية:** جميع endpoints الخاصة بالتجار تتطلب صلاحية **ADMIN** فقط.

المسارات معرفة في [api-routes.constants.ts](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/common/constants/api-routes.constants.ts#L56-L57).

---

## 1. Create Merchant (ADMIN only)

إنشاء تاجر جديد (صاحب مطعم). الدور MERCHANT يتم تعيينه تلقائياً.

- **URL:** `/users/merchants`
- **Method:** `POST`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: multipart/form-data`

### Payload (Request Body - Form Data)

| Field            | Type   | Required | Description                                                                                                               |
| ---------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `email`          | string | Yes      | البريد الإلكتروني (فريد)                                                                                                  |
| `password`       | string | Yes      | كلمة المرور (6 أحرف على الأقل)                                                                                            |
| `firstName`      | string | Yes      | الاسم الأول                                                                                                               |
| `lastName`       | string | Yes      | اسم العائلة                                                                                                               |
| `phone`          | string | Yes      | رقم الهاتف                                                                                                                |
| `countryId`      | number | No       | معرف الدولة                                                                                                               |
| `cityId`         | number | No       | معرف المدينة                                                                                                              |
| `areaId`         | number | No       | معرف المنطقة                                                                                                              |
| `address`        | string | No       | العنوان الكامل                                                                                                            |
| `birthday`       | string | No       | تاريخ الميلاد (YYYY-MM-DD)                                                                                                |
| `restaurantName` | string | No       | اسم المطعم (لصاحب المطعم فقط)                                                                                             |
| `type`           | string | No       | نوع التاجر (RESTAURANT أو STORE) - افتراضي: RESTAURANT                                                                    |
| `description`    | string | No       | وصف المطعم                                                                                                                |
| `location`       | object | No       | الموقع الجغرافي (`{"lat": number, "lng": number}`) كما يمكن إرسالها كـ JSON string في form-data                           |
| `image`          | file   | No       | صورة الملف الشخصي (JPG, JPEG, PNG, WebP, max 5MB). تتم معالجة الصورة تلقائياً إلى عدة أحجام (original, mobile, thumbnail) |

### Request Example (multipart/form-data)

```bash
curl -X POST http://localhost:3000/api/v1/users/merchants \
  -H "Authorization: Bearer <admin_token>" \
  -F "email=merchant5@example.com" \
  -F "password=password" \
  -F "firstName=John" \
  -F "lastName=Doe" \
  -F "phone=+96391234552" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Damascus, Merchant Street 123" \
  -F "birthday=1990-05-15" \
  -F "restaurantName=Tasty Burger Restaurant" \
  -F "location={\"lat\": 33.5138, \"lng\": 36.2765}" \
  -F "image=@/path/to/profile.jpg"
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Merchant created successfully",
  "data": {
    "location": {
      "lat": 33.5138,
      "lng": 36.2765
    },
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "id": 28,
    "firstName": "John",
    "lastName": "Doe",
    "email": "merchant5@example.com",
    "phone": "+96391234552",
    "role": "MERCHANT",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": {
        "ar": "سوريا",
        "en": "Syria"
      },
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
      "name": {
        "ar": "دمشق",
        "en": "Damascus"
      },
      "countryId": 1
    },
    "address": "Damascus, Merchant Street 123",
    "isOnline": true,
    "verifiedAt": "2026-03-10T10:59:21.770Z",
    "birthday": "1990-05-15",
    "createdAt": "2026-03-10T10:59:21.772Z",
    "updatedAt": "2026-03-10T10:59:22.045Z",
    "deletedAt": null,
    "officeOwnerId": null,
    "imageId": 28,
    "image": {
      "id": 28,
      "entityType": "USER",
      "entityId": 28,
      "url": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558).webp",
      "mobileUrl": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558)_mobile.webp",
      "thumbnailUrl": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558)_thumb.webp",
      "isMain": true,
      "displayOrder": 0,
      "createdAt": "2026-03-10T10:59:22.039Z",
      "updatedAt": "2026-03-10T10:59:22.039Z"
    },
    "restaurantName": "Tasty Burger Restaurant",
    "isOpen": false,
    "description": null,
    "estimatedDeliveryMinutes": 30,
    "merchantIsActive": true
  },
  "timestamp": "2026-03-10T10:59:22.551Z",
  "path": "/api/v1/users/merchants"
}
```

### Response (Error - 409 Conflict)

إذا كان البريد الإلكتروني موجود مسبقاً:

```json
{
  "statusCode": 409,
  "message": "Email already exists",
  "data": {},
  "timestamp": "2026-02-26T06:11:29.408Z",
  "path": "/api/v1/users/merchants"
}
```

### Response (Error - 422 Unprocessable Entity)

إذا كانت الصورة غير صالحة (نوع أو حجم):

```json
{
  "statusCode": 422,
  "message": "Validation failed (expected type is /(jpg|jpeg|png|webp)/)",
  "data": {},
  "timestamp": "2026-02-26T06:11:29.408Z",
  "path": "/api/v1/users/merchants"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن المستخدم ADMIN:

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants"
}
```

---

## 2. Get All Merchants (Filter, Search & Pagination)

إرجاع قائمة التجار مع دعم الفلترة والبحث الشامل والصفحات. متاح لكل من ADMIN و CUSTOMER.

- **URL:** `/users/merchants`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <admin_token>`

### Query Parameters

| Parameter    | Type    | Required | Description                               |
| ------------ | ------- | -------- | ----------------------------------------- |
| `page`       | number  | No       | رقم الصفحة (افتراضي: 1)                   |
| `limit`      | number  | No       | عدد العناصر في الصفحة (افتراضي: 10)       |
| `search`     | string  | No       | البحث الشامل بالاسم أو البريد أو الهاتف   |
| `countryId`  | number  | No       | الفلترة حسب الدولة                        |
| `cityId`     | number  | No       | الفلترة حسب المدينة                       |
| `isActive`   | boolean | No       | الفلترة حسب حالة الحساب (نشط/غير نشط)     |
| `isOpen`     | boolean | No       | الفلترة حسب حالة المتجر (مفتوح/مغلق)      |
| `isVerified` | boolean | No       | الفلترة حسب حالة التحقق من الحساب         |
| `type`       | string  | No       | فلتر حسب نوع التاجر (RESTAURANT أو STORE) |

### البحث الشامل

عند استخدام `search`، يتم البحث في الحقول التالية:

- `firstName` (الاسم الأول)
- `lastName` (اسم العائلة)
- `email` (البريد الإلكتروني)
- `phone` (رقم الهاتف)
- `restaurantName` (اسم المطعم)

### Example URLs

```
# عرض كل التجار
GET /users/merchants

# بحث مع فلترة
GET /users/merchants?search=john&countryId=1

# صفحة محددة مع عدد عناصر
GET /users/merchants?page=1&limit=10&search=john

# فلترة متقدمة (حالة الحساب والمتجر)
GET /users/merchants?isActive=true&isOpen=true

# فلترة بالمدينة والمتاجر المغلقة
GET /users/merchants?cityId=1&isOpen=false&page=1&limit=20
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "location": {
        "lat": 33.5138,
        "lng": 36.2765
      },
      "currentLat": 33.5138,
      "currentLng": 36.2765,
      "id": 28,
      "firstName": "John",
      "lastName": "Doe",
      "email": "merchant5@example.com",
      "phone": "+96391234552",
      "role": "MERCHANT",
      "notificationChannel": "WHATSAPP",
      "countryId": 1,
      "country": {
        "id": 1,
        "name": {
          "ar": "سوريا",
          "en": "Syria"
        },
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
        "name": {
          "ar": "دمشق",
          "en": "Damascus"
        },
        "countryId": 1
      },
      "address": "Damascus, Merchant Street 123",
      "isOnline": true,
      "verifiedAt": "2026-03-10T10:59:21.770Z",
      "birthday": "1990-05-15",
      "createdAt": "2026-03-10T10:59:21.772Z",
      "updatedAt": "2026-03-10T10:59:22.045Z",
      "deletedAt": null,
      "officeOwnerId": null,
      "imageId": 28,
      "image": {
        "id": 28,
        "entityType": "USER",
        "entityId": 28,
        "url": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558).webp",
        "mobileUrl": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558)_mobile.webp",
        "thumbnailUrl": "http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558)_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-03-10T10:59:22.039Z",
        "updatedAt": "2026-03-10T10:59:22.039Z"
      },
      "restaurantName": "Tasty Burger Restaurant",
      "type": "RESTAURANT",
      "isOpen": false,
      "description": null,
      "estimatedDeliveryMinutes": 30,
      "merchantIsActive": true
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
  "timestamp": "2026-03-10T11:00:05.329Z",
  "path": "/api/v1/users/merchants?page=1&limit=10&search=&countryId=&cityId=&isActive=true"
}
```

---

## 3. Get One Merchant

الحصول على تفاصيل تاجر محدد مع المطاعم المرتبطة به.

- **URL:** `/users/merchants/:id`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <admin_token>`

### URL Parameters

| Parameter | Type   | Description      |
| --------- | ------ | ---------------- |
| `id`      | number | معرف التاجر (ID) |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "location": {
      "lat": 33.5138,
      "lng": 36.2765
    },
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "id": 27,
    "firstName": "John",
    "lastName": "Doe",
    "email": "merchant4@example.com",
    "phone": "+9639123455",
    "role": "MERCHANT",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": {
        "ar": "سوريا",
        "en": "Syria"
      },
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
      "name": {
        "ar": "دمشق",
        "en": "Damascus"
      },
      "countryId": 1
    },
    "address": "Damascus, Merchant Street 123",
    "isOnline": true,
    "verifiedAt": "2026-03-10T10:39:17.846Z",
    "birthday": "1990-05-15",
    "createdAt": "2026-03-10T10:39:17.846Z",
    "updatedAt": "2026-03-10T10:39:18.088Z",
    "deletedAt": null,
    "officeOwnerId": null,
    "imageId": 27,
    "image": {
      "id": 27,
      "entityType": "USER",
      "entityId": 27,
      "url": "http://localhost:3000/uploads/users/27/1773139884918_images2.webp",
      "mobileUrl": "http://localhost:3000/uploads/users/27/1773139884918_images2_mobile.webp",
      "thumbnailUrl": "http://localhost:3000/uploads/users/27/1773139884918_images2_thumb.webp",
      "isMain": true,
      "displayOrder": 0,
      "createdAt": "2026-03-10T10:51:25.168Z",
      "updatedAt": "2026-03-10T10:51:25.168Z"
    },
    "restaurantName": "Tasty Burger Restaurant",
    "isOpen": false,
    "description": null,
    "estimatedDeliveryMinutes": 30,
    "merchantIsActive": true
  },
  "timestamp": "2026-03-10T11:01:01.502Z",
  "path": "/api/v1/users/merchants/27"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Merchant with ID 999 not found",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants/999"
}
```

---

## 4. Update Merchant

تحديث بيانات تاجر موجود. جميع الحقول اختيارية.

- **URL:** `/users/merchants/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: multipart/form-data`

### URL Parameters

| Parameter | Type   | Description      |
| --------- | ------ | ---------------- |
| `id`      | number | معرف التاجر (ID) |

### Payload (Request Body - Form Data)

| Field            | Type    | Description                                                                                                                                                    |
| ---------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `firstName`      | string  | الاسم الأول الجديد                                                                                                                                             |
| `lastName`       | string  | اسم العائلة الجديد                                                                                                                                             |
| `phone`          | string  | رقم الهاتف الجديد                                                                                                                                              |
| `password`       | string  | كلمة المرور الجديدة (6 أحرف على الأقل)                                                                                                                         |
| `countryId`      | number  | معرف الدولة الجديد                                                                                                                                             |
| `cityId`         | number  | معرف المدينة الجديد                                                                                                                                            |
| `address`        | string  | العنوان الجديد                                                                                                                                                 |
| `birthday`       | string  | تاريخ الميلاد (YYYY-MM-DD)                                                                                                                                     |
| `restaurantName` | string  | اسم المطعم الجديد                                                                                                                                              |
| `type`           | string  | نوع التاجر الجديد (RESTAURANT أو STORE)                                                                                                                        |
| `description`    | string  | وصف المطعم الجديد                                                                                                                                              |
| `location`       | object  | الموقع الجغرافي الجديد (`{"lat": number, "lng": number}`)                                                                                                      |
| `isActive`       | boolean | حالة التفعيل (isActive) - يتم إرسال إشعار Firebase للتاجر عند تغيير هذه القيمة                                                                                  |
| `isOpen`         | boolean | حالة المتجر (مفتوح/مغلق)                                                                                                                                       |
| `hidePhoneNumber` | boolean | إخفاء رقم الهاتف                                                                                                                                               |
| `currentLat`     | number  | خط العرض الحالي                                                                                                                                                 |
| `currentLng`     | number  | خط الطول الحالي                                                                                                                                                 |
| `image`          | file    | صورة الملف الشخصي الجديدة (JPG, JPEG, PNG, WebP, max 5MB). سيتم حذف الصورة القديمة تلقائياً ومعالجة الصورة الجديدة إلى عدة أحجام (original, mobile, thumbnail) |

### Request Example (multipart/form-data)

```bash
curl -X PATCH http://localhost:3000/api/v1/users/merchants/27 \
  -H "Authorization: Bearer <admin_token>" \
  -F "firstName=John Updated" \
  -F "image=@/path/to/new_profile.jpg"
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Merchant updated successfully",
  "data": {
    "location": {
      "lat": 33.5138,
      "lng": 36.2765
    },
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "id": 27,
    "firstName": "John Updated",
    "lastName": "Doe",
    "email": "merchant4@example.com",
    "phone": "+9639123455",
    "role": "MERCHANT",
    "notificationChannel": "WHATSAPP",
    "countryId": 1,
    "country": {
      "id": 1,
      "name": {
        "ar": "سوريا",
        "en": "Syria"
      },
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
      "name": {
        "ar": "دمشق",
        "en": "Damascus"
      },
      "countryId": 1
    },
    "address": "Damascus, Merchant Street 123",
    "isOnline": true,
    "verifiedAt": "2026-03-10T10:39:17.846Z",
    "birthday": "1990-05-15",
    "createdAt": "2026-03-10T10:39:17.846Z",
    "updatedAt": "2026-03-10T11:01:36.896Z",
    "deletedAt": null,
    "officeOwnerId": null,
    "imageId": 27,
    "image": {
      "id": 27,
      "entityType": "USER",
      "entityId": 27,
      "url": "http://localhost:3000/uploads/users/27/1773139884918_images2.webp",
      "mobileUrl": "http://localhost:3000/uploads/users/27/1773139884918_images2_mobile.webp",
      "thumbnailUrl": "http://localhost:3000/uploads/users/27/1773139884918_images2_thumb.webp",
      "isMain": true,
      "displayOrder": 0,
      "createdAt": "2026-03-10T10:51:25.168Z",
      "updatedAt": "2026-03-10T10:51:25.168Z"
    },
    "restaurantName": "Tasty Burger Restaurant",
    "isOpen": false,
    "description": null,
    "estimatedDeliveryMinutes": 30,
    "merchantIsActive": true
  },
  "timestamp": "2026-03-10T11:01:37.409Z",
  "path": "/api/v1/users/merchants/27"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن المستخدم ADMIN:

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants/27"
}
```

---

## 5. Delete Merchant (Hard Delete)

حذف تاجر (حذف نهائي - Hard Delete). يتم حذف التاجر وصوره ومنتجاته والطلبات المعلقة وسجل التاجر بشكل نهائي من قاعدة البيانات.

- **URL:** `/users/merchants/:id`
- **Method:** `DELETE`
- **Headers:** `Authorization: Bearer <admin_token>`

### URL Parameters

| Parameter | Type   | Description      |
| --------- | ------ | ---------------- |
| `id`      | number | معرف التاجر (ID) |

### ما يتم حذفه:

| العنصر          | الوصف                                    |
| --------------- | ---------------------------------------- |
| صور التاجر      | جميع صور الملف الشخصي                    |
| المنتجات        | جميع منتجات التاجر                       |
| صور المنتجات    | جميع صور المنتجات                        |
| التقييمات       | جميع تقييمات المنتجات                    |
| الطلبات المعلقة | الطلبات بالحالات `PENDING` و `CONFIRMED` |
| بيانات التاجر   | الحذف النهائي من قاعدة البيانات          |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Merchant deleted successfully",
  "data": {},
  "timestamp": "2026-02-26T06:14:14.957Z",
  "path": "/api/v1/users/merchants/9"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Merchant with ID 9 not found",
  "data": {},
  "timestamp": "2026-02-26T06:14:24.514Z",
  "path": "/api/v1/users/merchants/9"
}
```

---

## تفاصيل تقنية إضافية

- **المتحكم:** [MerchantController](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/controllers/merchant.controller.ts)
  - جميع endpoints محمية بـ `AuthGuard` و `RolesGuard` و `@Roles(UserRole.ADMIN)`
  - الإنشاء: `POST /users/merchants`
  - العرض (الكل مع البحث): `GET /users/merchants?search=` - البحث مدمج في نفس endpoint
  - العرض (واحد): `GET /users/merchants/:id`
  - التعديل: `PATCH /users/merchants/:id`
  - الحذف: `DELETE /users/merchants/:id`

- **الخدمة:** [MerchantService](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/services/merchant.service.ts)
  - التحقق من وجود البريد الإلكتروني: قبل الإنشاء
  - تشفير كلمة المرور: bcrypt
  - التحقق من الملكية: التأكد من عدم وجود مطاعم مرتبطة قبل الحذف
  - البحث الشامل: يبحث في firstName, lastName, email, phone
  - الفلترة والـ Pagination: دعم كامل لل paginated results
  - **معالجة الصور:** OneToOne relationship بين User و Image، روابط كاملة باستخدام StorageService.resolveUrl()
  - **Flattened Response:** بيانات المطعم تظهر مباشرة في الكائن الرئيسي

- **DTOs:**
  - [CreateMerchantDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/create-merchant.dto.ts)
  - [UpdateMerchantDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/update-merchant.dto.ts)
  - [FilterMerchantDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/auth/dto/filter-merchant.dto.ts)

- **ملف Postman:** [Delivery Jeeb - Merchants Module](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/DOCS/ApprovedPostman/Delivery Jeeb - Merchants Module.postman_collection.json)

---

## ملاحظات أمان

1. **الدور يتم تعيينه تلقائياً:** لا يمكن للـ ADMIN إنشاء مستخدم بدور آخر من خلال هذه endpoints
2. **التحقق من البريد:** يجب أن يكون البريد الإلكتروني فريداً في النظام
3. **تشفير كلمة المرور:** جميع كلمات المرور تُخزن مشفرة باستخدام bcrypt
4. **الحذف النهائي (Hard Delete):** عند حذف تاجر، يتم الحذف النهائي الكامل من قاعدة البيانات
5. **حذف المنتجات المرتبطة:** جميع منتجات التاجر وصورها وتقييماتها تُحذف نهائياً
6. **معالجة الصور:** OneToOne relationship بين User و Image، روابط كاملة بدون تكرار uploads

---

## ملاحظات هامة حول الاستجابة

- **Flattened Response:** بيانات المطعم (`restaurantName`, `isOpen`, `description`, `estimatedDeliveryMinutes`, `merchantIsActive`) تظهر مباشرة في الكائن الرئيسي وليست ضمن كائن `merchant` متداخل
- **Image URLs:** روابط الصور تأتي كاملة وصالحة للاستخدام المباشر (مثال: `http://localhost:3000/uploads/users/28/1773140361782_Screenshot (558).webp`)
- **Pagination:** جميع endpoints التي ترجع قوائم تدعم pagination مع معلومات كاملة عن الصفحات
- **Error Codes:** أخطاء مخصصة مع رموز فريدة لكل حالة (Email exists, Phone exists, Not found, etc.)

---

## 6. Confirm Merchant (ADMIN only)

تفعيل حساب التاجر عن طريق تعيين `isActive = true`. يتم إرسال إشعار Firebase للتاجر بعد التفعيل.

- **URL:** `/users/merchants/:id/confirm`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: application/json`

### URL Parameters

| Parameter | Type   | Description      |
| --------- | ------ | ---------------- |
| `id`      | number | معرف التاجر (ID) |

### Response (Success - 200 OK)

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
    "restaurantName": "Tasty Burger Restaurant",
    "merchantIsActive": true
  },
  "timestamp": "2026-03-10T11:00:05.329Z",
  "path": "/api/v1/users/merchants/27/confirm"
}
```

**ملاحظة:** بعد التفعيل، يتم إرسال إشعار Firebase للتاجر بعنوان "تفعيل الحساب" ومحتوى "تم تفعيل حساب مطعمك بنجاح. يمكنك الآن تسجيل الدخول."

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Merchant with ID 999 not found",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants/999/confirm"
}
```

### Response (Error - 400 Bad Request)

إذا كان التاجر مُفعَّلاً بالفعل:

```json
{
  "statusCode": 400,
  "message": "Merchant account is already active",
  "error": "Bad Request",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants/27/confirm"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن المستخدم ADMIN:

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden",
  "data": {},
  "timestamp": "2026-02-26T10:00:00.000Z",
  "path": "/api/v1/users/merchants/27/confirm"
}
```

---

## 7. Reset Merchant Password (ADMIN only)

إعادة تعيين كلمة مرور التاجر **بدون الحاجة لكلمة المرور القديمة**.

- **URL:** `/users/merchants/:id/reset-password`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
  - `Content-Type: application/json`

### URL Parameters

| Parameter | Type   | Description      |
| --------- | ------ | ---------------- |
| `id`      | number | معرف التاجر (ID) |

### Payload (JSON)

| Field      | Type   | Required | Description                                    |
| ---------- | ------ | -------- | ---------------------------------------------- |
| `password` | string | Yes      | كلمة المرور الجديدة (6 أحرف كحد أدنى)          |

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
    "id": 27,
    "firstName": "John",
    "lastName": "Doe",
    "email": "merchant@example.com",
    "phone": "+963912345678",
    "role": "MERCHANT",
    "isActive": true,
    "createdAt": "2026-03-10T10:00:00.000Z",
    "updatedAt": "2026-06-29T12:00:00.000Z"
  },
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/users/merchants/27/reset-password"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User with ID 999 not found",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/users/merchants/999/reset-password"
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

---

## 8. Auto-Sort by Distance for CUSTOMER

**الترتيب automatic حسب المسافة من موقع العميل.** (للمستخدمين من دور CUSTOMER عند استخدام `/merchants` endpoint).

- **URL:** `/merchants`
- **Method:** `GET`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <customer_token>`

### How It Works (for CUSTOMER)

```
1. CUSTOMER calls GET /merchants
2. System checks if role is CUSTOMER
3. System gets customer location from user entity:
   - Priority 1: user.location (JSON field)
   - Priority 2: user.currentLat + user.currentLng
4. IF location exists:
   a. Get all active merchants
   b. Use Google Directions API (real routes)
   c. Sort by distance (ascending)
   d. Return sorted results
5. IF no location:
   a. Return normal results (sorted by createdAt - DESC)
```

### Query Parameters (Additional for CUSTOMER)

| Parameter | Type    | Required | Description                               |
| --------- | ------- | -------- | ----------------------------------------- |
| `page`    | number  | No       | رقم الصفحة (افتراضي: 1)                   |
| `limit`   | number  | No       | عدد العناصر في الصفحة (افتراضي: 10)       |
| `search`  | string  | No       | البحث الشامل                              |
| `type`    | string  | No       | فلتر حسب نوع التاجر (RESTAURANT أو STORE) |
| `isOpen`  | boolean | No       | الفلترة حسب حالة المتجر (مفتوح/مغلق)      |

### Example URLs (CUSTOMER)

```
# جلب التجار (سيتم ترتيبهم تلقائياً حسب المسافة)
GET /merchants

# فلتر حسب نوع التاجر
GET /merchants?type=STORE

# فلتر حسب opened فقط
GET /merchants?isOpen=true&type=RESTAURANT
```

### Behavior Summary by Role

| Role       | Result Behavior                            |
| ---------- | ------------------------------------------ |
| `CUSTOMER` | ✅ Sorted by distance (if location exists) |
| `MERCHANT` | Normal (sorted by createdAt DESC)          |
| `DELIVERY` | Normal (sorted by createdAt DESC)          |
| `ADMIN`    | Normal (sorted by createdAt DESC)          |

### Response (Success - 200 OK) - CUSTOMER

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 5,
      "userId": 27,
      "restaurantName": "مطعم السلام",
      "type": "RESTAURANT",
      "isOpen": true,
      "description": "منتجات طازجة",
      "estimatedDeliveryMinutes": 30,
      "user": {
        "id": 27,
        "firstName": "أحمد",
        "lastName": "علي",
        "location": {
          "lat": 33.5138,
          "lng": 36.2765
        }
      }
    },
    {
      "id": 8,
      "userId": 35,
      "restaurantName": "متجر الكتب",
      "type": "STORE",
      "isOpen": true,
      "description": "كتب ومجلات",
      "estimatedDeliveryMinutes": 45,
      "user": {
        "id": 35,
        "firstName": "محمد",
        "lastName": "خالد",
        "location": {
          "lat": 33.52,
          "lng": 36.3
        }
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
  "timestamp": "2026-03-10T11:00:05.329Z",
  "path": "/api/v1/merchants"
}
```

### Settings (Optional)

These settings can be configured in the system:

| Setting                | Default | Description                    |
| ---------------------- | ------- | ------------------------------ |
| `nearbyMerchantRadius` | 10 km   | Radius for searching merchants |
| `nearbyMerchantLimit`  | 10      | Number of merchants to return  |
