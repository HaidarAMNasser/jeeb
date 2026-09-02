# Areas API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة والصلاحيات

- **عمليات الكتابة (Create, Update, Delete)** محصورة فقط بدور **المدير (ADMIN)**.
- **عمليات القراءة (Get All, Get One)** متاحة لأي مستخدم **مسجل دخول** (JWT مطلوب).
- الكيان يحتوي على: `id`, `name`, `price`, `description`.
- البحث (`search`) يعمل على الحقول الثلاثة: `name`, `description`، و `price` (كمحرّف إلى TEXT).
- كل الحقول النصية في البحث تستخدم **ILIKE** (غير حساس لحالة الأحرف).
- الفلترة بالسعر تتم عبر: `min_price` و `max_price`.

### تنسيق الاستجابة الموحّد (Response Envelope)

جميع الاستجابات تمر عبر `TransformInterceptor` وتُغلف بهذا التنسيق:

| الحقل | النوع | الظهور | الوصف |
|:---|---:|:---:|:---|
| `statusCode` | number | دائمًا | حالة HTTP |
| `message` | string | دائمًا | رسالة الحالة |
| `data` | object / array | دائمًا | بيانات الاستجابة (`{}` عند عدم وجود بيانات) |
| `pagination` | object | فقط في `findAll` | بيانات التصفح (انظر أدناه) |
| `timestamp` | string | دائمًا | وقت الاستجابة (ISO) |
| `path` | string | دائمًا | مسار الـ API |

هيكل `pagination`:

```json
{
  "total": 25,
  "page": 1,
  "limit": 10,
  "totalPages": 3,
  "hasNextPage": true,
  "hasPreviousPage": false
}
```

جميع الأخطاء تمر عبر `AllExceptionsFilter` بنفس القالب (`statusCode`, `message`, `data` كـ `{}`, `timestamp`, `path`).

---

## 1. Create Area (Admin Only)

إنشاء منطقة جديدة.

- **URL:** `/areas`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <admin_token>`
- **Roles:** `ADMIN` فقط

### Payload (Request Body)

| Key           | Type   | Required | Description              |
| ------------- | ------ | -------- | ------------------------ |
| `name`        | string | Yes      | اسم المنطقة              |
| `price`       | number | Yes      | سعر التوصيل (>= 0)       |
| `description` | string | No       | وصف المنطقة              |

```json
{
  "name": "Downtown",
  "price": 5000,
  "description": "Central business district delivery zone"
}
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Downtown",
    "price": "5000.00",
    "description": "Central business district delivery zone",
    "createdAt": "2026-03-10T12:00:00.000Z",
    "updatedAt": "2026-03-10T12:00:00.000Z"
  },
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Only Admins can create areas",
  "data": {},
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas"
}
```

---

## 2. Get All Areas

إرجاع قائمة المناطق مع pagination + search + price filters.

- **URL:** `/areas`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <access_token>`
- **Roles:** أي مستخدم مسجل دخول

### Query Parameters

| Parameter   | Type   | Required | Default | Description                                              |
| ----------- | ------ | -------- | ------- | -------------------------------------------------------- |
| `page`      | number | No       | 1       | رقم الصفحة                                                |
| `limit`     | number | No       | 10      | عدد العناصر في الصفحة                                      |
| `search`    | string | No       | —       | بحث غير حساس لحالة الأحرف (ILIKE) في `name`, `description`, `price` |
| `min_price` | number | No       | —       | الحد الأدنى للسعر (>= 0)                                  |
| `max_price` | number | No       | —       | الحد الأعلى للسعر (>= 0)                                  |

> **ملاحظة:** البحث يستخدم `ILIKE` (PostgreSQL) مع `%wildcard%` حول القيمة، غير حساس لحالة الأحرف. حقل `price` يُحوّل إلى TEXT للمقارنة النصية.

**Example URL:** `/areas?page=1&limit=10&search=downtown&min_price=1000&max_price=10000`

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 1,
      "name": "Downtown",
      "price": "5000.00",
      "description": "Central business district delivery zone",
      "createdAt": "2026-03-10T12:00:00.000Z",
      "updatedAt": "2026-03-10T12:00:00.000Z"
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
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas"
}
```

### Response (Error - 400 Bad Request)

عند `min_price > max_price`:

```json
{
  "statusCode": 400,
  "message": "min_price must be less than or equal to max_price",
  "data": {},
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas"
}
```

### Response (Error - 401 Unauthorized)

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "data": {},
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas"
}
```

