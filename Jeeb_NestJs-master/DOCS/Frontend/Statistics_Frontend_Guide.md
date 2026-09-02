# دليل إحصاءات المطاعم - دليل الربط مع الواجهة الأمامية (Frontend)

تاريخ التحديث: 2026-06-08

---

## 1. نظرة عامة

هذا الـ endpoint يوفّر إحصاءات كاملة عن المطاعم وطلباتهم، مخصص للوحة تحكم المدير (Admin Panel).

- **Base URL:** `/statistics/merchants`
- **Method:** `GET`
- **Authentication:** Required (Bearer Token)
- **الصلاحية:** ADMIN فقط

> جميع المستخدمين غير ADMIN سيحصلون على خطأ `403 Forbidden`.

---

## 2. معاملات الـ Query

| Parameter    | Type   | Required | Default | Description                                        |
| ------------ | ------ | -------- | ------- | -------------------------------------------------- |
| `page`       | number | No       | 1       | رقم الصفحة                                         |
| `limit`      | number | No       | 10      | عدد العناصر في الصفحة                              |
| `search`     | string | No       | —       | بحث في اسم المطعم، الاسم الأول، اسم العائلة         |
| `from`       | string | No       | —       | بداية نطاق التاريخ (ISO 8601) — يصفي الطلبات       |
| `to`         | string | No       | —       | نهاية نطاق التاريخ (ISO 8601) — يصفي الطلبات       |
| `merchantId` | number | No       | —       | معرف التاجر (userId) — لإحصاءات مطعم محدد          |

### أمثلة URLs

| الغرض                                            | الـ URL                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------ |
| جلب كل المطاعم (الصفحة 1)                        | `/statistics/merchants`                                                  |
| الصفحة 2، 5 عناصر                                | `/statistics/merchants?page=2&limit=5`                                   |
| بحث باسم "burger"                                | `/statistics/merchants?search=burger`                                    |
| طلبات من 2026-01-01 إلى 2026-06-08               | `/statistics/merchants?from=2026-01-01&to=2026-06-08`                    |
| مطعم محدد (userId = 27)                          | `/statistics/merchants?merchantId=27`                                    |
| الكل معاً                                        | `/statistics/merchants?page=1&limit=10&search=burger&from=2026-01-01&to=2026-06-08&merchantId=27` |

---

## 3. شكل الـ Response

### 3.1 Response (Success — 200 OK)

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

### 3.2 Response (Empty — 200 OK)

عند عدم وجود نتائج أو بحث بدون تطابق:

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

### 3.3 Response (Error — 403 Forbidden)

عند محاولة مستخدم غير ADMIN:

```json
{
    "statusCode": 403,
    "message": "Forbidden resource",
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

### 3.4 Response (Error — 401 Unauthorized)

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

## 4. هيكل البيانات

### 4.1 MerchantStatsItem (عنصر المطعم)

| الحقل                  | النوع                                      | الوصف                                     |
| ---------------------- | ------------------------------------------ | ----------------------------------------- |
| `id`                   | number                                     | معرف المطعم (من جدول merchants)           |
| `userId`               | number                                     | معرف المستخدم (من جدول users)             |
| `name`                 | string or null                             | اسم المطعم (restaurantName)               |
| `type`                 | string (RESTAURANT / STORE)                | نوع المطعم                               |
| `location.country`     | `{ id: number, name: object }` or null     | الدولة (name هو JSONB `{ ar, en }`)       |
| `location.city`        | `{ id: number, name: object }` or null     | المدينة (name هو JSONB `{ ar, en }`)      |
| `location.coordinates` | `{ lat: number, lng: number }` or null     | الإحداثيات الجغرافية                      |
| `stats.totalOrders`    | number                                     | إجمالي عدد الطلبات                        |
| `stats.totalRevenue`   | number                                     | مجموع الفواتير (بأصغر وحدة عملة)          |

### 4.2 Pagination (الترحيل)

| الحقل             | النوع    | الوصف                     |
| ----------------- | -------- | ------------------------- |
| `total`           | number   | إجمالي عدد المطاعم        |
| `page`            | number   | رقم الصفحة الحالية        |
| `limit`           | number   | عدد العناصر في الصفحة     |
| `totalPages`      | number   | إجمالي عدد الصفحات        |
| `hasNextPage`     | boolean  | هل توجد صفحة تالية؟       |
| `hasPreviousPage` | boolean  | هل توجد صفحة سابقة؟       |

---

## 5. هيكل الـ Response العام

الـ API يستخدم `TransformInterceptor` الذي يغلف كل الردود بهذا الشكل:

```json
{
    "statusCode": 200,
    "message": "Operation successful",
    "data": [ /* المصفوفة */ ],
    "pagination": { /* كائن pagination */ },
    "timestamp": "2026-06-08T10:00:00.000Z",
    "path": "/api/v1/statistics/merchants"
}
```

- إذا كانت `data` مصفوفة فارغة → `[]` (وليس `{}`)
- إذا لم تكن هناك نتائج → `total: 0` و `totalPages: 0`

---

## 6. تفاصيل الحقول

### 6.1 `name`

- مصدره `restaurantName` من جدول `merchants`
- يمكن أن يكون `null` إذا لم يحدد المطعم اسماً

### 6.2 `type`

- `RESTAURANT` — مطعم
- `STORE` — متجر

### 6.3 `location.country`

- إذا كان المطعم يملك دولة: `{ id: 1, name: { ar: "سوريا", en: "Syria" } }`
- إذا لم يكن: `null`
- `name` هو كائن JSONB ثنائي اللغة (عربي + إنجليزي)

### 6.4 `location.city`

- إذا كان المطعم يملك مدينة: `{ id: 1, name: { ar: "دمشق", en: "Damascus" } }`
- إذا لم يكن: `null`

### 6.5 `location.coordinates`

- إحداثيات من حقل `location` في جدول `users`
- إذا وجدت: `{ lat: 33.5138, lng: 36.2765 }`
- إذا لم توجد: `null`

### 6.6 `stats.totalOrders`

- عدد الطلبات المرتبطة بهذا المطعم (حسب `order.ownerId = merchant.userId`)
- `0` إذا لم توجد طلبات

### 6.7 `stats.totalRevenue`

- مجموع `totalAmount` لكل الطلبات
- `0` إذا لم توجد طلبات
- القيمة بأصغر وحدة عملة (هللة/قرش)
- للعرض: `value = totalRevenue / currencyFactor`
- مثال: `1250000 ÷ 100 = 12,500.00 SAR`

---

## 7. آلية البحث (Search Logic)

البحر يطبق على 3 حقول معاً باستخدام `ILIKE` (غير حساس لحالة الأحرف):

| الحقل                | المصدر                  |
| -------------------- | ----------------------- |
| `merchant.restaurantName` | اسم المطعم         |
| `user.firstName`     | الاسم الأول للتاجر      |
| `user.lastName`      | اسم العائلة للتاجر      |

مثال: `search=burger` يطابق:
- `restaurantName` = **"Tasty Burger"**
- `firstName` = **"Burger King"**

---

## 8. تصفية التاريخ (Date Filtering)

| الشرط              | التأثير                                           |
| ------------------ | ------------------------------------------------- |
| بدون `from`/`to`   | جميع الطلبات (بدون فلتر تاريخي)                   |
| `from` فقط         | الطلبات من التاريخ المحدد فصاعداً                 |
| `to` فقط           | الطلبات حتى التاريخ المحدد                        |
| `from` + `to`      | الطلبات ضمن النطاق التاريخي                       |

> **ملاحظة مهمة**: فلاتر التاريخ تؤثر فقط على `stats` (إحصاءات الطلبات). المطاعم نفسها تظهر دائماً بغض النظر عن وجود طلبات في النطاق الزمني.

---

## 9. الترتيب (Ordering)

المطاعم مرتّبة حسب `merchant.createdAt` تنازلياً (الأحدث أولاً).

---

## 10. Types/Interfaces المقترحة للـ Frontend

```typescript
enum MerchantType {
  RESTAURANT = 'RESTAURANT',
  STORE = 'STORE',
}

