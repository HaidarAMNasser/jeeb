# توثيق عمليات إدارة العملاء (Customer CRUD Operations)

يوضح هذا المستند نقاط النهاية (Endpoints) الخاصة بإدارة المستخدمين من نوع "عميل" (Customer) من قبل الإدارة.

## نظرة عامة (Overview)

جميع العمليات التالية تتطلب مصادقة (Authentication) وصلاحيات مدير (Admin).
يتم إرجاع البيانات ضمن الهيكلية الموحدة للاستجابة.

**Base URL**: `/users/customers`

---

## 1. عرض قائمة العملاء (List Customers)

جلب قائمة العملاء مع إمكانية الفلترة والبحث والترقيم.

* **Method**: `GET`
* **URL**: `/users/customers`
* **Query Parameters**:
  * `page` (optional, int): رقم الصفحة (default: 1).
  * `limit` (optional, int): عدد العناصر في الصفحة (default: 10).
  * `search` (optional, string): البحث بالاسم، الإيميل، أو الهاتف.
  * `countryId` (optional, int): فلترة حسب الدولة.
  * `cityId` (optional, int): فلترة حسب المدينة.

### مثال طلب (Request Example)

```http
GET /users/customers?page=1&limit=10&search=ahmed&cityId=1
Authorization: Bearer <admin_token>
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [
        {
            "id": 1,
            "firstName": "Ahmed",
            "lastName": "Ali",
            "email": "ahmed@example.com",
            "phone": "+963912345678",
            "role": "CUSTOMER",
            "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" } },
            "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
            "createdAt": "2023-10-27T10:00:00.000Z"
        }
    ],
    "pagination": {
        "total": 50,
        "page": 1,
        "limit": 10,
        "totalPages": 5,
        "hasNextPage": true,
        "hasPreviousPage": false
    },
    "timestamp": "...",
    "path": "/users/customers"
}
```

---

## 2. عرض تفاصيل عميل (Get Customer Details)

جلب بيانات عميل محدد بواسطة المعرف (ID).

* **Method**: `GET`
* **URL**: `/users/customers/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": {
        "id": 1,
        "firstName": "Ahmed",
        "lastName": "Ali",
        "email": "ahmed@example.com",
        "phone": "+963912345678",
        "role": "CUSTOMER",
        "wallet": { ... }, // إذا وجدت علاقة
        "country": { ... },
        "city": { ... }
    },
    "timestamp": "...",
    "path": "/users/customers/1"
}
```

---

## 3. إنشاء عميل جديد (Create Customer)

إضافة عميل جديد للنظام يدوياً من قبل الإدارة.

* **Method**: `POST`
* **URL**: `/users/customers`
* **Body (JSON)**:

```json
{
    "firstName": "Samer",
    "lastName": "Hassan",
    "email": "samer@example.com",
    "password": "securePassword123",
    "phone": "+963987654321",
    "countryId": 1,
    "cityId": 1,
    "address": "Aleppo, Street 5",
    "notificationChannel": "WHATSAPP"
}
```

### مثال استجابة (Response Example)

```json
{
    "statusCode": 201,
    "message": "Operation successful",
    "data": {
        "id": 2,
        "email": "samer@example.com",
        "role": "CUSTOMER",
        "createdAt": "..."
    },
    "timestamp": "...",
    "path": "/users/customers"
}
```

---

## 4. تحديث بيانات عميل (Update Customer)

تعديل بيانات عميل موجود.

* **Method**: `PATCH`
* **URL**: `/users/customers/:id`
* **Body (JSON)**: (إرسال الحقول المراد تعديلها فقط)

```json
{
    "firstName": "Samer Updated",
    "phone": "+963999999999"
}
```

---

## 5. حذف عميل (Delete Customer)

حذف عميل (Soft Delete) من النظام.

* **Method**: `DELETE`
* **URL**: `/users/customers/:id`

### مثال استجابة (Response Example)

```json
{
    "statusCode": 200,
    "message": "Operation successful", // أو لا يتم إرجاع محتوى حسب التنفيذ
    "data": null,
    "timestamp": "...",
    "path": "/users/customers/2"
}
```
