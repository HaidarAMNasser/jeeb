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
      "role": "CUSTOMER",
      "isActive": true,
      "is_guest": true,
      "image": null,
      "imageId": null,
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

### ✅ Allowed Operations

#### Read-Only (GET)

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

#### Mutating Operations (مسموحة للضيف)

| Endpoint                  | Method | Description                       |
| ------------------------- | ------ | --------------------------------- |
| `/auth/logout`            | POST   | تسجيل خروج (إبطال التوكن)         |
| `/auth/firebase-token`    | POST   | تحديث توكن Firebase               |
| `/cart`                   | POST   | إنشاء/استبدال السلة               |
| `/cart`                   | PATCH  | تحديث محتويات السلة               |
| `/cart`                   | DELETE | تفريغ السلة                        |
| `/favorites/toggle`       | POST   | إضافة/إزالة منتج من المفضلة       |

### ❌ Restricted Operations (Not Allowed)

| Endpoint                        | Method       | Error Message                                                          |
| ------------------------------- | ------------ | ---------------------------------------------------------------------- |
| أي عملية غير GET أو غير المسموحة بـ `@AllowGuest()` | POST/PATCH/DELETE | "عذراً، يجب إنشاء حساب دائم للتمتع بهذه الصلاحيات وإتمام هذه العملية." |

**ملاحظة:** العمليات المسموحة للضيف موضحة في الجدول أعلاه (مثل `POST /cart`, `POST /favorites/toggle`).

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

- ✅ يمكنهم إضافة منتجات للسلة وتعديلها
- ❌ لا يمكنهم إنشاء طلبات
- ✅ يمكنهم إضافة/إزالة منتجات من المفضلة
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
- **Action:** Hard delete (permanent — `userRepository.remove()`, cannot be restored)

---

## 6. Converting Guest to Permanent Account

Guests can create a permanent account by registering via `/auth/register`.

### Flow

```
1. Guest logs in
2. Guest opens registration form
3. Fills: email, password, phone, etc.
4. Submits to /auth/register
5. System creates new permanent account
6. Guest account becomes orphaned and will be cleaned up after 5 days of inactivity
```

**ملاحظة:** لا يوجد حالياً آلية لترحيل بيانات الضيف (السلة، المفضلة) إلى الحساب الدائم — يتم إنشاء حساب منفصل تماماً. يجب إعادة إضافة العناصر يدوياً بعد التسجيل.

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
