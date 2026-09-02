# توثيق عمليات إدارة التجار (Merchant CRUD Operations)

يوضح هذا المستند نقاط النهاية (Endpoints) الخاصة بإدارة المستخدمين من نوع "تاجر" (Merchant) من قبل الإدارة.

## نظرة عامة (Overview)

جميع العمليات التالية تتطلب مصادقة (Authentication) وصلاحيات مدير (Admin).
يتم إرجاع البيانات ضمن الهيكلية الموحدة للاستجابة.

**Base URL**: `/users/merchants`

---

## 1. عرض قائمة التجار (List Merchants)

جلب قائمة التجار مع إمكانية الفلترة والبحث والترقيم.

* **Method**: `GET`
* **URL**: `/users/merchants`
* **Query Parameters**:
* `page` (optional, int): رقم الصفحة (default: 1).
* `limit` (optional, int): عدد العناصر في الصفحة (default: 10).
* `search` (optional, string): البحث بالاسم، الإيميل، أو الهاتف.
* `countryId` (optional, int): فلترة حسب الدولة.
* `cityId` (optional, int): فلترة حسب المدينة.

### مثال طلب (Request Example)

```http
GET /users/merchants?page=1&limit=10&search=restaurant&cityId=1
Authorization: Bearer <admin_token>
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [
        {
            "id": 5,
            "firstName": "Sami",
            "lastName": "Owner",
            "email": "owner@restaurant.com",
            "phone": "+963912345678",
            "role": "MERCHANT",
            "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" } },
            "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
            "createdAt": "2023-10-27T10:00:00.000Z"
        }
    ],
    "pagination": {
        "total": 12,
        "page": 1,
        "limit": 10,
        "totalPages": 2,
        "hasNextPage": true,
        "hasPreviousPage": false
    },
    "timestamp": "...",
    "path": "/users/merchants"
}
```

---

## 2. عرض تفاصيل تاجر (Get Merchant Details)

جلب بيانات تاجر محدد بواسطة المعرف (ID).

* **Method**: `GET`
* **URL**: `/users/merchants/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": {
        "id": 5,
        "firstName": "Sami",
        "lastName": "Owner",
        "email": "owner@restaurant.com",
        "phone": "+963912345678",
        "role": "MERCHANT",
        "country": { ... },
        "city": { ... }
    },
    "timestamp": "...",
    "path": "/users/merchants/5"
}
```

---

## 3. إنشاء تاجر جديد (Create Merchant)

إضافة تاجر جديد للنظام يدوياً من قبل الإدارة.

* **Method**: `POST`
* **URL**: `/users/merchants`
* **Body (JSON)**:

```json
{
    "firstName": "New",
    "lastName": "Merchant",
    "email": "merchant@example.com",
    "password": "securePassword123",
    "phone": "+963987654321",
    "countryId": 1,
    "cityId": 1,
    "address": "Damascus, City Center",
    "notificationChannel": "WHATSAPP"
}
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 201,
    "message": "Operation successful",
    "data": {
        "id": 6,
        "email": "merchant@example.com",
        "role": "MERCHANT",
        "createdAt": "..."
    },
    "timestamp": "...",
    "path": "/users/merchants"
}
```

---

## 4. تحديث بيانات تاجر (Update Merchant)

تعديل بيانات تاجر موجود.

* **Method**: `PATCH`
* **URL**: `/users/merchants/:id`
* **Body (JSON)**: (إرسال الحقول المراد تعديلها فقط)

```json
{
    "firstName": "Sami Updated",
    "phone": "+963999999999"
}
```

---

## 5. حذف تاجر (Delete Merchant)

حذف تاجر (Soft Delete) من النظام.

* **Method**: `DELETE`
* **URL**: `/users/merchants/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": null,
    "timestamp": "...",
    "path": "/users/merchants/5"
}
```
