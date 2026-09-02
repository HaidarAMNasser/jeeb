# Statistics API Documentation

Base URL: `https://api.jeeb2.com/api/v1`

---

## 1. نظرة عامة

نظام الإحصاءات يوفر بيانات تحليلية عن المطاعم وطلباتهم، مخصص للوحة تحكم المدير (Admin Panel).

- **Base URL:** `/statistics`
- **Authentication:** Required (Bearer Token)
- **الصلاحية:** ADMIN فقط

---

## 2. Merchant Statistics — إحصاءات المطاعم

جلب إحصاءات جميع المطاعم مع إمكانية التصفية والبحث والترتيب.

- **URL:** `/statistics/merchants`
- **Method:** `GET`
- **Authentication:** Required
- **الصلاحية:** ADMIN فقط

### 2.1 Query Parameters

| Parameter    | Type   | Required | Default | Description                                        |
| ------------ | ------ | -------- | ------- | -------------------------------------------------- |
| `page`       | number | No       | 1       | رقم الصفحة                                         |
| `limit`      | number | No       | 10      | عدد العناصر في الصفحة                              |
| `search`     | string | No       | —       | بحث في اسم المطعم، الاسم الأول، اسم العائلة         |
| `from`       | string | No       | —       | بداية نطاق التاريخ (ISO 8601) — يصفي الطلبات       |
| `to`         | string | No       | —       | نهاية نطاق التاريخ (ISO 8601) — يصفي الطلبات       |
| `merchantId` | number | No       | —       | معرف التاجر (userId) — لإحصاءات مطعم محدد          |

### 2.2 هيكل عنصر الـ Response (MerchantStatsItem)

```json
{
    "id": 5,
    "userId": 27,
    "name": "Tasty Burger",
    "type": "RESTAURANT",
    "location": {
        "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" } },
        "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
        "coordinates": { "lat": 33.5138, "lng": 36.2765 }
    },
    "stats": {
        "totalOrders": 150,
        "totalRevenue": 1250000
    }
}
```

| الحقل                    | النوع                                      | الوصف                            |
| ------------------------ | ------------------------------------------ | -------------------------------- |
| `id`                     | number                                     | معرف المطعم (من جدول merchants)  |
| `userId`                 | number                                     | معرف المستخدم (من جدول users)    |
| `name`                   | string or null                             | اسم المطعم (restaurantName)     |
| `type`                   | enum (RESTAURANT / STORE)                  | نوع المطعم                       |
| `location.country`       | `{ id, name }` or null                     | الدولة (name كائن JSONB ar/en)   |
| `location.city`          | `{ id, name }` or null                     | المدينة (name كائن JSONB ar/en)   |
| `location.coordinates`   | `{ lat, lng }` or null                     | الإحداثيات الجغرافية             |
| `stats.totalOrders`      | number                                     | إجمالي عدد الطلبات               |
| `stats.totalRevenue`     | number                                     | إجمالي value الطلبات (بأصغر وحدة عملة) |

### 2.3 أمثلة URLs

| الغرض                                            | الـ URL                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------ |
| جلب كل المطاعم (الصفحة 1)                        | `/statistics/merchants`                                                  |
| الصفحة 2، 5 عناصر                                | `/statistics/merchants?page=2&limit=5`                                   |
| بحث باسم "burger"                                | `/statistics/merchants?search=burger`                                    |
| طلبات من 2026-01-01 إلى 2026-06-08               | `/statistics/merchants?from=2026-01-01&to=2026-06-08`                    |
| مطعم محدد (userId = 27)                          | `/statistics/merchants?merchantId=27`                                    |
| الكل معاً                                        | `/statistics/merchants?page=1&limit=10&search=burger&from=2026-01-01&to=2026-06-08&merchantId=27` |

### 2.4 Request Example

```bash
GET /api/v1/statistics/merchants?page=1&limit=10&search=burger&from=2026-01-01&to=2026-06-08
Authorization: Bearer <admin_token>
```

