# توثيق عمليات إدارة السائقين (Delivery/Driver CRUD Operations)

يوضح هذا المستند نقاط النهاية (Endpoints) الخاصة بإدارة المستخدمين من نوع "سائق" (Delivery) من قبل الإدارة.

## نظرة عامة (Overview)

جميع العمليات التالية تتطلب مصادقة (Authentication) وصلاحيات مدير (Admin).
يتم إرجاع البيانات ضمن الهيكلية الموحدة للاستجابة.

**Base URL**: `/users/deliveries`

---

## 1. عرض قائمة السائقين (List Drivers)

جلب قائمة السائقين مع إمكانية الفلترة والبحث والترقيم.

* **Method**: `GET`
* **URL**: `/users/deliveries`
* **Query Parameters**:
  * `page` (optional, int): رقم الصفحة (default: 1).
  * `limit` (optional, int): عدد العناصر في الصفحة (default: 10).
  * `search` (optional, string): البحث بالاسم، الإيميل، أو الهاتف.
  * `countryId` (optional, int): فلترة حسب الدولة.
  * `cityId` (optional, int): فلترة حسب المدينة.

### مثال طلب (Request Example)

```http
GET /users/deliveries?page=1&limit=10&search=driver&cityId=1
Authorization: Bearer <admin_token>
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [
        {
            "id": 10,
            "firstName": "Driver",
            "lastName": "One",
            "email": "driver@example.com",
            "phone": "+963912345678",
            "role": "DELIVERY",
            "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" } },
            "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
            "createdAt": "2023-10-27T10:00:00.000Z"
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
    "timestamp": "...",
    "path": "/users/deliveries"
}
```

---

## 2. عرض تفاصيل سائق (Get Driver Details)

جلب بيانات سائق محدد بواسطة المعرف (ID).

* **Method**: `GET`
* **URL**: `/users/deliveries/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": {
        "id": 10,
        "firstName": "Driver",
        "lastName": "One",
        "email": "driver@example.com",
        "phone": "+963912345678",
        "role": "DELIVERY",
        "country": { ... },
        "city": { ... }
    },
    "timestamp": "...",
    "path": "/users/deliveries/10"
}
```

---

## 3. إنشاء سائق جديد (Create Driver)

إضافة سائق جديد للنظام يدوياً من قبل الإدارة.

* **Method**: `POST`
* **URL**: `/users/deliveries`
* **Body (JSON)**:

```json
{
    "firstName": "New",
    "lastName": "Driver",
    "email": "new.driver@example.com",
    "password": "securePassword123",
    "phone": "+963999888777",
    "countryId": 1,
    "cityId": 1,
    "address": "Damascus, Garage",
    "notificationChannel": "WHATSAPP"
}
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 201,
    "message": "Operation successful",
    "data": {
        "id": 11,
        "email": "new.driver@example.com",
        "role": "DELIVERY",
        "createdAt": "..."
    },
    "timestamp": "...",
    "path": "/users/deliveries"
}
```

---

## 4. تحديث بيانات سائق (Update Driver)

تعديل بيانات سائق موجود.

* **Method**: `PATCH`
* **URL**: `/users/deliveries/:id`
* **Body (JSON)**: (إرسال الحقول المراد تعديلها فقط)

```json
{
    "firstName": "Driver Updated",
    "phone": "+963911111111"
}
```

---

## 5. حذف سائق (Delete Driver)

حذف سائق (Soft Delete) من النظام.

* **Method**: `DELETE`
* **URL**: `/users/deliveries/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": null,
    "timestamp": "...",
    "path": "/users/deliveries/10"
}
```
