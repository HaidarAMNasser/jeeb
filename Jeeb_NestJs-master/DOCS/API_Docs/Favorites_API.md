# Favorites API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## نظرة عامة

- المفضّلة متاحة للمستخدمين من نوع CUSTOMER وأيضاً للمستخدمين الضيوف (Guest).
- الأنواع المدعومة حالياً: منتجات فقط (`PRODUCT`).
- عمليات إضافة/حذف المفضلات تتم بشكل مجمّع (Bulk).
- جلب المفضلات مدعوم بالترقيد (Pagination).

---

## 1. Toggle Favorites (Bulk)

إضافة أو حذف منتجات من المفضلة بشكل مجمّع. إذا كان المنتج موجوداً في المفضلة يُحذف، وإذا لم يكن موجوداً يُضاف.

- **URL:** `/favorites/toggle`
- **Method:** `POST`
- **Auth Required:** Yes (Bearer Token)
- **Guest Access:** Yes (`@AllowGuest()` — يمكن للمستخدمين الضيوف استخدام هذه العملية)
- **Roles Required:** None

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |
| `Content-Type` | Yes | `application/json` |

### Request Body

| Parameter | Type | Required | Description |
| :---------------- | :------ | :------- | :-------------- |
| `products` | Number[] | No | قائمة معرفات المنتجات. Validation: `@IsOptional()` `@IsArray()` `@IsInt({ each: true })` |

### Request Example

```json
{
  "products": [10, 11, 12]
}
```

### Response (Success - 200 OK)

يتم إرجاع المنتجات التي **تمت إضافتها فقط** (المنتجات الجديدة في المفضلات). المنتجات التي تم حذفها لا تظهر في الاستجابة.

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "products": [
      {
        "id": 10,
        "name": "Delicious Burger",
        "price": 1299,
        "category": "وجبات سريعة"
      },
      {
        "id": 11,
        "name": "Chicken Sandwich",
        "price": 899,
        "category": "وجبات سريعة"
      }
    ]
  },
  "timestamp": "2026-06-12T10:00:00.000Z",
  "path": "/api/v1/favorites/toggle"
}
```

### Response Fields

| Field | Type | Description |
| :------------ | :-------- | :------------------------------ |
| `products` | Array | قائمة المنتجات التي تمت إضافتها للمفضلة |
| `products[].id` | Number | معرف المنتج |
| `products[].name` | String | اسم المنتج |
| `products[].price` | Number | السعر |
| `products[].category` | String or null | اسم التصنيف |

> **ملاحظة:** لا تحتوي استجابة Toggle على حقل `images`. الصور متاحة فقط في استجابة جلب المفضلات (Section 2).

### Response (Error - 404 Not Found)

إذا لم يُعثر على أحد المنتجات:

```json
{
  "statusCode": 404,
  "message": "Product with ID 999 not found",
  "error": "Not Found"
}
```

### Response (Error - 400 Bad Request)

إذا كانت `products` تحتوي على قيم غير صحيحة (مثل نصوص بدلاً من أرقام):

```json
{
  "statusCode": 400,
  "message": ["each value in products must be an integer number"],
  "error": "Bad Request"
}
```

---

## 2. Get All Favorites (Paginated)

- **URL:** `/favorites`
- **Method:** `GET`
- **Auth Required:** Yes (Bearer Token)
- **Guest Access:** No (غير مسموح للضيوف)
- **Roles Required:** None

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Query Parameters

| Parameter | Type | Required | Default | Description |
| :-------- | :--- | :------- | :------ | :---------- |
| `page` | Number | No | `1` | رقم الصفحة |
| `limit` | Number | No | `10` | عدد العناصر في الصفحة |

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "products": [
        {
          "id": 10,
          "name": "Delicious Burger",
          "price": 1299,
          "category": "وجبات سريعة",
          "images": [
            {
              "id": 1,
              "url": "https://example.com/burger.webp",
              "mobileUrl": "https://example.com/burger_mobile.webp",
              "thumbnailUrl": "https://example.com/burger_thumb.webp",
              "isMain": true
            }
          ]
        },
        {
          "id": 11,
          "name": "Chicken Sandwich",
          "price": 899,
          "category": "وجبات سريعة",
          "images": [
            {
              "id": 2,
              "url": "https://example.com/sandwich.webp",
              "mobileUrl": "https://example.com/sandwich_mobile.webp",
              "thumbnailUrl": "https://example.com/sandwich_thumb.webp",
              "isMain": true
            }
          ]
        },
        {
          "id": 12,
          "name": "French Fries",
          "price": 299,
          "category": "وجبات جانبية",
          "images": []
        }
      ]
    }
  ],
  "pagination": {
    "total": 3,
    "page": 1,
    "limit": 10,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "timestamp": "2026-06-12T10:00:00.000Z",
  "path": "/api/v1/favorites"
}
```

