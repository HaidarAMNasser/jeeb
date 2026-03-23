# Cart API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة

نظام إدارة سلة التسوق (Cart) يوفر واجهة API بسيطة لإدارة محتويات سلة العميل.

### المميزات الرئيسية:

- **سلة واحدة لكل عميل**: كل عميل لديه سلة واحدة فقط
- **منتجات وعروض**: إمكانية إضافة منتجات وعروض للسلة
- **مطعم واحد**: جميع العناصر يجب أن تكون من نفس المطعم
- **لا يوجد مخزون**: لا يتم حجز المنتجات أو التحقق من المخزون
- **لا يوجد ربط مع Orders**: النظام مستقل تماماً

---

## Base URL

```
http://localhost:3000/api/v1
```

---

## Authentication

جميع الـ endpoints تتطلب JWT token في الـ header:

```
Authorization: Bearer <access_token>
```

---

## API Endpoints

### 1. جلب السلة الحالية

جلب محتويات السلة الحالية للعميل.

**URL:** `/cart`
**Method:** `GET`

#### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "customer": {
      "id": 52,
      "firstName": "أحمد",
      "lastName": "محمد",
      "phone": "+963912345678"
    },
    "merchant": {
      "id": 100,
      "restaurantName": "مطعم الشاورما",
      "phone": "+963911111111",
      "address": "دمشق"
    },
    "items": [
      {
        "id": 1,
        "product": {
          "id": 10,
          "name": "شاورما دجاج",
          "shortDescription": "شاورما دجاج لذيذة",
          "description": "شاورما دجاج طازجة مع الصوص الخاص",
          "personCount": 1,
          "price": 7500,
          "discount": 10,
          "discountType": "PERCENTAGE",
          "isAvailable": true,
          "hasStock": true,
          "stockQuantity": 50,
          "images": [
            { "id": 1, "url": "https://example.com/image.jpg", "isMain": true }
          ]
        },
        "quantity": 2,
        "unitPrice": 7500,
        "totalPrice": 15000,
        "createdAt": "2026-03-22T10:00:00.000Z"
      }
    ],
    "offers": [
      {
        "id": 1,
        "offer": {
          "id": 5,
          "name": "وجبة كاملة",
          "description": "وجبة كاملة تشمل برجر وعصير",
          "discountType": "PERCENTAGE",
          "discountValue": 10,
          "isActive": true,
          "products": [
            {
              "id": 1,
              "name": "برجر",
              "price": 5000,
              "shortDescription": "برجر لحم طازج",
              "image": "https://example.com/burger.jpg"
            },
            {
              "id": 2,
              "name": "عصير",
              "price": 2000,
              "shortDescription": "عصير برتقال طازج",
              "image": "https://example.com/juice.jpg"
            }
          ]
        },
        "quantity": 1,
        "subtotal": 7000,
        "discount": 700,
        "createdAt": "2026-03-22T10:05:00.000Z"
      }
    ],
    "summary": {
      "itemsSubtotal": 15000,
      "offersSubtotal": 7000,
      "totalSubtotal": 22000,
      "totalDiscount": 700,
      "finalTotal": 21300,
      "platformCommission": 2130,
      "merchantRevenue": 19170
    }
  }
}
```

#### Response (السلة فارغة - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Cart is empty",
  "data": null
}
```

---

### 2. إنشاء/استبدال السلة

إنشاء سلة جديدة أو استبدال السلة الحالية بالكامل.

**URL:** `/cart`
**Method:** `POST`

#### Payload (Request Body)

| الحقل               | النوع  | مطلوب  | الوصف          |
| ------------------- | ------ | ------ | -------------- |
| `items`             | array  | **لا** | قائمة المنتجات |
| `items[].productId` | number | نعم    | معرف المنتج    |
| `items[].quantity`  | number | نعم    | الكمية (≥ 1)   |
| `offers`            | array  | **لا** | قائمة العروض   |
| `offers[].offerId`  | number | نعم    | معرف العرض     |
| `offers[].quantity` | number | نعم    | الكمية (≥ 1)   |

> **ملاحظة:** يجب توفير `items` أو `offers` أو كليهما.

#### مثال - إنشاء سلة:

```json
{
  "items": [
    { "productId": 10, "quantity": 2 },
    { "productId": 15, "quantity": 1 }
  ],
  "offers": [{ "offerId": 5, "quantity": 1 }]
}
```

#### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": { ... }
}
```

#### Response (Error - منتج من مطعم مختلف - 400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "All items must be from the same merchant",
  "error": "Bad Request"
}
```

#### Response (Error - منتج غير موجود - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Product with id 99 not found",
  "error": "Not Found"
}
```

---

### 3. تعديل السلة

تعديل محتويات السلة (إضافة/تعديل/حذف).

**URL:** `/cart`
**Method:** `PATCH`

#### Payload (Request Body)

```json
{
  "add": {
    "items": [{ "productId": 20, "quantity": 1 }],
    "offers": [{ "offerId": 8, "quantity": 2 }]
  },
  "update": {
    "items": [{ "productId": 10, "quantity": 5 }]
  },
  "remove": {
    "items": [15],
    "offers": [5]
  }
}
```

| الحقل    | الوصف                               |
| -------- | ----------------------------------- |
| `add`    | إضافة عناصر جديدة للسلة             |
| `update` | تعديل كميات عناصر موجودة            |
| `remove` | حذف عناصر من السلة (بمعرّفاتها فقط) |

#### مثال - إضافة منتجات:

```json
{
  "add": {
    "items": [{ "productId": 25, "quantity": 3 }]
  }
}
```

#### مثال - تعديل كميات:

```json
{
  "update": {
    "items": [{ "productId": 10, "quantity": 10 }]
  }
}
```

#### مثال - حذف منتجات:

```json
{
  "remove": {
    "items": [10, 15],
    "offers": [5]
  }
}
```

#### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": { ... }
}
```

#### Response (Error - سلة غير موجودة - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Cart not found",
  "error": "Not Found"
}
```

---

### 4. تفريغ السلة

حذف جميع محتويات السلة.

**URL:** `/cart`
**Method:** `DELETE`

#### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Cart cleared successfully",
  "data": null
}
```

---

## منطق العمل

### 1. مطعم واحد فقط

جميع المنتجات والعروض في السلة يجب أن تكون من نفس المطعم.

```
عند إضافة أي عنصر:
1. جلب merchantId للمنتج/العرض
2. إذا كانت السلة فارغة → تعيين merchantId
3. إذا كان merchantId مختلف → Error
```

### 2. رسائل الخطأ

| الحالة                  | الرسالة                                           |
| ----------------------- | ------------------------------------------------- |
| إضافة من مطعم مختلف     | `All items must be from the same merchant`        |
| منتج غير موجود          | `Product with id {id} not found`                  |
| عرض غير موجود           | `Offer with id {id} not found`                    |
| منتج غير متوفر          | `Product {name} is not available`                 |
| عرض غير نشط             | `Offer {name} is not active`                      |
| منتج غير موجود في العرض | `Product {name} in offer {name} is not available` |

### 3. الحسابات

```
itemsSubtotal = مجموع(product.price × quantity) للمنتجات

offersSubtotal = مجموع(سعر منتجات العرض × الكمية المطلوبة)

totalDiscount = خصم المنتجات + خصم العروض

finalTotal = (itemsSubtotal + offersSubtotal) - totalDiscount

platformCommission = finalTotal × 10%
merchantRevenue = finalTotal - platformCommission
```

---

## ملاحظات مهمة

1. **لا يوجد ربط مع Orders**: النظام مستقل تماماً عن نظام الطلبات
2. **لا يوجد مخزون**: لا يتم التحقق من المخزون
3. **لا يوجد تفريغ تلقائي**: السلة لا تُفرغ تلقائياً
4. **سلة واحدة**: كل عميل لديه سلة واحدة فقط

---

## أمثلة curl

### جلب السلة:

```bash
curl -X GET http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>"
```

### إنشاء سلة:

```bash
curl -X POST http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      { "productId": 10, "quantity": 2 }
    ],
    "offers": [
      { "offerId": 5, "quantity": 1 }
    ]
  }'
```

### إضافة للسلة:

```bash
curl -X PATCH http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "add": {
      "items": [{ "productId": 20, "quantity": 1 }]
    }
  }'
```

### حذف من السلة:

```bash
curl -X PATCH http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "remove": {
      "items": [10]
    }
  }'
```

### تفريغ السلة:

```bash
curl -X DELETE http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>"
```