interface CountryInfo {
  id: number;
  name: { ar: string; en: string };
}

interface CityInfo {
  id: number;
  name: { ar: string; en: string };
}

interface Coordinates {
  lat: number;
  lng: number;
}

interface MerchantLocation {
  country: CountryInfo | null;
  city: CityInfo | null;
  coordinates: Coordinates | null;
}

interface MerchantStats {
  totalOrders: number;
  totalRevenue: number;
}

interface MerchantStatsItem {
  id: number;
  userId: number;
  name: string | null;
  type: MerchantType;
  location: MerchantLocation;
  stats: MerchantStats;
}

interface MerchantStatsQuery {
  page?: number;
  limit?: number;
  search?: string;
  from?: string;   // ISO 8601
  to?: string;     // ISO 8601
  merchantId?: number;
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

interface ApiResponse<T> {
  statusCode: number;
  message: string;
  data: T;
  pagination?: PaginationMeta;
  timestamp: string;
  path: string;
}
```

---

## 11. واجب الـ Frontend

| السيناريو | الإجراء |
|:---|---:|
| **صفحة إحصاءات المطاعم (Admin Panel)** | أضف جدولاً يعرض المطاعم مع إحصاءاتهم (عدد الطلبات + الإيرادات) |
| **عرض الـ location** | اعرض الدولة والمدينة كـ "سوريا، دمشق" والإحداثيات على خريطة (إذا وجدت) |
| **عرض قيمة الـ totalRevenue** | حولها من أصغر وحدة عملة: `(totalRevenue / 100).toFixed(2)` |
| **إضافة search** | أضف حقل بحث يرسل `search` parameter — يبحث بالاسم واسم المطعم |
| **إضافة date filter** | أضف منتقي تاريخ (date picker) لـ `from` و `to` |
| **إضافة filter merchantId** | أضف قائمة منسدلة لاختيار مطعم محدد |
| **Pagination** | استخدم `page` و `limit` و `totalPages` و `hasNextPage` لبناء أزرار التنقل |
| **معالجة الأخطاء** | تعامل مع `403` (ليس ADMIN)، `401` (غير مصرح)، `400` (معاملات غير صالحة) |
| **تحديث Types** | أضف الـ interfaces المذكورة أعلاه في مشروع الـ Frontend |

---

## 12. ملاحظات إضافية

1. **الترحيل (Pagination)**: يتم التعامل معه تلقائياً عبر `TransformInterceptor` — الـ `data` دائماً مصفوفة
2. **الفرق بين الـ id**: `id` هو معرف المطعم (من `merchants`)، `userId` هو معرف المستخدم (من `users`)
3. **المطاعم بدون طلبات**: `totalOrders = 0` و `totalRevenue = 0` — تظهر في القائمة بشكل طبيعي
4. **الـ name**: قد يكون `null` إذا لم يحدد المطعم `restaurantName`
5. **الـ coordinates**: قد تكون `null` — في هذه الحالة لا تعرض خريطة
6. **الـ country/city**: قد يكون `null` — اعرض "غير محدد" في هذه الحالة
