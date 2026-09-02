# Cart API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## Overview

Cart management system. Each customer has exactly one cart. All items must be from the same merchant.

### Key Features

- **One cart per customer**: Each customer has a single cart
- **Products and offers**: Add both products and offers to the cart
- **Single merchant**: All items must belong to the same merchant
- **Full details**: Product images, availability, stock info, discounts
- **No order linkage**: Cart is completely independent from orders

---

## Authentication

All endpoints require JWT token in the header:

```
Authorization: Bearer <access_token>
```

**Guest access**: POST, PATCH, and DELETE endpoints allow guest users (via `@AllowGuest()`). GET requires a registered user account (guest users cannot GET the cart).

---

## 1. Get Cart

Retrieve the current cart with all items, offers, and summary.

- **URL:** `/cart`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`
- **Auth:** Required (registered user only, no guest access)

### Response (200 OK) — Cart with Items

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
            {
              "id": 1,
              "url": "https://storage.example.com/images/shawarma.jpg",
              "mobileUrl": "https://storage.example.com/mobile/shawarma.jpg",
              "thumbnailUrl": "https://storage.example.com/thumb/shawarma.jpg",
              "isMain": true
            },
            {
              "id": 2,
              "url": "https://storage.example.com/images/shawarma2.jpg",
              "mobileUrl": "https://storage.example.com/mobile/shawarma2.jpg",
              "thumbnailUrl": "https://storage.example.com/thumb/shawarma2.jpg",
              "isMain": false
            }
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
          "images": [
            {
              "id": 10,
              "url": "https://storage.example.com/images/combo-offer.jpg",
              "mobileUrl": "https://storage.example.com/mobile/combo-offer.jpg",
              "thumbnailUrl": "https://storage.example.com/thumb/combo-offer.jpg",
              "isMain": true
            }
          ],
          "products": [
            {
              "id": 1,
              "name": "برجر",
              "price": 5000,
              "shortDescription": "برجر لحم طازج",
              "discount": 5,
              "discountType": "PERCENTAGE",
              "isAvailable": true,
              "hasStock": true,
              "stockQuantity": 30,
              "images": [
                {
                  "id": 3,
                  "url": "https://storage.example.com/images/burger.jpg",
                  "mobileUrl": "https://storage.example.com/mobile/burger.jpg",
                  "thumbnailUrl": "https://storage.example.com/thumb/burger.jpg",
                  "isMain": true
                }
              ]
            },
            {
              "id": 2,
              "name": "عصير",
              "price": 2000,
              "shortDescription": "عصير برتقال طازج",
              "discount": null,
              "discountType": null,
              "isAvailable": true,
              "hasStock": false,
              "stockQuantity": null,
              "images": []
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
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/cart"
}
```

### Response (200 OK) — Empty Cart

When no cart exists for the customer:

```json
{
  "statusCode": 200,
  "message": "Cart is empty",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/cart"
}
```

---

## 2. Create / Replace Cart

Create a new cart or **replace** the existing cart entirely. If a cart already exists, all existing items and offers are removed before adding the new ones.

- **URL:** `/cart`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (guest users allowed)

### Payload

| Field                  | Type   | Required | Description              |
| ---------------------- | ------ | -------- | ------------------------ |
| `items`                | array  | No       | List of products (at least one of `items` or `offers` required) |
| `items[].productId`    | number | Yes*     | Product ID (≥ 1)         |
| `items[].quantity`     | number | Yes*     | Quantity (≥ 1)           |
| `offers`               | array  | No       | List of offers           |
| `offers[].offerId`     | number | Yes*     | Offer ID (≥ 1)           |
| `offers[].quantity`    | number | Yes*     | Quantity (≥ 1)           |

> **Validation:** `{ transform: true, whitelist: true }` — extra fields are silently stripped. All IDs and quantities must be ≥ 1.

```json
{
  "items": [
    { "productId": 10, "quantity": 2 },
    { "productId": 15, "quantity": 1 }
  ],
  "offers": [
    { "offerId": 5, "quantity": 1 }
  ]
}
```

