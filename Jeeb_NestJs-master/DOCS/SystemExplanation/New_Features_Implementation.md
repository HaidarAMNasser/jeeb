# New Features Implementation & Auth Updates

## 1. Authentication Flow Updates

### Role Management

- **Public Registration (`/auth/register`)**:
  - The `role` field is now restricted to `CUSTOMER` and `MERCHANT`.
  - `DELIVERY` and `ADMIN` roles are no longer allowed to register via this endpoint.
  - This prevents unauthorized users from registering as drivers or admins.

- **Admin User Creation**:
  - A new DTO `CreateUserDto` was created for internal/admin use.
  - Admin users can still be created with specific roles via protected admin endpoints.

### Location & Profile

- **Registration Payload**: Added `countryId`, `cityId`, and `areaId` to the registration payload.
- **Notification Preferences**: Added `notificationChannel` (EMAIL/FIREBASE/WHATSAPP/SMS) to user preferences. Default is now `FIREBASE` (was `WHATSAPP`).
- **Resend OTP**: Implemented `/auth/resend-otp` endpoint to allow users to request a new OTP if the previous one expired or was not received.

## 2. Location Module

### Entities

- **Country**: Stores country data (name, code, currency, calling code).
- **City**: Stores city data linked to a country.

### Endpoints

- `GET /api/v1/location/countries`: List all active countries (Paginated).
- `GET /api/v1/location/countries/:countryId/cities`: List cities for a specific country (Paginated).

### Seeding

- A seeding script `scripts/seed-location.ts` was created to populate initial data for Syria, UAE, and Saudi Arabia.

## 3. Email Notifications (Nodemailer)

### Implementation

- Integrated `Nodemailer` for sending transactional emails.
- Replaced the placeholder SendGrid strategy.
- Users can now choose `EMAIL` as their notification channel to receive OTPs and welcome messages.

### Configuration

- SMTP settings are configured in `.env` (Host, Port, User, Pass).
- Supports Gmail and other standard SMTP providers.

## 4. Redis Integration (OTP & Caching)

### OTP Storage

- **Mechanism**: OTPs are now stored in Redis instead of an in-memory map or database column.
- **TTL (Time-To-Live)**: OTPs automatically expire after 5 minutes (300 seconds).
- **Validation**: The system checks Redis for the OTP presence and validity during verification.

## 5. Order Management (BullMQ)

### Order Timeout

- **Queue System**: Implemented BullMQ to handle background jobs.
- **Timeout Logic**: Orders created with `PENDING` status are added to a delayed queue.
- **Auto-Cancellation**: If an order remains `PENDING` for 15 minutes, the processor automatically cancels it.

## 6. Scheduled Tasks (Cron)

### Notification Cleanup

- **Schedule**: Runs daily at midnight.
- **Task**: Cleans up old notification logs to maintain database performance.

## 8. Categories Module

### Implementation

- **Category Entity**: Supports two types of categories via `CategoryType` enum:
  - `CUISINE`: Global categories (e.g., Italian, Burger) created by Admin.
  - `MENU`: Restaurant-specific menu sections (e.g., Starters, Drinks) created by Merchant.
- **Relationships**:
  - `ManyToMany` between `Restaurant` and `Category` (Cuisines).
  - `OneToMany` between `Restaurant` and `Category` (Menu Sections).
  - `ManyToOne` between `Product` and `Category`.

### Endpoints

- `POST /categories`: Create a category (Admin for Cuisine, Merchant for Menu).
- `GET /categories`: List categories with filtering options.
- `PATCH /categories/:id`: Update category details.
- `DELETE /categories/:id`: Remove category.

### Validation

- Products must belong to a `MENU` category owned by the same restaurant.
- Merchants can only manage their own menu sections.
- Only Admins can manage Cuisines.

## 9. API Documentation

- Updated Postman Collection (`Jeeb_Delivery_API.postman_collection.json`) with updated Auth and Location endpoints.
- Created new Postman Collection (`Jeeb_Categories_API.postman_collection.json`) for Categories management.
