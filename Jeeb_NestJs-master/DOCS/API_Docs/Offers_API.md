# Offers API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## 1. Create Offer

Create a new offer.

- **URL:** `/offers`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Roles:** `MERCHANT`, `ADMIN`

### Payload (Request Body)

| Field           | Type          | Required | Description                                   |
| --------------- | ------------- | -------- | --------------------------------------------- |
| `name`          | string        | Yes      | اسم العرض                                     |
| `description`   | string        | No       | وصف العرض                                     |
| `discountType`  | string (Enum) | Yes      | نوع الخصم (`PERCENTAGE` أو `FIXED`)           |
| `discountValue` | number        | Yes      | قيمة الخصم (أكبر أو تساوي 0)                  |
| `startDate`     | date string   | No       | تاريخ بدء العرض (YYYY-MM-DDTHH:mm:ss.sssZ)    |
| `endDate`       | date string   | No       | تاريخ انتهاء العرض (YYYY-MM-DDTHH:mm:ss.sssZ) |
| `isActive`      | boolean       | No       | حالة تفعيل العرض                              |
| `products`      | array[object] | Yes\*    | مصفوفة تحتوي على منتجات العرض (1 على الأقل)   |
| `productIds`    | array[number] | Yes\*    | مصفوفة بمعرّفات المنتجات (صيغة قديمة/بديلة)   |

> **ملاحظة:** يجب توفير إما `products` أو `productIds`. الصيغة `products` هي المفضلة.

### Products Array Structure

| Field       | Type    | Required | Description                    |
| ----------- | ------- | -------- | ------------------------------ |
| `productId` | number  | Yes      | معرّف المنتج                   |
| `quantity`  | number  | No       | الكمية (الافتراضي: 1)          |
| `isActive`  | boolean | No       | حالة التفعيل (الافتراضي: true) |

### Request Example

```json
{
  "name": "عرض الصيف الخاص",
  "description": "خصم كبير على المنتجات المختارة",
  "discountType": "PERCENTAGE",
  "discountValue": 25,
  "startDate": "2024-06-01T00:00:00.000Z",
  "endDate": "2024-06-30T23:59:59.000Z",
  "isActive": true,
  "products": [
    { "productId": 1, "quantity": 2 },
    { "productId": 2, "quantity": 1 },
    { "productId": 3 }
  ]
}
```

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "عرض الصيف الخاص",
    "description": "خصم كبير على المنتجات المختارة",
    "discountType": "PERCENTAGE",
    "discountValue": 25,
    "startDate": "2024-06-01T00:00:00.000Z",
    "endDate": "2024-06-30T23:59:59.000Z",
    "isActive": true,
    "merchantId": 2,
    "images": [],
    "offerProducts": [
      {
        "id": 1,
        "offerId": 1,
        "productId": 1,
        "quantity": 2,
        "isActive": true,
        "product": {
          "id": 1,
          "name": "وجبة برغر",
          "price": 5000,
          "commissionRate": 0,
          "commissionAmount": 0,
          "offerQuantity": 2,
          "finalPrice": 10500,
          "images": [
            {
              "id": 10,
              "entityType": "PRODUCT",
              "entityId": 1,
              "url": "https://example.com/burger.webp",
              "mobileUrl": "https://example.com/burger_mobile.webp",
              "thumbnailUrl": "https://example.com/burger_thumb.webp",
              "isMain": true,
              "displayOrder": 0,
              "createdAt": "2024-01-01T10:00:00.000Z",
              "updatedAt": "2024-01-01T10:00:00.000Z"
            }
          ]
        },
        "createdAt": "2024-01-01T10:00:00.000Z",
        "updatedAt": "2024-01-01T10:00:00.000Z"
      }
    ],
    "totalQuantity": 2,
    "subtotal": 10500,
    "productDiscountTotal": 2625,
    "totalPrice": 7875,
    "merchant": {
      "id": 2,
      "firstName": "محمد",
      "lastName": "أحمد"
    }
  },
  "timestamp": "2024-01-01T10:00:00.000Z",
  "path": "/api/v1/offers"
}
```

---

## 2. Get All Offers

Retrieve a paginated list of offers.

- **URL:** `/offers`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <access_token>`

### Query Parameters