---

## 3. Get One Area

عرض تفاصيل منطقة واحدة عبر معرّفها.

- **URL:** `/areas/:id`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <access_token>`
- **Roles:** أي مستخدم مسجل دخول
- **Params Validation:** `:id` يُمرر عبر `ParseIntPipe` — إذا لم يكن رقمًا صحيحًا يُرجع 400

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Downtown",
    "price": "5000.00",
    "description": "Central business district delivery zone",
    "createdAt": "2026-03-10T12:00:00.000Z",
    "updatedAt": "2026-03-10T12:00:00.000Z"
  },
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas/1"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Area with ID 999 not found",
  "data": {},
  "timestamp": "2026-03-10T12:00:00.000Z",
  "path": "/api/v1/areas/999"
}
```

---

## 4. Update Area (Admin Only)

تحديث تفاصيل المنطقة (تعديل جزئي مدعوم عبر `PATCH`).

- **URL:** `/areas/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <admin_token>`
- **Roles:** `ADMIN` فقط
- **Params Validation:** `:id` يُمرر عبر `ParseIntPipe`

### Payload (Request Body)

جميع الحقول اختيارية.

| Key           | Type   | Description        |
| ------------- | ------ | ------------------ |
| `name`        | string | الاسم الجديد       |
| `price`       | number | السعر الجديد (>=0) |
| `description` | string | الوصف الجديد       |

```json
{
  "name": "Updated Downtown",
  "price": 6000
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Updated Downtown",
    "price": "6000.00",
    "description": "Central business district delivery zone",
    "createdAt": "2026-03-10T12:00:00.000Z",
    "updatedAt": "2026-03-10T12:30:00.000Z"
  },
  "timestamp": "2026-03-10T12:30:00.000Z",
  "path": "/api/v1/areas/1"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Only Admins can update areas",
  "data": {},
  "timestamp": "2026-03-10T12:30:00.000Z",
  "path": "/api/v1/areas/1"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Area with ID 999 not found",
  "data": {},
  "timestamp": "2026-03-10T12:30:00.000Z",
  "path": "/api/v1/areas/999"
}
```

---

## 5. Delete Area (Admin Only)

حذف منطقة نهائياً.

- **URL:** `/areas/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Authorization: Bearer <admin_token>`
- **Roles:** `ADMIN` فقط
- **Params Validation:** `:id` يُمرر عبر `ParseIntPipe`

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Area deleted successfully",
  "data": {},
  "timestamp": "2026-03-10T12:40:00.000Z",
  "path": "/api/v1/areas/1"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Only Admins can delete areas",
  "data": {},
  "timestamp": "2026-03-10T12:40:00.000Z",
  "path": "/api/v1/areas/1"
}
```

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Area with ID 999 not found",
  "data": {},
  "timestamp": "2026-03-10T12:40:00.000Z",
  "path": "/api/v1/areas/999"
}
```

---

## Error Codes (معرفة في الكود — لا تُرجع حالياً في الاستجابة)

> **ملاحظة:** هذه الأكواد مُعرفة في `error-codes.ts` ولكن **لا تُستخدم حالياً** في `AreasService`. الاستجابات ترسل `statusCode` و `message` فقط عبر `AllExceptionsFilter`.

| Code | Constant                 | Description                                      |
| ---- | ------------------------ | ------------------------------------------------ |
| 7151 | `AREA_NOT_FOUND`         | Area not found                                   |
| 7152 | `AREA_INVALID_PRICE_RANGE` | min_price must be less than or equal to max_price |

---

## Notes

- **البحث**: يستخدم `SearchService.buildSearchConditions()` مع `ILIKE` (case-insensitive) على الحقول: `name`, `description`, `CAST(price AS TEXT)`.
- **الترتيب الافتراضي**: `createdAt DESC` (الأحدث أولاً).
- **`ParseIntPipe`**: جميع `:id` parameters تُمرر عبر `ParseIntPipe` — أي قيمة غير رقمية تُعيد `400 Bad Request`.
- **`PATCH` للتحديث**: يستخدم `PartialType(CreateAreaDto)` مما يجعل جميع الحقول اختيارية للتحديث.
- **الـ Guards**: `AuthGuard` + `RolesGuard` معمّمان على مستوى الـ Controller بالكامل.
- **العلاقة مع Order**: جدول `areas` مرتبط بجدول `orders` عبر `ManyToOne` — لا يمكن حذف منطقة مرتبطة بأي طلب موجود (قيد خارجي).
