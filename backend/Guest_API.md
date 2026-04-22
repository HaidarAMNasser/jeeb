# Guest API Documentation

Base URL: `http://localhost:3000/api/v1`

## 1. Guest Login (تسجيل دخول كضيف)

تسجيل دخول مؤقت للمستخدمين الذين يرغبون في تجربة التطبيق دون إنشاء حساب دائم.

- **URL:** `/auth/guest`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
- **Public:** ✅ Yes (لا يتطلب توكن)

### Payload (Request Body)

| Field           | Type   | Required | Description                             |
| --------------- | ------ | -------- | --------------------------------------- |
| `firebaseToken` | string | Yes      | Firebase Anonymous Authentication Token |

### Request Example

```bash
curl -X POST http://localhost:3000/api/v1/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"firebaseToken": "eyJhbGciOiJSUzI1..."}'
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 999,
      "firstName": "Guest",
      "lastName": "User",
      "email": "guest-abc123@jeeb.local",
      "phone": "abc123456789",
      "role": "CUSTOMER",
      "isActive": true,
      "createdAt": "2026-04-13T00:00:00.000Z"
    }
  },
  "timestamp": "2026-04-13T00:00:00.000Z",
  "path": "/api/v1/auth/guest"
}
```

### Response (Error - 403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Invalid Firebase Token",
  "error": "Forbidden",
  "data": null,
  "timestamp": "2026-04-13T00:00:00.000Z",
  "path": "/api/v1/auth/guest"
}
```

---

## 2. What Can Guests Access?

### ✅ Allowed Operations (Read-Only)

| Endpoint         | Method | Description      |
| ---------------- | ------ | ---------------- |
| `/auth/profile`  | GET    | عرض الملف الشخصي |
| `/merchants`     | GET    | تصفح التجار      |
| `/merchants/:id` | GET    | عرض تاجر محدد    |
| `/products`      | GET    | تصفح المنتجات    |
| `/products/:id`  | GET    | عرض منتج محدد    |
| `/categories`    | GET    | تصفح الفئات      |
| `/orders/costs`  | GET    | حساب تكلفة الطلب |
| `/cart`          | GET    | عرض السلة        |

### ❌ Restricted Operations (Not Allowed)

| Endpoint              | Method | Error Message                                                          |
| --------------------- | ------ | ---------------------------------------------------------------------- |
| Any POST/PATCH/DELETE | All    | "عذراً، يجب إنشاء حساب دائم للتمتع بهذه الصلاحيات وإتمام هذه العملية." |

---

## 3. Guest Account Details

### Account Properties

| Property    | Value                             | Description        |
| ----------- | --------------------------------- | ------------------ |
| `email`     | `guest-{firebase_uid}@jeeb.local` | بريد إلكتروني مؤقت |
| `firstName` | "Guest"                           | الاسم              |
| `lastName`  | "User"                            | اسم العائلة        |
| `role`      | CUSTOMER                          | الدور              |
| `isActive`  | true                              | حالة التفعيل       |
| `password`  | Random hash                       | كلمة مرور عشوائية  |

### Limitations

- ❌ لا يمكنهم إضافة منتجات للسلة
- ❌ لا يمكنهم إنشاء طلبات
- ❌ لا يمكنهم إضافة منتجات للمفضلة
- ❌ لا يمكنهم كتابة تقييمات
- ❌ لا يمكنهم تحديث بياناتهم

---

## 4. Security & Rate Limiting

### Rate Limits

| Type             | Limit        |
| ---------------- | ------------ |
| Global (non-GET) | 30 req/min   |
| Global (GET)     | 50 req/min   |
| Long-term        | 600 req/hour |

### Protection Features

- ✅ Firebase Token Verification (تحقق من توكن Firebase)
- ✅ Global Rate Limiting (تحديد عدد الطلبات)
- ✅ Track by IP + User-Agent (تتبع بعنوان IP)
- ✅ GuestRestrictionGuard (تقييد العمليات)

---

## 5. Guest Account Lifecycle

### Creation Flow

```
1. User (App) → Firebase Anonymous Auth → Get Firebase Token
2. App → POST /auth/guest with Firebase Token
3. Server → Verify Firebase Token → Get UID
4. Server → Check/Create Shadow User (guest-{UID}@jeeb.local)
5. Server → Return JWT Token
6. User → Can browse (read-only)
```

### Garbage Collection

- **Schedule:** Daily at 3:00 AM
- **Criteria:**
  - Email pattern: `guest-%@jeeb.local`
  - No login for 5 days
  - No orders associated
- **Action:** Soft delete (can be restored)

---

## 6. Converting Guest to Permanent Account

guests can create a permanent account by registering via `/auth/register`.

### Flow

```
1. Guest logs in
2. Guest opens registration form
3. Fills: email, password, phone, etc.
4. Submits to /auth/register
5. System creates new permanent account
6. Guest data can be migrated (optional)
```

---

## 7. Error Codes

| Code | Message                  | Description            |
| ---- | ------------------------ | ---------------------- |
| 403  | "Invalid Firebase Token" | توكن Firebase غير صالح |
| 429  | "Too Many Requests"      | تجاوز حد الطلبات       |
| 500  | "Internal Server Error"  | خطأ في السيرفر         |

---

## 8. Postman Collection

### Sample Request

```json
{
  "name": "Guest Login",
  "request": {
    "method": "POST",
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      }
    ],
    "body": {
      "mode": "raw",
      "raw": "{\n    \"firebaseToken\": \"eyJhbGciOiJSUzI1...\"\n}"
    },
    "url": {
      "raw": "{{baseUrl}}/auth/guest",
      "host": ["{{baseUrl}}"],
      "path": ["auth", "guest"]
    }
  }
}
```