### 2.5 Response Example (Success — 200 OK)

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [
        {
            "id": 5,
            "userId": 27,
            "name": "Tasty Burger",
            "type": "RESTAURANT",
            "location": {
                "country": {
                    "id": 1,
                    "name": { "ar": "سوريا", "en": "Syria" }
                },
                "city": {
                    "id": 1,
                    "name": { "ar": "دمشق", "en": "Damascus" }
                },
                "coordinates": {
                    "lat": 33.5138,
                    "lng": 36.2765
                }
            },
            "stats": {
                "totalOrders": 150,
                "totalRevenue": 1250000
            }
        },
        {
            "id": 8,
            "userId": 34,
            "name": "Pizza House",
            "type": "RESTAURANT",
            "location": {
                "country": {
                    "id": 1,
                    "name": { "ar": "سوريا", "en": "Syria" }
                },
                "city": {
                    "id": 2,
                    "name": { "ar": "حلب", "en": "Aleppo" }
                },
                "coordinates": null
            },
            "stats": {
                "totalOrders": 89,
                "totalRevenue": 780000
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
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

### 2.6 Response (Empty — 200 OK)

عند عدم وجود نتائج:

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [],
    "pagination": {
        "total": 0,
        "page": 1,
        "limit": 10,
        "totalPages": 0,
        "hasNextPage": false,
        "hasPreviousPage": false
    },
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

### 2.7 Response (Error — 403 Forbidden)

عند محاولة مستخدم غير ADMIN:

```json
{
    "statusCode": 403,
    "message": "Forbidden resource",
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

### 2.8 Response (Error — 401 Unauthorized)

عند عدم إرسال التوكن أو انتهاء صلاحيته:

```json
{
    "statusCode": 401,
    "message": "Unauthorized",
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

---

## 3. Location Object

الكائن `location` داخل كل عنصر يمثل موقع المطعم الجغرافي والإداري.

```json
{
    "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" } },
    "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
    "coordinates": { "lat": 33.5138, "lng": 36.2765 }
}
```

| الحقل          | النوع                     | ملاحظة                                |
| -------------- | ------------------------- | ------------------------------------- |
| `country`      | `{ id, name }` or null    | `name` هو JSONB `{ ar, en }`          |
| `city`         | `{ id, name }` or null    | `name` هو JSONB `{ ar, en }`          |
| `coordinates`  | `{ lat, lng }` or null    | إحداثيات من جدول users (`location`)   |

> إذا كان المطعم لا يملك دولة أو مدينة أو إحداثيات، تكون القيمة `null`.

---

## 4. Stats Object

الكائن `stats` داخل كل عنصر يمثل إحصاءات الطلبات لذلك المطعم.

```json
{
    "totalOrders": 150,
    "totalRevenue": 1250000
}
```

| الحقل          | النوع   | الوصف                                              |
| -------------- | ------- | -------------------------------------------------- |
| `totalOrders`  | number  | إجمالي عدد الطلبات                                 |
| `totalRevenue` | number  | مجموع `totalAmount` لجميع الطلبات (بأصغر وحدة عملة) |

> **ملاحظة**: `totalRevenue` مخزنة بأصغر وحدة عملة (هللة/قرش). للعرض، قسم على 100: `1250000 ÷ 100 = 12,500.00 SAR`.

---

## 5. Pagination Structure

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

| الحقل             | النوع    | الوصف                     |
| ----------------- | -------- | ------------------------- |
| `total`           | number   | إجمالي عدد المطاعم        |
| `page`            | number   | رقم الصفحة الحالية        |
| `limit`           | number   | عدد العناصر في الصفحة     |
| `totalPages`      | number   | إجمالي عدد الصفحات        |
| `hasNextPage`     | boolean  | هل توجد صفحة تالية؟       |
| `hasPreviousPage` | boolean  | هل توجد صفحة سابقة؟       |

---

## 6. Search Logic

آلية البحث الموحد تطبق على الحقول التالية معاً باستخدام `ILIKE` (غير حساس لحالة الأحرف):

| الحقل                | المصدر                  |
| -------------------- | ----------------------- |
| `merchant.restaurantName` | اسم المطعم         |
| `user.firstName`     | الاسم الأول للتاجر      |
| `user.lastName`      | اسم العائلة للتاجر      |

مثال: `search=burger` يطابق:
- `restaurantName` = **"Tasty Burger"**
- `firstName` = **"Burger King"** (لو كان موجوداً)

---

## 7. Date Filtering

يتم تطبيق `from` و `to` على حقل `order.createdAt` (تاريخ إنشاء الطلب):

| الشرط              | التأثير                                           |
| ------------------ | ------------------------------------------------- |
| بدون `from`/`to`   | جميع الطلبات (بدون فلتر تاريخي)                   |
| `from` فقط         | الطلبات من التاريخ المحدد فصاعداً                 |
| `to` فقط           | الطلبات حتى التاريخ المحدد                        |
| `from` + `to`      | الطلبات ضمن النطاق التاريخي                       |

> **ملاحظة**: فلاتر التاريخ تؤثر فقط على إحصاءات الطلبات (`stats`). المطاعم نفسها تظهر بغض النظر عن وجود طلبات في النطاق الزمني.

---

## 8. Merchant Type

| القيمة       | الوصف     |
| ------------ | --------- |
| `RESTAURANT` | مطعم      |
| `STORE`      | متجر      |

---

## 9. Notes

1. **الصلاحية:** هذا الـ endpoint متاح فقط للمستخدمين بدور `ADMIN`
2. **الترتيب:** المطاعم مرتبة حسب `merchant.createdAt` تنازلياً (الأحدث أولاً)
3. **إحصاءات فارغة:** إذا لم يكن للمطعم أي طلبات، تكون `totalOrders = 0` و `totalRevenue = 0`
4. **الـ search:** غير حساس لحالة الأحرف — يبحث في اسم المطعم واسم التاجر
5. **فلاتر التاريخ:** تطبق فقط على الطلبات — لا تؤثر على قائمة المطاعم
6. **الـ totalRevenue:** بأصغر وحدة عملة — قسّم على `currencyFactor` للحصول على القيمة المعروضة
7. **الترحيل (Pagination):** يتم التعامل معه تلقائياً عبر `TransformInterceptor`