| Parameter    | Type    | Required | Description                                                    |
| ------------ | ------- | -------- | -------------------------------------------------------------- |
| `page`       | number  | No       | رقم الصفحة (الافتراضي: 1)                                      |
| `limit`      | number  | No       | عدد العناصر في الصفحة (الافتراضي: 10)                          |
| `search`     | string  | No       | البحث في اسم العرض (يدعم العربية والإنجليزية)                  |
| `isActive`   | boolean | No       | الفلترة حسب حالة العرض (`true` أو `false`)                     |
| `merchantId` | number  | No       | الفلترة حسب رقم التاجر (المدير يستخدمها لفلترة عروض تاجر محدد) |

### Request Example

```bash
curl -X GET "http://localhost:3000/api/v1/offers?page=1&limit=10&isActive=true" \
  -H "Authorization: Bearer <access_token>"
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 1,
      "name": "عرض الصيف الخاص",
      "description": "خصم كبير على المنتجات المختارة",
      "discountType": "PERCENTAGE",
      "discountValue": 25,
      "startDate": "2024-06-01T00:00:00.000Z",
      "endDate": "2024-06-30T23:59:59.000Z",
      "isActive": true,
      "merchantId": 2,
      "images": [],
      "offerProducts": [
        {
          "id": 1,
          "offerId": 1,
          "productId": 1,
          "quantity": 2,
          "isActive": true,
          "product": {
            "id": 1,
            "name": "وجبة برغر",
            "price": 5000,
            "commissionRate": 0,
            "commissionAmount": 0,
            "offerQuantity": 2,
            "finalPrice": 10500,
            "images": [...]
          }
        }
      ],
      "totalQuantity": 2,
      "subtotal": 10500,
      "productDiscountTotal": 2625,
      "totalPrice": 7875,
      "merchant": {
        "id": 2,
        "firstName": "محمد",
        "lastName": "أحمد"
      }
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
  "timestamp": "2024-01-01T10:00:00.000Z",
  "path": "/api/v1/offers"
}
```

---

## 3. Get Offer by ID

Retrieve a specific offer by integer ID.

- **URL:** `/offers/:id`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <access_token>`

### Response (Success - 200 OK)

Returns the Offer object (similar to the data object in Create response).

### Response (Error - 404 Not Found)

```json
{
  "statusCode": 404,
  "message": "Offer with ID 999 not found",
  "data": {},
  "timestamp": "2024-01-01T10:00:00.000Z",
  "path": "/api/v1/offers/999"
}
```

---

## 4. Update Offer

Update details of an existing offer, add or remove products.

- **URL:** `/offers/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Roles:** `MERCHANT` (Only for their own offers), `ADMIN`

### Payload (Request Body)

| Field              | Type          | Required | Description                                         |
| ------------------ | ------------- | -------- | --------------------------------------------------- |
| `name`             | string        | No       | اسم العرض                                           |
| `description`      | string        | No       | وصف العرض                                           |
| `discountType`     | string (Enum) | No       | نوع الخصم (`PERCENTAGE` أو `FIXED`)                 |
| `discountValue`    | number        | No       | قيمة الخصم                                          |
| `startDate`        | date string   | No       | تاريخ بدء العرض                                     |
| `endDate`          | date string   | No       | تاريخ انتهاء العرض                                  |
| `isActive`         | boolean       | No       | حالة تفعيل العرض                                    |
| `products`         | array[object] | No       | لإضافة منتجات جديدة أو تحديث كمية المنتجات الموجودة |
| `removeProductIds` | array[number] | No       | مصفوفة بمعرّفات المنتجات المراد إزالتها من العرض    |

### Products Array Structure (for add/update)

| Field       | Type    | Required | Description                         |
| ----------- | ------- | -------- | ----------------------------------- |
| `productId` | number  | Yes      | معرّف المنتج                        |
| `quantity`  | number  | No       | الكمية الجديدة (للإضافة أو التحديث) |
| `isActive`  | boolean | No       | حالة التفعيل                        |

### Request Examples

**تعديل بيانات العرض فقط:**

```json
{
  "isActive": false,
  "discountValue": 30
}
```

**إضافة منتجات جديدة إلى العرض:**

```json
{
  "products": [{ "productId": 5, "quantity": 3 }, { "productId": 6 }]
}
```

**إزالة منتجات من العرض:**

```json
{
  "removeProductIds": [1, 2, 3]
}
```

**تعديل كمية منتج موجود في العرض:**

```json
{
  "products": [{ "productId": 5, "quantity": 10 }]
}
```

