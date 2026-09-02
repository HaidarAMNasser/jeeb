# Authentication API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## Table of Contents

1. [Register](#1-register)
2. [Customer Registration (Phone-First)](#2-customer-registration-phone-first)
3. [Login](#3-login)
4. [Guest Login](#4-guest-login)
5. [Verify Account](#5-verify-account)
6. [Resend OTP](#6-resend-otp)
7. [Forgot Password](#7-forgot-password)
8. [Reset Password](#8-reset-password)
9. [Get Profile](#9-get-profile)
10. [Update Profile](#10-update-profile)
11. [Delete Account](#11-delete-account)
12. [Logout](#12-logout)
13. [Update Firebase Token](#13-update-firebase-token)
14. [Admin: Create Admin/Merchant User](#14-admin-create-adminmerchant-user)
15. [Error Codes](#15-error-codes)
16. [Enums Reference](#16-enums-reference)

---

## 1. Register

Create a new account.

- **URL:** `/auth/register`
- **Method:** `POST`
- **Headers:** `Content-Type: multipart/form-data`
- **Auth:** None (Public)

### Payload

| Field                 | Type         | Required | Description                                                                  |
| --------------------- | ------------ | -------- | ---------------------------------------------------------------------------- |
| `email`               | string       | Yes      | Email address                                                                |
| `password`            | string       | Yes      | Password (min 6 characters)                                                  |
| `firstName`           | string       | Yes      | First name                                                                   |
| `lastName`            | string       | Yes      | Last name                                                                    |
| `phone`               | string       | Yes      | Phone number                                                                 |
| `role`                | string       | Yes      | Role: `DELIVERY`, `MERCHANT`                                                 |
| `countryId`           | number       | No       | Country ID                                                                   |
| `cityId`              | number       | No       | City ID                                                                      |
| `areaId`              | number       | No       | Area ID                                                                      |
| `address`             | string       | No       | Address                                                                      |
| `notificationChannel` | string       | No       | `EMAIL`, `WHATSAPP`, `SMS`, `FIREBASE` (default: `FIREBASE`)                 |
| `birthday`            | string       | No       | Date of birth (YYYY-MM-DD)                                                   |
| `restaurantName`      | string       | No*      | Restaurant name (required if role is `MERCHANT`)                             |
| `type`                | string       | No       | Merchant type: `RESTAURANT`, `STORE` (MERCHANT only)                         |
| `description`         | string       | No       | Restaurant description (MERCHANT only)                                       |
| `isOpen`              | boolean      | No       | Store open status (MERCHANT only)                                            |
| `isOnline`            | boolean      | No       | Online status                                                                |
| `location`            | object       | No       | `{"lat": number, "lng": number}` — send as JSON string in form-data          |
| `image`               | file         | No       | Profile image (CUSTOMER/MERCHANT: single image using `image` field)          |
| `images`              | file[]       | No       | Profile images (DELIVERY: up to 3 images using `images` field, 5MB each)     |

**Allowed image types:** `image/jpeg`, `image/jpg`, `image/png`, `image/gif`, `image/webp` — max 5MB each.

### Role-Specific Behavior

| Role       | isActive | Notes                                                                      |
| ---------- | -------- | -------------------------------------------------------------------------- |
| `CUSTOMER` | `true`   | Activated immediately, can login after verification                        |
| `MERCHANT` | `false`  | Requires admin activation via `PATCH /users/merchants/:id/confirm`         |
| `DELIVERY` | `false`  | Requires admin activation via `PATCH /users/deliveries/:id/confirm`        |

> **⚠️ CUSTOMER registration is deprecated in this endpoint.** New CUSTOMER accounts must use the [Phone-First Registration Flow](#2-customer-registration-phone-first) (`POST /auth/register/customer/*`). This endpoint continues to support `MERCHANT` and `DELIVERY` roles.

### Phone Uniqueness

For `DELIVERY` role, phone number must be unique. If already registered:

```json
{
  "statusCode": 400,
  "message": "Phone number already registered",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

This validation does NOT apply to `MERCHANT` role.

### Response (201 Created) — DELIVERY / MERCHANT

```json
{
  "statusCode": 201,
  "message": "تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى البريد الإلكتروني.",
  "data": {
    "message": "تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى البريد الإلكتروني."
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

### Response (400 Bad Request)

Email already exists:

```json
{
  "statusCode": 400,
  "message": "User with this email already exists",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

Missing restaurant name for MERCHANT:

```json
{
  "statusCode": 400,
  "message": "Restaurant name is required for merchant registration",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

Invalid file type:

```json
{
  "statusCode": 400,
  "message": "Invalid file type: application/pdf. Allowed: image/jpeg, image/png, image/gif, image/webp",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

### Request Example

```bash
# MERCHANT registration
curl -X POST http://localhost:3000/api/v1/auth/register \
  -F "email=restaurant@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=Ahmad" \
  -F "lastName=Hassan" \
  -F "phone=+963912345678" \
  -F "role=MERCHANT" \
  -F "restaurantName=Ahmad's Restaurant" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "address=Damascus, Restaurant Street 123" \
  -F "image=@/path/to/logo.jpg"

# DELIVERY registration with multiple images
curl -X POST http://localhost:3000/api/v1/auth/register \
  -F "email=driver@example.com" \
  -F "password=strongPassword123" \
  -F "firstName=Driver" \
  -F "lastName=One" \
  -F "phone=+963987654321" \
  -F "role=DELIVERY" \
  -F "images=@/path/to/photo1.jpg" \
  -F "images=@/path/to/photo2.jpg"
```

---

## 2. Customer Registration (Phone-First)

A 3-step phone-first registration flow for CUSTOMER accounts. The user starts by providing their phone number, verifies via OTP (WhatsApp), and the account is created immediately upon OTP verification. The final step (optional) allows updating additional profile data.

- **Auth:** Public for steps 1 & 2; **JWT required** for step 3
- **OTP Channel:** WhatsApp only (always, regardless of user's `notificationChannel` setting)
- **Session TTL:** 15 minutes (Redis)

---

### 2.1 Initiate Registration

Start the registration by sending the phone number and basic details. OTP will be sent via WhatsApp. The password is hashed with bcrypt and stored in Redis session for the next step.

- **URL:** `/auth/register/customer/init`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`

#### Payload

| Field       | Type   | Required | Description                          |
| ----------- | ------ | -------- | ------------------------------------ |
| `phone`     | string | Yes      | Phone number                         |
| `firstName` | string | Yes      | First name                           |
| `lastName`  | string | Yes      | Last name                            |
| `password`  | string | Yes      | Password (min 6 characters)          |

```json
{
  "phone": "+963912345678",
  "firstName": "John",
  "lastName": "Doe",
  "password": "strongPassword123"
}
```

#### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "OTP sent successfully to your phone.",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/init"
}
```

#### Response (409 Conflict) — Phone Already Registered

```json
{
  "statusCode": 409,
  "message": "Phone number already registered",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/init"
}
```

---

### 2.2 Verify Phone

Verify the phone number using the OTP sent in the previous step. Upon successful OTP verification, the CUSTOMER account is **created immediately** using the data from the Init step (phone, firstName, lastName, password). The Redis session is deleted and a JWT access token is returned — the customer can start using the app right away.

- **URL:** `/auth/register/customer/verify-phone`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`

#### Payload

| Field   | Type   | Required | Description            |
| ------- | ------ | -------- | ---------------------- |
| `phone` | string | Yes      | Phone number (must match init step) |
| `otp`   | string | Yes      | 6-digit OTP code       |

```json
{
  "phone": "+963912345678",
  "otp": "123456"
}
```

#### Response (200 OK) — Account Created

```json
{
  "statusCode": 200,
  "message": "Account created and verified successfully.",
  "data": {
    "message": "Account created and verified successfully.",
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+963912345678",
      "role": "CUSTOMER"
    }
  },
  "timestamp": "2026-06-30T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/verify-phone"
}
```

> يعيد فقط البيانات التي أدخلها المستخدم (id, firstName, lastName, phone, role). الحقول الأخرى (email, countryId, cityId, address, location, birthday, image, إلخ) لم تُدخل بعد ويمكن إضافتها لاحقاً عبر الخطوة 3.

#### Response (400 Bad Request)

No session found:

```json
{
  "statusCode": 400,
  "message": "No registration session found. Please start again.",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/verify-phone"
}
```

Invalid OTP:

```json
{
  "statusCode": 400,
  "message": "Invalid OTP code",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/verify-phone"
}
```

---

### 2.3 Complete Registration (Optional)

Update the CUSTOMER account with additional profile data. This step is **optional** — the account was already created in step 2.2. Use this endpoint to add an email, location, or other optional fields.

- **URL:** `/auth/register/customer`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: multipart/form-data`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (JWT from step 2.2)

#### Payload

| Field       | Type         | Required | Description                                                           |
| ----------- | ------------ | -------- | --------------------------------------------------------------------- |
| `email`     | string       | No       | Email address                                                         |
| `countryId` | number       | No       | Country ID                                                            |
| `cityId`    | number       | No       | City ID                                                               |
| `address`   | string       | No       | Address                                                               |
| `birthday`  | string       | No       | Date of birth (YYYY-MM-DD)                                            |
| `location`  | object       | No       | `{"lat": number, "lng": number}` — send as JSON string in form-data   |
| `isOnline`  | boolean      | No       | Online status                                                         |
| `image`     | file         | No       | Profile image (single, max 5MB)                                       |

**Allowed image types:** `image/jpeg`, `image/jpg`, `image/png`, `image/gif`, `image/webp` — max 5MB.

#### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Profile updated successfully.",
  "data": {
    "message": "Profile updated successfully.",
    "user": {
      "id": 1,
      "firstName": "John",
      "lastName": "Doe",
      "email": "customer@example.com",
      "phone": "+963912345678",
      "role": "CUSTOMER",
      "notificationChannel": "FIREBASE",
      "firebaseToken": null,
      "countryId": 1,
      "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" }, "code": "SY", "callingCode": "+963" },
      "cityId": 1,
      "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
      "areaId": null,
      "area": null,
      "address": "Damascus, Syria",
      "isOnline": false,
      "isActive": true,
      "verifiedAt": "2026-06-30T12:00:00.000Z",
      "currentLat": null,
      "currentLng": null,
      "location": null,
      "birthday": null,
      "lastLoginAt": null,
      "lastLoginIp": null,
      "createdAt": "2026-06-30T11:55:00.000Z",
      "updatedAt": "2026-06-30T12:05:00.000Z",
      "officeOwnerId": null,
      "deletedAt": null,
      "image": null,
      "imageId": null
    }
  },
  "timestamp": "2026-06-30T12:05:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

> Returns **all user fields** (same shape as Customer Login Response). Fields that were not provided remain unchanged from their previous values.

#### Response (400 Bad Request)

Email already exists:

```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

Invalid country/city:

```json
{
  "statusCode": 400,
  "message": "Country with ID 999 not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

#### Response (404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

#### Request Example

```bash
curl -X POST http://localhost:3000/api/v1/auth/register/customer \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -F "email=customer@example.com" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "image=@/path/to/profile.jpg"
```

---

## 3. Login

Authenticate and receive an access token.

- **URL:** `/auth/login`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

Provide **email** or **phone** (at least one required).

| Field            | Type   | Required | Description                |
| ---------------- | ------ | -------- | -------------------------- |
| `email`          | string | No*      | Email (required if no phone) |
| `phone`          | string | No*      | Phone (required if no email) |
| `password`       | string | Yes      | Password                   |
| `firebaseToken`  | string | No       | FCM device token (optional; updates user's Firebase token on login) |

```json
{
  "email": "user@example.com",
  "password": "strongPassword123"
}
```

Or with phone:

```json
{
  "phone": "+963912345678",
  "password": "strongPassword123"
}
```

### Response (200 OK)

The response structure varies by role.

#### Customer Login Response

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 12,
      "firstName": "John",
      "lastName": "Doe",
      "email": "user@example.com",
      "phone": "+963912345678",
      "role": "CUSTOMER",
      "notificationChannel": "EMAIL",
      "firebaseToken": null,
      "countryId": 1,
      "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" }, "code": "SY", "callingCode": "+963" },
      "cityId": 1,
      "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
      "areaId": null,
      "area": null,
      "address": "Damascus, User Street 123",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-03-08T16:33:56.616Z",
      "currentLat": null,
      "currentLng": null,
      "location": null,
      "birthday": "1990-05-15",
      "lastLoginAt": "2026-03-08T16:33:56.616Z",
      "lastLoginIp": "192.168.1.100",
      "createdAt": "2026-03-08T16:33:56.616Z",
      "updatedAt": "2026-03-08T16:33:56.616Z",
      "officeOwnerId": null,
      "image": {
        "id": 1,
        "entityType": "USER",
        "entityId": 12,
        "url": "https://api.jeeb2.com/uploads/users/12/profile.webp",
        "mobileUrl": "https://api.jeeb2.com/uploads/users/12/profile_mobile.webp",
        "thumbnailUrl": "https://api.jeeb2.com/uploads/users/12/profile_thumb.webp",
        "isMain": true,
        "displayOrder": 0,
        "createdAt": "2026-03-08T16:33:56.616Z",
        "updatedAt": "2026-03-08T16:33:56.616Z"
      },
      "imageId": 1
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

#### Merchant Login Response

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 27,
      "firstName": "Ahmad",
      "lastName": "Hassan",
      "email": "merchant@example.com",
      "phone": "+963912345678",
      "role": "MERCHANT",
      "notificationChannel": "WHATSAPP",
      "firebaseToken": null,
      "countryId": 1,
      "country": { ... },
      "cityId": 1,
      "city": { ... },
      "areaId": null,
      "area": null,
      "address": "Damascus, Merchant Street 123",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-03-10T10:39:17.846Z",
      "currentLat": null,
      "currentLng": null,
      "location": { "lat": 33.5138, "lng": 36.2765 },
      "birthday": "1990-05-15",
      "lastLoginAt": "2026-03-10T13:55:59.554Z",
      "lastLoginIp": "192.168.1.100",
      "createdAt": "2026-03-10T10:39:17.846Z",
      "updatedAt": "2026-03-10T13:55:59.554Z",
      "officeOwnerId": null,
      "image": { ... },
      "imageId": 27,
      "merchantId": 27,
      "restaurantName": "Ahmad's Restaurant",
      "isOpen": true,
      "description": "Restaurant description",
      "hidePhoneNumber": false,
      "estimatedDeliveryMinutes": 30
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

> If the merchant account is not activated (`isActive: false`), login is rejected with "حسابك قيد المراجعة من قبل المدير".

#### Delivery Login Response

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 45,
      "firstName": "Driver",
      "lastName": "One",
      "email": "driver@example.com",
      "phone": "+963987654321",
      "role": "DELIVERY",
      "notificationChannel": "WHATSAPP",
      "firebaseToken": null,
      "countryId": 1,
      "country": { ... },
      "cityId": 1,
      "city": { ... },
      "areaId": null,
      "area": null,
      "address": "Damascus, Street 3",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-03-10T10:00:00.000Z",
      "currentLat": null,
      "currentLng": null,
      "location": { "lat": 33.5138, "lng": 36.2765 },
      "birthday": null,
      "lastLoginAt": "2026-03-10T10:00:00.000Z",
      "lastLoginIp": "192.168.1.100",
      "createdAt": "2026-03-10T10:00:00.000Z",
      "updatedAt": "2026-03-10T10:00:00.000Z",
      "officeOwnerId": null,
      "images": [
        { "id": 1, "entityType": "USER", "entityId": 45, "url": "...", "mobileUrl": "...", "thumbnailUrl": "...", "isMain": true, "displayOrder": 0 },
        { "id": 2, "entityType": "USER", "entityId": 45, "url": "...", "mobileUrl": "...", "thumbnailUrl": "...", "isMain": false, "displayOrder": 1 }
      ]
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

> DELIVERY role returns `images` array (up to 3 images). CUSTOMER, MERCHANT, and ADMIN return `image` (single object) and `imageId`.

#### Admin Login Response

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 3,
      "firstName": "Admin",
      "lastName": "System",
      "email": "admin@jeeb.com",
      "phone": "+963950000003",
      "role": "ADMIN",
      "notificationChannel": "EMAIL",
      "firebaseToken": null,
      "countryId": null,
      "country": null,
      "cityId": null,
      "city": null,
      "areaId": null,
      "area": null,
      "address": "Damascus, Syria",
      "isOnline": true,
      "isActive": true,
      "verifiedAt": "2026-03-07T18:23:26.969Z",
      "currentLat": null,
      "currentLng": null,
      "location": null,
      "birthday": null,
      "lastLoginAt": "2026-03-07T18:23:26.969Z",
      "lastLoginIp": "192.168.1.1",
      "createdAt": "2026-03-07T18:23:27.006Z",
      "updatedAt": "2026-03-07T18:23:27.006Z",
      "officeOwnerId": null,
      "image": null,
      "imageId": null
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

### Response (401 Unauthorized)

Invalid credentials:

```json
{
  "statusCode": 401,
  "message": "Invalid email/phone or password",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

Account not verified:

```json
{
  "statusCode": 401,
  "message": "Account not verified. Please verify your account first.",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

### Response (403 Forbidden) — Account Locked

```json
{
  "statusCode": 403,
  "message": "Account is temporarily locked",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

### Response (429 Too Many Requests) — IP Blocked

```json
{
  "statusCode": 429,
  "message": "Too many failed login attempts from your IP address. Please try again in 5 minutes.",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/login"
}
```

---

## 4. Guest Login

Login or create a shadow account using a Firebase anonymous token. Guests get a `CUSTOMER` role with `is_guest: true`.

- **URL:** `/auth/guest`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

| Field            | Type   | Required | Description                           |
| ---------------- | ------ | -------- | ------------------------------------- |
| `firebaseToken`  | string | Yes      | Firebase Anonymous Authentication Token |

```json
{
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6I..."
}
```

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 100,
      "firstName": "Guest",
      "lastName": "User",
      "role": "CUSTOMER",
      "is_guest": true,
      "image": null,
      "imageId": null
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/guest"
}
```

### Response (403 Forbidden) — Invalid Token

```json
{
  "statusCode": 403,
  "message": "Invalid Firebase Token",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/guest"
}
```

---

## 5. Verify Account

Verify a newly registered account using the OTP sent to email or phone.

- **URL:** `/auth/verify`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

| Field   | Type   | Required | Description                            |
| ------- | ------ | -------- | -------------------------------------- |
| `email` | string | No*      | Email (required if no phone)           |
| `phone` | string | No*      | Phone (required if no email)           |
| `otp`   | string | Yes      | 6-digit OTP code                       |

```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

### Response (200 OK) — CUSTOMER

After successful verification, the user receives a token and profile data:

```json
{
  "statusCode": 200,
  "message": "Account verified successfully.",
  "data": {
    "message": "Account verified successfully.",
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+963912345678",
      "role": "CUSTOMER",
      "verifiedAt": "2026-06-07T12:00:00.000Z",
      "image": null,
      "imageId": null
    }
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

### Response (202 Accepted) — DELIVERY

```json
{
  "statusCode": 202,
  "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
  "data": {
    "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
    "userId": 45
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

### Response (202 Accepted) — MERCHANT

```json
{
  "statusCode": 202,
  "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
  "data": {
    "message": "تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.",
    "userId": 27,
    "isActive": false
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

### Response (200 OK) — Already Verified

```json
{
  "statusCode": 200,
  "message": "Account already verified",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

### Response (400 Bad Request) — Invalid OTP

```json
{
  "statusCode": 400,
  "message": "Invalid OTP code",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

### Response (404 Not Found) — User Not Found

```json
{
  "statusCode": 404,
  "message": "User not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/verify"
}
```

---

## 6. Resend OTP

Request a new OTP if the previous one was not received. Uses a 60-second Redis cooldown.

- **URL:** `/auth/resend-otp`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

| Field   | Type   | Required | Description                     |
| ------- | ------ | -------- | ------------------------------- |
| `email` | string | No*      | Email (required if no phone)    |
| `phone` | string | No*      | Phone (required if no email)    |

At least one of `email` or `phone` is required.

```json
{
  "email": "user@example.com"
}
```

Or with phone:

```json
{
  "phone": "+963912345678"
}
```

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "OTP resent successfully to your email.",
  "data": {
    "message": "OTP resent successfully to your email."
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/resend-otp"
}
```

### Response (400 Bad Request) — Cooldown

```json
{
  "statusCode": 400,
  "message": "Too many OTP requests, please try again later",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/resend-otp"
}
```

### Response (400 Bad Request) — Already Verified

```json
{
  "statusCode": 400,
  "message": "Account already verified",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/resend-otp"
}
```

### Response (404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/resend-otp"
}
```

---

## 7. Forgot Password

Initiate password reset by sending an OTP to the user's email or phone.

- **URL:** `/auth/forgot-password`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

| Field   | Type   | Required | Description                     |
| ------- | ------ | -------- | ------------------------------- |
| `email` | string | No*      | Email (required if no phone)    |
| `phone` | string | No*      | Phone (required if no email)    |

At least one of `email` or `phone` is required.

```json
{
  "email": "user@example.com"
}
```

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "OTP sent successfully to your email.",
  "data": {
    "message": "OTP sent successfully to your email."
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/forgot-password"
}
```

### Response (404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/forgot-password"
}
```

---

## 8. Reset Password

Set a new password using the OTP received.

- **URL:** `/auth/reset-password`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** None (Public)

### Payload

| Field      | Type   | Required | Description                  |
| ---------- | ------ | -------- | ---------------------------- |
| `email`    | string | Yes      | Email address                |
| `otp`      | string | Yes      | 6-digit OTP code             |
| `password` | string | Yes      | New password (min 6 chars)   |

```json
{
  "email": "user@example.com",
  "otp": "123456",
  "password": "newStrongPassword123"
}
```

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Password reset successfully. You can now login.",
  "data": {
    "message": "Password reset successfully. You can now login."
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/reset-password"
}
```

### Response (400 Bad Request) — Invalid OTP

```json
{
  "statusCode": 400,
  "message": "Invalid OTP code",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/reset-password"
}
```

### Response (404 Not Found)

```json
{
  "statusCode": 404,
  "message": "User not found",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/reset-password"
}
```

---

## 9. Get Profile

Retrieve the authenticated user's profile.

- **URL:** `/auth/profile`
- **Method:** `GET`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required

### Response (200 OK)

The response shape depends on the role.

#### Customer Profile

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "isActive": true,
    "verifiedAt": "2026-03-08T16:33:56.616Z",
    "createdAt": "2026-03-08T16:33:56.616Z",
    "updatedAt": "2026-03-08T16:33:56.616Z",
    "birthday": "1990-01-15",
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "country": { "id": 1, "name": { "ar": "سوريا", "en": "Syria" }, "code": "SY", "callingCode": "+963", "currencyCode": "SYP", "currencySymbol": "£" },
    "city": { "id": 1, "name": { "ar": "دمشق", "en": "Damascus" } },
    "areaId": null,
    "area": null,
    "address": "Al-Hamra Street, Building 5",
    "notificationChannel": "EMAIL",
    "isOnline": false,
    "location": { "lat": 33.5138, "lng": 36.2765 },
    "officeOwnerId": null,
    "image": { "id": 1, "url": "...", "mobileUrl": "...", "thumbnailUrl": "...", "isMain": true },
    "imageId": 1
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

#### Delivery Profile

Same as customer but returns `images` array instead of `image`/`imageId`.

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 45,
    "email": "driver@example.com",
    "role": "DELIVERY",
    "images": [ ... ],
    ...
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

#### Merchant Profile

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 27,
    "email": "merchant@example.com",
    "firstName": "Ahmad",
    "lastName": "Hassan",
    "phone": "+963912345678",
    "role": "MERCHANT",
    "country": { ... },
    "city": { ... },
    "areaId": null,
    "area": null,
    "address": "Damascus, Merchant Street 123",
    "notificationChannel": "WHATSAPP",
    "isOnline": true,
    "isActive": true,
    "verifiedAt": "2026-03-10T10:39:17.846Z",
    "createdAt": "2026-03-10T10:39:17.846Z",
    "updatedAt": "2026-03-10T13:55:59.554Z",
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "location": { "lat": 33.5138, "lng": 36.2765 },
    "birthday": "1990-05-15",
    "officeOwnerId": null,
    "image": { ... },
    "imageId": 27,
    "restaurantName": "Ahmad's Restaurant",
    "type": "RESTAURANT",
    "isOpen": true,
    "description": "Restaurant description",
    "hidePhoneNumber": false,
    "estimatedDeliveryMinutes": 30,
    "merchantIsActive": true,
    "deletedAt": null
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

### Response (401 Unauthorized)

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

---

## 10. Update Profile

Update the authenticated user's profile details.

- **URL:** `/auth/profile`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: multipart/form-data`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required

### Payload

All fields are optional.

| Field                 | Type         | Description                                                                  |
| --------------------- | ------------ | ---------------------------------------------------------------------------- |
| `firstName`           | string       | New first name                                                               |
| `lastName`            | string       | New last name                                                                |
| `phone`               | string       | New phone number                                                             |
| `countryId`           | number       | New country ID                                                               |
| `cityId`              | number       | New city ID                                                                  |
| `areaId`              | number       | New area ID                                                                  |
| `address`             | string       | New address                                                                  |
| `notificationChannel` | string       | `EMAIL`, `WHATSAPP`, `SMS`, `FIREBASE`                                       |
| `birthday`            | string       | Date of birth (YYYY-MM-DD)                                                   |
| `currentLat`          | number       | Current latitude                                                             |
| `currentLng`          | number       | Current longitude                                                            |
| `latitude`            | number       | Alternative latitude (also updates `currentLat` and `location`)              |
| `longitude`           | number       | Alternative longitude (also updates `currentLng` and `location`)             |
| `location`            | object       | `{"lat": number, "lng": number}` (send as JSON string in form-data)          |
| `isOnline`            | boolean      | Online status                                                                |
| `isOpen`              | boolean      | Store open status (MERCHANT only)                                            |
| `restaurantName`      | string       | Restaurant name (MERCHANT only)                                              |
| `description`         | string       | Restaurant description (MERCHANT only)                                       |
| `password`            | string       | Current password (required for password change)                              |
| `new_password`        | string       | New password (min 6 chars, required with `password`)                         |
| `confirmed_password`  | string       | Confirm new password (must match `new_password`)                             |
| `image`               | file         | Profile image (CUSTOMER/MERCHANT: use `image` field)                         |
| `images`              | file[]       | Profile images (DELIVERY: up to 3 images using `images` field)               |

**Allowed image types:** `image/jpeg`, `image/jpg`, `image/png`, `image/gif`, `image/webp` — max 5MB each.

### Response (200 OK)

Returns the updated user profile (same shape as Get Profile).

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "firstName": "Updated Name",
    ...
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

### Response (400 Bad Request)

Invalid location format:

```json
{
  "statusCode": 400,
  "message": "Invalid location format. Expected {lat: number, lng: number}",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

Password mismatch:

```json
{
  "statusCode": 400,
  "message": "كلمة المرور الجديدة غير متطابقة",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

Wrong current password:

```json
{
  "statusCode": 400,
  "message": "كلمة المرور القديمة غير صحيحة",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

Active delivery mission (DELIVERY only):

```json
{
  "statusCode": 400,
  "message": "Cannot update account while on active delivery mission. Active orders: #123 (PENDING)",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

### Response (401 Unauthorized)

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

---

## 11. Delete Account

Permanently delete the authenticated user's account (hard delete).

- **URL:** `/auth/profile`
- **Method:** `DELETE`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required

### Deletion Scope by Role

| Role        | What is deleted                                                                              |
| ----------- | -------------------------------------------------------------------------------------------- |
| **CUSTOMER**| Profile images, pending orders (PENDING, CONFIRMED), favorites, user data                    |
| **MERCHANT**| User data and associated merchant profile                                                    |
| **DELIVERY**| Profile images, Firebase driver document, user data (blocked if on active delivery mission)  |

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Account deleted successfully",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

### Response (400 Bad Request)

Active delivery mission (DELIVERY only):

```json
{
  "statusCode": 400,
  "message": "Cannot delete account while on active delivery mission. Active orders: #123 (PENDING)",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

### Response (401 Unauthorized)

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/profile"
}
```

---

## 12. Logout

Invalidate the current access token (single active session enforcement).

- **URL:** `/auth/logout`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (also accessible to guest users)

### Response (200 OK)

```json
{
  "statusCode": 200,
  "message": "Logged out successfully",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/logout"
}
```

### Response (401 Unauthorized)

```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/logout"
}
```

---

## 13. Update Firebase Token

Update the FCM device token for push notifications. For DELIVERY role, also generates a Firebase Custom Token.

- **URL:** `/auth/firebase-token`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Auth:** Required (also accessible to guest users)

### Payload

| Field            | Type   | Required | Description                      |
| ---------------- | ------ | -------- | -------------------------------- |
| `firebaseToken`  | string | No*      | FCM device token (if no `token`) |
| `token`          | string | No*      | Alternative FCM token field      |

At least one of `firebaseToken` or `token` is required.

```json
{
  "firebaseToken": "fcm_device_token_here"
}
```

### Response (201 Created) — Non-Delivery (CUSTOMER, MERCHANT, ADMIN)

```json
{
  "statusCode": 201,
  "message": "Firebase token updated successfully",
  "data": {
    "success": true,
    "fcmTokenUpdated": true
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/firebase-token"
}
```

### Response (201 Created) — DELIVERY

```json
{
  "statusCode": 201,
  "message": "Firebase token and custom token generated successfully",
  "data": {
    "success": true,
    "fcmTokenUpdated": true,
    "firebaseUid": "delivery_12",
    "customToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6I..."
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/firebase-token"
}
```

### Response (400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "Either token or firebaseToken is required",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/firebase-token"
}
```

---

## 14. Admin: Create Admin/Merchant User

Create an admin or merchant user directly (bypasses registration flow — user is immediately verified and active).

- **URL:** `/admin/auth/create-user`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Auth:** Required (ADMIN role only)

### Payload

| Field                 | Type    | Required | Description                                    |
| --------------------- | ------- | -------- | ---------------------------------------------- |
| `email`               | string  | Yes      | Email address                                  |
| `password`            | string  | Yes      | Password (min 6 characters)                    |
| `firstName`           | string  | Yes      | First name                                     |
| `lastName`            | string  | Yes      | Last name                                      |
| `phone`               | string  | Yes      | Phone number                                   |
| `role`                | string  | Yes      | `ADMIN` or `MERCHANT`                          |
| `countryId`           | number  | No       | Country ID                                     |
| `cityId`              | number  | No       | City ID                                        |
| `address`             | string  | No       | Address                                        |

```json
{
  "email": "newadmin@jeeb.com",
  "password": "strongPassword123",
  "firstName": "New",
  "lastName": "Admin",
  "phone": "+963912345678",
  "role": "ADMIN"
}
```

### Response (201 Created)

```json
{
  "statusCode": 201,
  "message": "User created successfully.",
  "data": {
    "userId": 50
  },
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/admin/auth/create-user"
}
```

### Response (403 Forbidden)

```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/admin/auth/create-user"
}
```

### Response (409 Conflict)

```json
{
  "statusCode": 409,
  "message": "Email already exists",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/admin/auth/create-user"
}
```

---

## 15. Error Codes

Common error codes returned by authentication endpoints.

| Identifier                    | HTTP Status | Description                                                  |
| ----------------------------- | ----------- | ------------------------------------------------------------ |
| `INVALID_CREDENTIALS`         | 401         | Invalid email/phone or password                              |
| `ACCOUNT_LOCKED` (1005)       | 403         | Account temporarily locked due to repeated failed attempts   |
| `ACCOUNT_PERMANENTLY_BLOCKED` (1005) | 403         | Account permanently blocked, contact support                 |
| `ACCOUNT_DISABLED` (1006)     | 401         | Account suspended, contact support                           |
| `ACCOUNT_PENDING` (1006)      | 401         | Account pending review by administrator                      |
| `EMAIL_NOT_VERIFIED` (1007)   | 401         | Account not yet verified via OTP                             |
| `IP_TEMPORARILY_BLOCKED`      | 429         | IP temporarily blocked due to excessive failed attempts      |
| `INVALID_FIREBASE_TOKEN`      | 403         | Invalid Firebase token provided for guest login              |

---

## 16. Enums Reference

### UserRole

| Value          | Description               |
| -------------- | ------------------------- |
| `CUSTOMER`     | Regular customer          |
| `DELIVERY`     | Delivery driver           |
| `MERCHANT`     | Merchant / restaurant     |
| `ADMIN`        | System administrator      |
| `OFFICE_OWNER` | Delivery office owner     |
| `SUPPORT`      | Support staff             |

### NotificationChannel

| Value      | Description                |
| ---------- | -------------------------- |
| `EMAIL`    | Email notifications        |
| `WHATSAPP` | WhatsApp notifications     |
| `SMS`      | SMS notifications          |
| `FIREBASE` | Firebase push notifications|

### MerchantType

| Value        | Description        |
| ------------ | ------------------ |
| `RESTAURANT` | Restaurant         |
| `STORE`      | Store / retail     |

### Image Object

| Field          | Type    | Description                  |
| -------------- | ------- | ---------------------------- |
| `id`           | number  | Image ID                     |
| `entityType`   | string  | Entity type (e.g. `USER`)    |
| `entityId`     | number  | Entity ID                    |
| `url`          | string  | Original image URL           |
| `mobileUrl`    | string  | Mobile-optimized image URL   |
| `thumbnailUrl` | string  | Thumbnail image URL          |
| `isMain`       | boolean | Is the main image            |
| `displayOrder` | number  | Display order                |
| `createdAt`    | string  | Upload timestamp             |
| `updatedAt`    | string  | Last update timestamp        |

### Image Response Differences by Role

| Role       | `images` (array) | `image` (single) | `imageId` |
| ---------- | ---------------- | ---------------- | --------- |
| `DELIVERY` | ✅ (up to 3)     | ❌               | ❌        |
| `MERCHANT` | ❌               | ✅               | ✅        |
| `CUSTOMER` | ❌               | ✅               | ✅        |
| `ADMIN`    | ❌               | ✅               | ✅        |

---

## Standard Response Envelope

All API responses follow this structure:

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-06-07T12:00:00.000Z",
  "path": "/api/v1/auth/endpoint"
}
```

- `statusCode`: HTTP status code
- `message`: Human-readable message
- `data`: Response payload (object or array)
- `timestamp`: ISO 8601 timestamp
- `path`: Request URL path

> Paginated list endpoints also include a `pagination` metadata object.
