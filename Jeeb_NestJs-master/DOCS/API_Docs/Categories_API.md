# Categories API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## Overview & Permissions

- **Write operations** (Create, Update, Delete) are restricted to **ADMIN** role only.
- **Read operations** (Get All, Get One) require a valid JWT token but are accessible to all roles.
- Categories are global — they are NOT linked to a specific merchant (`restaurantId` and `type` have been removed).
- Text fields (`name`, `description`) support multilingual storage (JSONB in database). They are passed as plain text via the API and stored with Arabic as the default language.
- Search supports both Arabic and English (`name->>'ar'`, `name->>'en'`).

---

## 1. Create Category (Admin Only)

Create a new category.

- **URL:** `/categories`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: multipart/form-data`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (ADMIN role only)

### Payload (FormData)

| Field          | Type | Required | Description                                    |
| -------------- | ---- | -------- | ---------------------------------------------- |
| `name`         | Text | Yes      | Category name (stored as Arabic by default).   |
| `description`  | Text | No       | Category description.                          |
| `isActive`     | Text | No       | `true` or `false` (default: `true`).           |
| `displayOrder` | Text | No       | Display order (number, default: `0`).          |
| `image`        | File | No       | Image file (jpeg, png, gif, webp — max 5MB).   |

### Response (201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Fast Food",
    "description": "Burgers, fries, and more",
    "isActive": true,
    "displayOrder": 1,
    "createdAt": "2026-02-23T17:57:48.269Z",
    "updatedAt": "2026-02-23T17:57:48.269Z",
    "images": [
      {
        "id": 1,
        "entityType": "CATEGORY",
        "entityId": 1,
        "url": "https://api.jeeb2.com/uploads/categories/1/image.webp",
        "mobileUrl": "https://api.jeeb2.com/uploads/categories/1/image_mobile.webp",
        "thumbnailUrl": "https://api.jeeb2.com/uploads/categories/1/image_thumb.webp",
        "isMain": true,
        "displayOrder": 0
      }
    ]
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories"
}
```

### Response (403 Forbidden) — Non-Admin

```json
{
  "message": "Only Admins can create categories",
  "error": "Forbidden",
  "statusCode": 403
}
```

### Response (422 Unprocessable Entity) — Invalid Image

```json
{
  "message": "File size too large. Max is 5MB",
  "error": "Unprocessable Entity",
  "statusCode": 422
}
```

---

## 2. Get All Categories

Retrieve categories with filtering, search, and pagination. Results are sorted by `displayOrder` ASC, then `createdAt` DESC.

- **URL:** `/categories`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`
- **Auth:** Required (any authenticated role)

### Query Parameters

| Parameter  | Type    | Description                                                |
| ---------- | ------- | ---------------------------------------------------------- |
| `page`     | number  | Page number (default: `1`, must be ≥ 1)                    |
| `limit`    | number  | Items per page (default: `10`, must be ≥ 1)                |
| `search`   | string  | Search by category name (supports Arabic and English).     |
| `isActive` | string  | Filter by active status (`true` or `false`).               |

**Example:** `/categories?page=1&limit=10&search=Burgers&isActive=true`

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 1,
      "name": "Fast Food",
      "description": "Burgers, fries, and more",
      "isActive": true,
      "displayOrder": 1,
      "images": [
        {
          "url": "https://api.jeeb2.com/uploads/categories/1/image.webp",
          "isMain": true
        }
      ]
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
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories"
}
```

---

## 3. Get One Category

Retrieve a single category by ID.

- **URL:** `/categories/:id`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`
- **Auth:** Required (any authenticated role)

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Fast Food",
    "description": "Burgers, fries, and more",
    "isActive": true,
    "displayOrder": 1,
    "images": [
      {
        "id": 1,
        "url": "https://api.jeeb2.com/uploads/categories/1/image.webp",
        "isMain": true
      }
    ]
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories/1"
}
```

### Response (404 Not Found)

```json
{
  "message": "Category with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## 4. Update Category (Admin Only)

Update category details. Supports partial updates. If a new image is uploaded, old images are deleted first.

- **URL:** `/categories/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: multipart/form-data`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (ADMIN role only)

### Payload (FormData)

All fields are optional.

| Field          | Type | Description                                     |
| -------------- | ---- | ----------------------------------------------- |
| `name`         | Text | New category name.                              |
| `description`  | Text | New description.                                |
| `isActive`     | Text | `true` or `false`.                              |
| `displayOrder` | Text | New display order.                              |
| `image`        | File | New image file (replaces existing images).      |

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Updated Name",
    "description": "Updated description",
    "isActive": false,
    "displayOrder": 2,
    "images": []
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories/1"
}
```

### Response (403 Forbidden) — Non-Admin

```json
{
  "message": "Only Admins can update categories",
  "error": "Forbidden",
  "statusCode": 403
}
```

### Response (422 Unprocessable Entity) — Invalid Image

```json
{
  "message": "File size too large. Max is 5MB",
  "error": "Unprocessable Entity",
  "statusCode": 422
}
```

---

## 5. Delete Category (Admin Only)

Permanently delete a category and its associated images.

- **URL:** `/categories/:id`
- **Method:** `DELETE`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (ADMIN role only)

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories/1"
}
```

### Response (403 Forbidden) — Non-Admin

```json
{
  "message": "Only Admins can delete categories",
  "error": "Forbidden",
  "statusCode": 403
}
```

### Response (404 Not Found)

```json
{
  "message": "Category with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## Error Codes

| Code | Error                       | Description                                |
| ---- | --------------------------- | ------------------------------------------ |
| 7101 | `CATEGORY_NOT_FOUND`        | Category not found                         |
| 7102 | `CATEGORY_ALREADY_EXISTS`   | Category already exists                    |
| 7103 | `CATEGORY_HAS_PRODUCTS`     | Cannot delete category with existing products |
| 7104 | `CATEGORY_INVALID`          | Invalid category                           |

---

## Standard Response Envelope

All successful API responses follow this structure:

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "pagination": null,
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/categories"
}
```

Error responses follow the standard NestJS exception format:

```json
{
  "message": "Error message",
  "error": "Error Type",
  "statusCode": 400
}
```
