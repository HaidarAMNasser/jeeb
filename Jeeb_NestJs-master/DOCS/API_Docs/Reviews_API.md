# Reviews API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة ودور الصلاحيات

- **CUSTOMER (عميل):**
  - يمكنه إنشاء تقييمات للطلبات والمنتجات.
  - يمكنه تعديل/حذف تقييماته الخاصة فقط.
  - يمكنه عرض تقييماته الخاصة.

- **ADMIN:** يمتلك صلاحيات كاملة: عرض/تعديل/حذف أي تقييم.

- **MERCHANT (تاجر):**
  - يمكنه عرض التقييمات الخاصة بمنتجاته وطلبات مطعمه.
  - لا يمكنه تعديل أو حذف التقييمات.

جميع الـ endpoints محمية بـ AuthGuard و RolesGuard.

المسارات معرفة في [api-routes.constants.ts](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/common/constants/api-routes.constants.ts#L43-L49).

- **ORDER**: Review a delivered order (customer can only review their own delivered orders)
- **PRODUCT**: Review a product (customers can review any product, multiple reviews allowed)
- **MERCHANT**: Review a merchant directly (customers can review any merchant, one review per customer per merchant)

### User Roles & Permissions

| Role     | Create Review | View Own Reviews | Update Own Reviews | Delete Own Reviews | View All Reviews | Manage Reviews |
| -------- | ------------- | ---------------- | ------------------ | ------------------ | ---------------- | -------------- |
| Customer | ✅            | ✅               | ✅                 | ✅                 | ❌               | ❌             |
| Merchant | ❌            | ❌               | ❌                 | ❌                 | ✅ (own only)    | ❌             |
| Admin    | ❌            | ✅               | ✅                 | ✅                 | ✅               | ✅             |

---

## Customer Operations

### 1. Create Review (Order)

Create a review for a delivered order. Only customers can review their own delivered orders.

- **URL:** `/reviews`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <customer_token>`

### Payload (Request Body)

```json
{
  "entityType": "ORDER",
  "entityId": 1, // Order ID
  "rating": 5, // 1-5 stars
  "comment": "Great service and fast delivery!"
}
```

### Response (Success - 201 Created)

```json
{
  "entityType": "ORDER",
  "entityId": 1,
  "rating": 5,
  "comment": "Great service and fast delivery!",
  "reviewerId": 10,
  "id": 1,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-27T10:00:00.000Z"
}
```

### Response (Error - 400 Bad Request)

If order is not delivered:

```json
{
  "message": "Order must be delivered to leave a review",
  "error": "Bad Request",
  "statusCode": 400
}
```

If order doesn't belong to customer:

```json
{
  "message": "You can only review your own orders",
  "error": "Bad Request",
  "statusCode": 400
}
```

If review already exists for this order:

```json
{
  "message": "You have already reviewed this order",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

### 2. Create Review (Product)

Create a review for a product. Customers can review any product and can leave multiple reviews for the same product.

- **URL:** `/reviews`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <customer_token>`

### Payload (Request Body)

```json
{
  "entityType": "PRODUCT",
  "entityId": 10, // Product ID
  "rating": 4, // 1-5 stars
  "comment": "Delicious pizza, great taste!"
}
```

### Response (Success - 201 Created)

```json
{
  "entityType": "PRODUCT",
  "entityId": 10,
  "rating": 4,
  "comment": "Delicious pizza, great taste!",
  "reviewerId": 10,
  "id": 2,
  "createdAt": "2023-10-27T10:05:00.000Z",
  "updatedAt": "2023-10-27T10:05:00.000Z"
}
```

### Response (Error - 400 Bad Request)

If product doesn't exist:

```json
{
  "message": "Product not found",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

### 3. Create Review (Merchant)

Create a review for a merchant. Customers can review any merchant but are limited to one review per merchant.

- **URL:** `/reviews`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <customer_token>`

### Payload (Request Body)

```json
{
  "entityType": "MERCHANT",
  "entityId": 10, // Merchant (User) ID
  "rating": 5, // 1-5 stars
  "comment": "Great store, amazing support."
}
```

### Response (Success - 201 Created)

```json
{
  "entityType": "MERCHANT",
  "entityId": 10,
  "rating": 5,
  "comment": "Great store, amazing support.",
  "reviewerId": 10,
  "id": 3,
  "createdAt": "2023-10-27T10:05:00.000Z",
  "updatedAt": "2023-10-27T10:05:00.000Z"
}
```

### Response (Error - 400 Bad Request)

If merchant doesn't exist:

```json
{
  "message": "Merchant not found",
  "error": "Bad Request",
  "statusCode": 400
}
```

If review already exists for this merchant by the customer:

```json
{
  "message": "You have already reviewed this merchant",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

### 4. Get My Review

Get a specific review that belongs to the authenticated customer.

- **URL:** `/reviews/:id`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <customer_token>`

### Response (Success - 200 OK)

```json
{
  "id": 1,
  "rating": 5,
  "comment": "Great service!",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-27T10:00:00.000Z",
  "reviewer": {
    "id": 10,
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

### Response (Error - 404 Not Found)

If review doesn't exist:

```json
{
  "message": "Review not found",
  "error": "Not Found",
  "statusCode": 404
}
```

### Response (Error - 403 Forbidden)

If review doesn't belong to the customer:

```json
{
  "message": "You can only access your own reviews",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

### 5. Update My Review

Update a review that belongs to the authenticated customer.

- **URL:** `/reviews/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <customer_token>`

### Payload (Request Body)

All fields are optional.

```json
{
  "rating": 4,
  "comment": "Updated review - good but could be better"
}
```

### Response (Success - 200 OK)

```json
{
  "id": 1,
  "rating": 4,
  "comment": "Updated review - good but could be better",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-28T15:30:00.000Z"
}
```

### Response (Error - 403 Forbidden)

If review doesn't belong to the customer:

```json
{
  "message": "You can only update your own reviews",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

### 6. Delete My Review

Delete a review that belongs to the authenticated customer.

- **URL:** `/reviews/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Authorization: Bearer <customer_token>`

### Response (Success - 200 OK)

Returns the deleted review object.

```json
{
  "id": 1,
  "rating": 4,
  "comment": "Updated review - good but could be better",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-28T15:30:00.000Z"
}
```

### Response (Error - 403 Forbidden)

If review doesn't belong to the customer:

```json
{
  "message": "You can only delete your own reviews",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

## Public Operations

### 7. Get Public Reviews (Driver)

Get all reviews for a specific driver (from delivered orders) with pagination.

- **URL:** `/reviews/driver/:driverId`
- **Method:** `GET`
- **Query Parameters:**
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 10)

### Request Example

`GET /reviews/driver/1?page=1&limit=10`

### Response (Success - 200 OK)

```json
{
  "data": [
    {
      "id": 4,
      "rating": 5,
      "comment": "Fast delivery!",
      "entityType": "ORDER",
      "entityId": 200,
      "createdAt": "2023-10-26T13:00:00.000Z",
      "reviewer": {
        "id": 10,
        "firstName": "John",
        "lastName": "Doe"
      }
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 10,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

---

### 8. Get Product Reviews (Public)

Get all reviews for a specific product with pagination.

- **URL:** `/reviews/product/:productId`
- **Method:** `GET`
- **Query Parameters:**
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 10)

### Request Example

`GET /reviews/product/5?page=1&limit=10`

### Response (Success - 200 OK)

```json
{
  "data": [
    {
      "id": 2,
      "rating": 4,
      "comment": "Delicious pizza, great taste!",
      "entityType": "PRODUCT",
      "entityId": 5,
      "reviewerId": 10,
      "createdAt": "2023-10-27T10:05:00.000Z",
      "updatedAt": "2023-10-27T10:05:00.000Z",
      "reviewer": {
        "id": 10,
        "firstName": "John",
        "lastName": "Doe"
      }
    },
    {
      "id": 1,
      "rating": 5,
      "comment": "Amazing product!",
      "entityType": "PRODUCT",
      "entityId": 5,
      "reviewerId": 12,
      "createdAt": "2023-10-26T12:00:00.000Z",
      "updatedAt": "2023-10-26T12:00:00.000Z",
      "reviewer": {
        "id": 12,
        "firstName": "Jane",
        "lastName": "Smith"
      }
    }
  ],
  "total": 2,
  "page": 1,
  "limit": 10,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

### Response (Error - 404 Not Found)

If product doesn't exist:

```json
{
  "message": "Product not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

### 9. Get Public Reviews (Merchant)

Get all reviews for a specific merchant's products with pagination.

- **URL:** `/reviews/merchant/:merchantId`
- **Method:** `GET`
- **Query Parameters:**
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 10)

### Request Example

`GET /reviews/merchant/1?page=1&limit=10`

### Response (Success - 200 OK)

```json
{
  "data": [
    {
      "id": 4,
      "rating": 5,
      "comment": "Fast delivery!",
      "entityType": "PRODUCT",
      "entityId": 2,
      "createdAt": "2023-10-26T13:00:00.000Z",
      "reviewer": {
        "id": 10,
        "firstName": "John",
        "lastName": "Doe"
      }
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 10,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

---

## Admin/Merchant Operations

### 10. Get All Reviews (Paginated)

Get a paginated list of reviews.

- **Admin:** Can see all reviews in the system.
- **Merchant:** Can see only reviews for their restaurants and products.

- **URL:** `/reviews`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <token>` (Admin or Merchant token)
- **Query Parameters:**
  - `page`: Page number (default: 1)
  - `limit`: Items per page (default: 10)

### Request Example

`GET /reviews?page=1&limit=10`

### Response (Success - 200 OK)

```json
{
  "data": [
    {
      "id": 10,
      "rating": 5,
      "comment": "Excellent",
      "entityType": "PRODUCT",
      "entityId": 50,
      "createdAt": "2023-10-27T09:00:00.000Z",
      "reviewer": {
        "id": 5,
        "firstName": "Alice",
        "lastName": "Wonder"
      }
    }
  ],
  "total": 50,
  "page": 1,
  "limit": 10
}
```

### Response (Error - 401 Unauthorized)

If token is missing or invalid:

```json
{
  "message": "Unauthorized",
  "statusCode": 401
}
```

---

### 11. Get One Review (Admin/Merchant/Customer)

Get details of a specific review.

- **Admin:** Can access any review.
- **Merchant:** Can only access reviews related to their restaurants or products.
- **Customer:** Can only access their own reviews.

- **URL:** `/reviews/:id`
- **Method:** `GET`
- **Headers:**
  - `Authorization: Bearer <token>`

### Response (Success - 200 OK)

```json
{
  "id": 1,
  "rating": 5,
  "comment": "Great service!",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-27T10:00:00.000Z",
  "reviewer": {
    "id": 10,
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

### Response (Error - 403 Forbidden)

If merchant tries to access reviews not related to their restaurants/products:

```json
{
  "message": "You can only access reviews for your own restaurants and products",
  "error": "Forbidden",
  "statusCode": 403
}
```

---

### 12. Update Review (Admin/Customer)

Update any review.

- **Admin:** Can update any review (moderation purposes).
- **Customer:** Can only update their own reviews.

- **URL:** `/reviews/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <token>`

### Payload (Request Body)

All fields are optional.

```json
{
  "comment": "Updated by Admin due to policy violation",
  "rating": 3
}
```

### Response (Success - 200 OK)

```json
{
  "id": 1,
  "rating": 3,
  "comment": "Updated by Admin due to policy violation",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-28T10:00:00.000Z"
}
```

---

### 13. Delete Review (Admin/Customer)

Delete any review.

- **Admin:** Can delete any review (moderation purposes).
- **Customer:** Can only delete their own reviews.

- **URL:** `/reviews/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Authorization: Bearer <token>`

### Response (Success - 200 OK)

Returns the deleted review object.

```json
{
  "id": 1,
  "rating": 5,
  "comment": "Spam content",
  "entityType": "ORDER",
  "entityId": 1,
  "reviewerId": 10,
  "createdAt": "2023-10-27T10:00:00.000Z",
  "updatedAt": "2023-10-27T10:00:00.000Z"
}
```

---

## Error Codes Reference

| Status Code | Description  | Common Scenarios                                 |
| ----------- | ------------ | ------------------------------------------------ |
| 200         | OK           | Successful GET, PATCH, DELETE operations         |
| 201         | Created      | Successful POST operations                       |
| 400         | Bad Request  | Invalid input data, validation errors            |
| 401         | Unauthorized | Missing or invalid authentication token          |
| 403         | Forbidden    | Insufficient permissions, accessing others' data |
| 404         | Not Found    | Review, Order, Product, or Restaurant not found  |

## Data Validation Rules

### Review Creation

- `rating`: Must be between 1 and 5 (inclusive)
- `comment`: Optional, max 500 characters
- `entityType`: Must be one of: `ORDER`, `PRODUCT`, `MERCHANT`
- `entityId`: Must be a valid positive integer

### Order Reviews

- Order must exist and be delivered (`DELIVERED` status)
- Customer can only review their own orders
- One review per order (no duplicates)

### Product Reviews

- Product must exist
- Multiple reviews allowed per customer per product

### Merchant Reviews

- Merchant must exist
- One review allowed per customer per merchant

## Rate Limiting

- **Create Review**: 5 reviews per minute per customer
- **Update/Delete Review**: 10 operations per minute per user
- **Get Reviews**: 100 requests per minute per IP

## Notes & Best Practices

1. **Authentication**: All endpoints (except public reviews) require valid JWT token
2. **Ownership**: Customers can only access/modify their own reviews
3. **Moderation**: Admins have full control over all reviews for content moderation
4. **Pagination**: Use pagination for large datasets to improve performance
5. **Error Handling**: Always check status codes and handle errors appropriately
6. **Data Consistency**: Reviews are immutable except for rating and comment updates