**دمج العمليات (إضافة + إزالة + تعديل + تحديث البيانات):**

```json
{
  "name": "عرض جديد",
  "discountValue": 20,
  "products": [{ "productId": 5, "quantity": 3 }, { "productId": 6 }],
  "removeProductIds": [1, 2]
}
```

### Response (Success - 200 OK)

Returns the updated Offer object (similar to the data object in Create response).

### Response (Error - 403 Forbidden)

If a Merchant tries to update an offer they do not own:

```json
{
  "statusCode": 403,
  "message": "You do not own this offer",
  "data": {},
  "timestamp": "2024-01-01T10:00:00.000Z",
  "path": "/api/v1/offers/1"
}
```

---

## 5. Delete Offer

Delete a specific offer by ID.

- **URL:** `/offers/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Authorization: Bearer <access_token>`
- **Roles:** `MERCHANT` (Only for their own offers), `ADMIN`

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2024-01-01T10:00:00.000Z",
  "path": "/api/v1/offers/1"
}
```

---

## ملاحظات حسابية الأسعار

### ترتيب الحساب لكل منتج

```
1. commissionAmount = 0 (معطّل)
2. productDiscountValue = originalPrice × productDiscount / 100 (PERCENTAGE) أو المبلغ الثابت
3. priceAfterProductDiscount = originalPrice - productDiscountValue
4. finalPrice = priceAfterProductDiscount × quantity
```

### ترتيب الحساب على مستوى العرض

```
1. subtotal = مجموع كل finalPrice من المنتجات
2. productDiscountTotal = تطبيق خصم العرض على subtotal:
   - إذا PERCENTAGE: subtotal × discountValue / 100
   - إذا FIXED: discountValue
3. totalPrice = subtotal - productDiscountTotal
```

### مثال حسابي كامل

```
منتج 1: سعر = 5000، خصم منتج = 10%، كمية = 2
منتج 2: سعر = 3000، خصم منتج = 0%، كمية = 1
خصم العرض: PERCENTAGE = 25%

=== حساب كل منتج ===

المنتج 1:
  commissionAmount = 0 (معطّل)
  productDiscountValue = 5000 × 10% = 500
  priceAfterProductDiscount = 5000 - 500 = 4500
  finalPrice = 4500 × 2 = 9000

المنتج 2:
  commissionAmount = 0 (معطّل)
  productDiscountValue = 0 (لا يوجد خصم)
  priceAfterProductDiscount = 3000 - 0 = 3000
  finalPrice = 3000 × 1 = 3000

=== الحسابات الإجمالية ===

subtotal = 9000 + 3000 = 12000
productDiscountTotal = 12000 × 25% = 3000
totalPrice = 12000 - 3000 = 9000
```

---

## ملخص الكائنات المسترجعة

### merchant (مبسّط)

```json
{
  "id": 2,
  "firstName": "محمد",
  "lastName": "أحمد"
}
```

### product inside offerProducts (مبسّط)

```json
{
  "id": 1,
  "name": "وجبة برغر",
  "price": 5000,
  "commissionRate": 0,
  "commissionAmount": 0,
  "offerQuantity": 2,
  "finalPrice": 9500,
  "images": [
    {
      "id": 10,
      "entityType": "PRODUCT",
      "entityId": 1,
      "url": "https://example.com/burger.webp",
      "mobileUrl": "https://example.com/burger_mobile.webp",
      "thumbnailUrl": "https://example.com/burger_thumb.webp",
      "isMain": true,
      "displayOrder": 0,
      "createdAt": "2024-01-01T10:00:00.000Z",
      "updatedAt": "2024-01-01T10:00:00.000Z"
    }
  ]
}
```

### images inside product

| Field          | Type    | Description                 |
| -------------- | ------- | --------------------------- |
| `id`           | number  | معرّف الصورة                |
| `entityType`   | string  | نوع الكيان (PRODUCT, OFFER) |
| `entityId`     | number  | معرّف الكيان                |
| `url`          | string  | رابط الصورة الأصلي          |
| `mobileUrl`    | string  | رابط الصورة للموبايل        |
| `thumbnailUrl` | string  | رابط الصورة المصغرة         |
| `isMain`       | boolean | هل هي الصورة الرئيسية       |
| `displayOrder` | number  | ترتيب العرض                 |
| `createdAt`    | date    | تاريخ الإنشاء               |
| `updatedAt`    | date    | تاريخ التحديث               |