### Response (201 Created)

Returns the full cart structure (same as GET /cart).

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "customer": { ... },
    "merchant": { ... },
    "items": [ ... ],
    "offers": [ ... ],
    "summary": { ... }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/cart"
}
```

### Response (400 Bad Request) — Different Merchant

```json
{
  "statusCode": 400,
  "message": "All items must be from the same merchant",
  "error": "Bad Request"
}
```

### Response (404 Not Found) — Product Not Found

```json
{
  "statusCode": 404,
  "message": "Product with id 99 not found",
  "error": "Not Found"
}
```

### Response (400 Bad Request) — Product Not Available

```json
{
  "statusCode": 400,
  "message": "Product شاورما دجاج is not available",
  "error": "Bad Request"
}
```

### Response (404 Not Found) — Offer Not Found

```json
{
  "statusCode": 404,
  "message": "Offer with id 99 not found",
  "error": "Not Found"
}
```

---

## 3. Update Cart

Modify the existing cart using add, update, and remove operations.

- **URL:** `/cart`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (guest users allowed)

### Payload

| Field                  | Type   | Description                                |
| ---------------------- | ------ | ------------------------------------------ |
| `add`                  | object | Add new items/offers to the cart           |
| `add.items`            | array  | Products to add (`productId`, `quantity`)  |
| `add.offers`           | array  | Offers to add (`offerId`, `quantity`)      |
| `update`               | object | Update quantities of existing items/offers |
| `update.items`         | array  | Products to update (`productId`, `quantity`) |
| `update.offers`        | array  | Offers to update (`offerId`, `quantity`)   |
| `remove`               | object | Remove items/offers by their ID            |
| `remove.items`         | array  | Array of product IDs to remove             |
| `remove.offers`        | array  | Array of offer IDs to remove               |

> **Behavior:** When adding an item/offer that already exists in the cart, the quantities are **merged** (existing quantity + added quantity), not replaced.

#### Example — Add Items

```json
{
  "add": {
    "items": [{ "productId": 20, "quantity": 1 }],
    "offers": [{ "offerId": 8, "quantity": 2 }]
  }
}
```

#### Example — Update Quantities

```json
{
  "update": {
    "items": [{ "productId": 10, "quantity": 5 }]
  }
}
```

#### Example — Remove Items

```json
{
  "remove": {
    "items": [10, 15],
    "offers": [5]
  }
}
```

#### Example — All Operations Combined

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

### Response (200 OK)

Returns the full cart structure (same as GET /cart).

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "customer": { ... },
    "merchant": { ... },
    "items": [ ... ],
    "offers": [ ... ],
    "summary": { ... }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/cart"
}
```

### Response (404 Not Found) — Cart Does Not Exist

```json
{
  "statusCode": 404,
  "message": "Cart not found",
  "error": "Not Found"
}
```

---

## 4. Clear Cart

Delete the entire cart and all its contents.

- **URL:** `/cart`
- **Method:** `DELETE`
- **Headers:** `Authorization: Bearer <access_token>`
- **Auth:** Required (guest users allowed)

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Cart cleared successfully",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/cart"
}
```

### Response (404 Not Found) — Cart Does Not Exist

```json
{
  "statusCode": 404,
  "message": "Cart not found",
  "error": "Not Found"
}
```

---

## Error Messages

| Condition                                        | Message                                                    |
| ------------------------------------------------ | ---------------------------------------------------------- |
| Add from different merchant                      | `All items must be from the same merchant`                 |
| Product not found                                | `Product with id {id} not found`                           |
| Offer not found                                  | `Offer with id {id} not found`                             |
| Product not available                            | `Product {name} is not available`                          |
| Offer not active                                 | `Offer {name} is not active`                               |
| Product in offer not available                   | `Product {name} in offer {name} is not available`          |
| Cart not found (on PATCH/DELETE)                 | `Cart not found`                                           |

---

## Business Logic

### 1. Single Merchant Rule

All items and offers must belong to the same merchant.

```
When adding any item:
1. Get merchantId of the product/offer
2. If cart is empty → set merchantId
3. If merchantId differs from existing → error
```

### 2. Quantity Merging on Add

When adding an item/offer that already exists in the cart, the quantities are **merged** (existing + new).

### 3. POST Replaces Entire Cart

`POST /cart` **replaces** the entire cart — existing items/offers are deleted, then the new ones are inserted. Use `PATCH /cart` for incremental updates.

### 4. Calculations

```
itemsSubtotal = Σ(product.price × quantity)  for direct products

