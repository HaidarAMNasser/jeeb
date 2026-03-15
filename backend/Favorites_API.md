# Favorites API Documentation

Base URL: `https://api.jeeb2.com/api/v1`

## نظرة عامة

- المفضّلة متاحة فقط للمستخدم من نوع CUSTOMER.
- الأنواع المدعومة: منتجات فقط (PRODUCTS).
- كل العمليات محمية بالمصادقة.

## 1. Toggle Favorites (Bulk)

- **URL:** `/favorites/toggle`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`

### Payload (Request Body)

```json
{
  "products": [10, 11, 12]
}
```

- قائمة من معرفات المنتجات المراد إضافتها/حذفها من المفضلات.
- إذا كان المنتج في المفضلات يتم حذفه، وإذا لم يكن يتم إضافته.

### Response (Success - 200 OK)

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
  "timestamp": "2026-02-24T10:00:00.000Z",
  "path": "/api/v1/favorites/toggle"
}
```

**ملاحظة:** يتم إرجاع المنتجات التي تمت إضافتها فقط (المنتجات الجديدة في المفضلات).

### Response (Error - 404 Not Found)

إذا لم يُعثر على أحد المنتجات:

```json
{
  "statusCode": 404,
  "message": "Product with ID 999 not found",
  "data": {},
  "timestamp": "2026-02-24T10:00:00.000Z",
  "path": "/api/v1/favorites/toggle"
}
```

---

## 2. Get All Favorites (Paginated)

- **URL:** `/favorites`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <access_token>`
- **Query Parameters:**
  - `page` (optional): رقم الصفحة، افتراضي 1
  - `limit` (optional): عدد العناصر في الصفحة، افتراضي 10

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
          "category": "وجبات سريعة"
        },
        {
          "id": 11,
          "name": "Chicken Sandwich",
          "price": 899,
          "category": "وجبات سريعة"
        },
        {
          "id": 12,
          "name": "French Fries",
          "price": 299,
          "category": "وجبات جانبية"
        }
      ]
    }
  ],
  "total": 3,
  "page": 1,
  "limit": 10,
  "timestamp": "2026-02-24T10:00:00.000Z",
  "path": "/api/v1/favorites"
}
```

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
  "total": 0,
  "page": 1,
  "limit": 10,
  "timestamp": "2026-02-24T10:00:00.000Z",
  "path": "/api/v1/favorites"
}
```

---

## ملاحظات تقنية

- **المتحكم:** [FavoritesController](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/favorites/favorites.controller.ts)
- **الخدمة:** [FavoritesService](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/favorites/favorites.service.ts)
- **DTO:** [ToggleFavoriteDto](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/favorites/dto/toggle-favorite.dto.ts)

### تفاصيل التنفيذ:

- **الكيان:** [Favorite Entity](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/database/entities/favorite.entity.ts)
  - يدعم `PRODUCT` نوع فقط حالياً
  - Unique constraint على `(userId, entityType, entityId)` لمنع التكرار
  - علاقة ManyToOne مع User

- **أنواع المدعومة:** [FavoriteEntityType](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/common/enums/favorite-entity-type.enum.ts)
  ```typescript
  export enum FavoriteEntityType {
    PRODUCT = 'PRODUCT'  // المنتجات فقط حالياً
  }
  ```

### قيود حالية:

- **المنتجات فقط:** لا يدعم إضافة المطاعم للمفضلات حالياً
- **Bulk Operations:** Toggle يدعم عمليات جماعية فقط
- **Pagination:** مدعوم في جلب المفضلات