### Product Fields

| Field | Type | Description | Available In |
| :-------- | :-------------- | :---------------------------- | :------------------- |
| `id` | Number | معرّف المنتج | Toggle + Get All |
| `name` | String | اسم المنتج | Toggle + Get All |
| `price` | Number | السعر | Toggle + Get All |
| `category` | String or null | اسم التصنيف | Toggle + Get All |
| `images` | Array | مصفوفة صور المنتج | **Get All only** |

### Images Inside Product

| Field | Type | Description |
| :-------------- | :-------- | :------------------------------------------ |
| `id` | Number | معرّف الصورة |
| `url` | String | رابط الصورة الكامل (يُحوَّل عبر `StorageService.resolveUrl()`) |
| `mobileUrl`    | String or null  | رابط صورة الموبايل (يُحوَّل عبر `StorageService.resolveUrl()`) |
| `thumbnailUrl` | String or null  | رابط الصورة المصغرة (يُحوَّل عبر `StorageService.resolveUrl()`) |
| `isMain` | Boolean | هل هي الصورة الرئيسية |

> **ملاحظة:** يتم تحويل روابط الصور باستخدام `StorageService.resolveUrl()` لضمان الحصول على الروابط الكاملة.

### Response (Empty Favorites - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "products": []
    }
  ],
  "pagination": {
    "total": 0,
    "page": 1,
    "limit": 10,
    "totalPages": 0,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "timestamp": "2026-06-12T10:00:00.000Z",
  "path": "/api/v1/favorites"
}
```

---

## Error Codes

| Error Code | Description |
| :--------- | :---------- |
| 400 | Bad Request — بيانات الإدخال غير صالحة (مثل `products` تحتوي على نصوص بدلاً من أرقام) |
| 404 | Not Found — لم يُعثر على المنتج المطلوب (رسالة: `Product with ID {id} not found`) |

> **ملاحظة:** صيغة الخطأ في جميع الحالات: `{ statusCode, message, error }` (لا تحتوي على `data` أو `timestamp` أو `path`).

---

## Enums Reference

### FavoriteEntityType

| Value | Description |
| :------ | :---------------- |
| `PRODUCT` | منتج (النوع الوحيد المدعوم حالياً) |

الـ enum مُعرَّف في `src/common/enums/favorite-entity-type.enum.ts`:

```typescript
export enum FavoriteEntityType {
  PRODUCT = 'PRODUCT',
}
```

---

## ملاحظات تقنية

- **المتحكم:** `src/modules/favorites/favorites.controller.ts`
- **الخدمة:** `src/modules/favorites/favorites.service.ts`
- **DTO:** `src/modules/favorites/dto/toggle-favorite.dto.ts`

### تفاصيل التنفيذ:

- **الكيان:** `src/database/entities/favorite.entity.ts`
  - يدعم `PRODUCT` فقط حالياً
  - Unique constraint على `(userId, entityType, entityId)` لمنع التكرار
  - علاقة ManyToOne مع User

- **أنواع المدعومة:** `src/common/enums/favorite-entity-type.enum.ts`
  ```typescript
  export enum FavoriteEntityType {
    PRODUCT = 'PRODUCT', // المنتجات فقط حالياً
  }
  ```

### قيود حالية:

- **المنتجات فقط:** لا يدعم إضافة المطاعم أو العروض للمفضلات حالياً
- **Bulk Operations:** Toggle يدعم عمليات جماعية فقط (لا يوجد إضافة/حذف فردي)
- **Pagination:** مدعوم في جلب المفضلات (يتم الترقيد in-memory باستخدام `.slice()`)
- **الصور:** غير متوفرة في استجابة Toggle، فقط في Get All
