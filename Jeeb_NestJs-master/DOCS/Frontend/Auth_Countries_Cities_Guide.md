# Jeeb Delivery System - Frontend Integration Guide

This guide provides a detailed overview of the Authentication system, Roles, and Location services (Countries/Cities) for the Jeeb Delivery application. It is designed to help the Frontend team integrate seamlessly with the Backend.

---

## 1. Authentication & Roles

The system supports multiple user roles, each with specific permissions and flows.

### Supported Roles

* **CUSTOMER**: End-users who place orders.
* **DELIVERY**: Drivers who deliver orders.
* **MERCHANT**: Restaurant owners/managers.
* **ADMIN**: System administrators.

### General Auth Flow

1. **Register**: Only available for `CUSTOMER` and `DELIVERY`.
2. **Verify Account**: OTP verification is mandatory after registration.
3. **Login**: Unified login for all roles.
4. **Access Token**: JWT token returned on login/verify must be included in the `Authorization` header (`Bearer <token>`) for all protected endpoints.

---

### A. Registration (Public)

* **Endpoint**: `POST /auth/register`
* **Allowed Roles**: `CUSTOMER`, `DELIVERY`
* **Description**: Creates a new user account.
* **Note**: `MERCHANT` and `ADMIN` accounts are created by system administrators and cannot register publicly.

**Request Body (Customer):**

```json
{
  "email": "customer@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+963912345678",
  "role": "CUSTOMER",
  "countryId": 1,
  "cityId": 1,
  "areaId": 1,
  "address": "Damascus, Al-Mezzeh"
}
```

**Request Body (Delivery):**

```json
{
  "email": "driver@example.com",
  "password": "password123",
  "firstName": "Driver",
  "lastName": "One",
  "phone": "+963987654321",
  "role": "DELIVERY",
  "countryId": 1,
  "cityId": 1,
  "areaId": 1
}
```

### B. Account Verification

* **Endpoint**: `POST /auth/verify`
* **Description**: Verifies the account using the OTP sent to email/phone.
* **Trigger**: Sent automatically after Registration or Login (if unverified).

**Request Body:**

```json
{
  "email": "customer@example.com",
  "otp": "123456"
}
```

**Response (Success):**

```json
{
  "statusCode": 200,
  "message": "Account verified successfully",
  "data": {
    "access_token": "eyJhbGci...", // Save this token!
    "user": { ... }
  }
}
```

### C. Login (Unified)

* **Endpoint**: `POST /auth/login`
* **Allowed Roles**: All (`CUSTOMER`, `DELIVERY`, `MERCHANT`, `ADMIN`)
* **Description**: Authenticates the user and returns an access token.

**Request Body:**

```json
{
  "email": "any.role@example.com",
  "password": "password123"
}
```

**Response (Success):**

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "access_token": "eyJhbGci...", // JWT Token
    "user": {
      "id": 1,
      "role": "CUSTOMER", // Check this role to redirect user to correct dashboard
      "firstName": "John",
      ...
    }
  }
}
```

### D. Password Management

1. **Forgot Password**: `POST /auth/forgot-password`
    * Sends OTP to email/phone.
2. **Reset Password**: `POST /auth/reset-password`
    * Requires `email`, `otp`, and `newPassword`.

---

## 2. Location Services (Countries & Cities)

Used for populating dropdowns in Registration and Profile forms.

### A. Get All Countries

* **Endpoint**: `GET /countries`
* **Usage**: Call this on the Registration page to populate the "Country" dropdown.

**Response:**

```json
{
  "statusCode": 200,
  "data": [
    {
      "id": 1,
      "name": { "ar": "سوريا", "en": "Syria" },
      "code": "SY",
      "callingCode": "+963",
      "currencyCode": "SYP",
      "currencySymbol": "£",
      "isActive": true
    }
  ]
}
```

### B. Get Cities by Country

* **Endpoint**: `GET /cities?countryId={id}`
* **Usage**: Call this when a user selects a Country to populate the "City" dropdown.

**Response:**

```json
{
  "statusCode": 200,
  "data": [
    {
      "id": 1,
      "name": { "ar": "دمشق", "en": "Damascus" },
      "countryId": 1
    },
    {
      "id": 2,
      "name": { "ar": "حلب", "en": "Aleppo" },
      "countryId": 1
    }
  ]
}
```

---

## 3. Frontend Implementation Checklist

### Registration Form

* [ ] Fetch **Countries** on load (`GET /countries`).
* [ ] Fetch **Cities** when Country is selected (`GET /cities?countryId=...`).
* [ ] Allow role selection (Customer/Delivery) or have separate pages.
* [ ] On success, redirect to **OTP Verification** page.

### Login Page

* [ ] Single form for all users.
* [ ] On success, store `access_token` in Secure Storage / LocalStorage.
* [ ] Check `user.role` in response:
  * `CUSTOMER` -> Home Page
  * `DELIVERY` -> Driver Dashboard
  * `MERCHANT` -> Restaurant Dashboard
  * `ADMIN` -> Admin Panel

### Error Handling

* [ ] Handle `401 Unauthorized`: Token expired or invalid credentials. Redirect to Login.
* [ ] Handle `400 Bad Request`: Validation errors (show messages to user).
* [ ] Handle `403 Forbidden`: User doesn't have permission for this action.

### Headers

* Ensure **ALL** authenticated requests include:

    ```
    Authorization: Bearer <access_token>
    Accept-Language: ar  (or 'en' for English responses)
    ```