offersSubtotal = Σ(offer product prices × quantity) for offers

totalDiscount = product discounts + offer discounts

finalTotal = (itemsSubtotal + offersSubtotal) - totalDiscount

platformCommission = finalTotal × 10%
merchantRevenue = finalTotal - platformCommission
```

### 5. Offer Discount Calculation

```
If discountType = PERCENTAGE:
  discount = (offersSubtotal × discountValue) / 100

If discountType = FIXED:
  discount = min(discountValue, offersSubtotal)
```

---

## Response Structures

### Product Info (in items)

| Field              | Type    | Description                      |
| ------------------ | ------- | -------------------------------- |
| `id`               | number  | Product ID                       |
| `name`             | string  | Product name                     |
| `shortDescription` | string  | Short description                |
| `description`      | string  | Full description                 |
| `personCount`      | number  | Number of persons                |
| `price`            | number  | Original price                   |
| `discount`         | number  | Discount value                   |
| `discountType`     | string  | `PERCENTAGE` or `FIXED`          |
| `isAvailable`      | boolean | Is the product available         |
| `hasStock`         | boolean | Does the product track stock     |
| `stockQuantity`    | number  | Current stock quantity           |
| `images`           | array   | Product images                   |

### Offer Info (in offers)

| Field           | Type    | Description                      |
| --------------- | ------- | -------------------------------- |
| `id`            | number  | Offer ID                         |
| `name`          | string  | Offer name                       |
| `description`   | string  | Offer description                |
| `discountType`  | string  | `PERCENTAGE` or `FIXED`          |
| `discountValue` | number  | Discount value                   |
| `isActive`      | boolean | Is the offer active              |
| `images`        | array   | Offer images                     |
| `products`      | array   | Products included in the offer   |

### Image Object

| Field          | Type    | Description             |
| -------------- | ------- | ----------------------- |
| `id`           | number  | Image ID                |
| `url`          | string  | Original image URL      |
| `mobileUrl`    | string  | Mobile-optimized URL    |
| `thumbnailUrl` | string  | Thumbnail URL           |
| `isMain`       | boolean | Is the main image       |

### Summary Object

| Field                | Type   | Description               |
| -------------------- | ------ | ------------------------- |
| `itemsSubtotal`      | number | Sum of all product prices |
| `offersSubtotal`     | number | Sum of all offer prices   |
| `totalSubtotal`      | number | itemsSubtotal + offersSubtotal |
| `totalDiscount`      | number | Total discount applied    |
| `finalTotal`         | number | Total after discount      |
| `platformCommission` | number | 10% platform fee          |
| `merchantRevenue`    | number | finalTotal - platformCommission |

---

## Notes

1. **No order linkage**: Cart is completely independent from orders
2. **No stock validation**: Stock info is informational only
3. **No auto-clear**: Cart is never automatically cleared
4. **One cart**: Each customer has exactly one cart
5. **Images**: Product and offer images are loaded automatically
6. **Currency**: All amounts are in the smallest unit (halalas/cents)
7. **Whitelist**: Extra fields in request body are silently stripped

---

## cURL Examples

### Get Cart

```bash
curl -X GET http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>"
```

### Create Cart

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

### Add to Cart

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

### Remove from Cart

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

### Clear Cart

```bash
curl -X DELETE http://localhost:3000/api/v1/cart \
  -H "Authorization: Bearer <token>"
```
