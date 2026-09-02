# دليل تسجيل العملاء (Phone-First Flow) - الواجهة الأمامية

تاريخ التحديث: 2026-06-30

---

## 1. نظرة عامة

تم تغيير طريقة تسجيل العملاء (`CUSTOMER`) إلى **Phone-First Flow** (3 خطوات، الحساب يُنشأ في الخطوة 2).  
**لم يتغير شيء** في تسجيل `MERCHANT` أو `DELIVERY`.

| القديم | الجديد |
|--------|--------|
| `POST /auth/register` مع `role: CUSTOMER` → **معطل الآن** (يرجع خطأ 400) | `POST /auth/register/customer/init` ← `verify-phone` (يُنشأ الحساب) ← `customer` (اختياري) |

---

## 2. Old Register — ما الذي تغير؟

- `POST /auth/register` endpoint لا يزال موجودًا لـ `MERCHANT` و `DELIVERY`
- إذا أرسلت `role: CUSTOMER` → ستحصل على:

```json
{
  "statusCode": 400,
  "message": "Customer registration is now done via the phone-first flow. Please use POST /auth/register/customer/init to start.",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register"
}
```

### واجب الـ Frontend
- **إزالة أو إخفاء** زر/رابط "تسجيل عميل" من شاشة التسجيل القديمة
- الاحتفاظ بـ "تسجيل عميل" لكن يوجه إلى الشاشة الجديدة (3 خطوات)
- **MERCHANT** و **DELIVERY** بدون تغيير — يعملان كما هما

---

## 3. Phone-First Registration Flow — الـ 3 خطوات

### الخطوة 1: Init — إرسال رقم الهاتف والبيانات الأساسية

إرسال رقم الهاتف مع البيانات الأساسية → يتم إرسال OTP عبر WhatsApp.  
**كلمة المرور تُشفر وتُخزن في جلسة Redis** (لا تُستخدم بعد).

| الحقل | Method | Content-Type |
|-------|--------|-------------|
| `POST /auth/register/customer/init` | **POST** | `application/json` |

#### Payload

| الحقل       | النوع   | مطلوب | الوصف                    |
| ----------- | ------- | ----- | ------------------------ |
| `phone`     | string  | نعم   | رقم الهاتف (مع مفتاح الدولة) |
| `firstName` | string  | نعم   | الاسم الأول                |
| `lastName`  | string  | نعم   | اسم العائلة               |
| `password`  | string  | نعم   | كلمة المرور (6 أحرف كحد أدنى) |

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
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/init"
}
```

#### Error — الرقم مسجل مسبقًا (409 Conflict)

```json
{
  "statusCode": 409,
  "message": "Phone number already registered",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/init"
}
```

---

### الخطوة 2: Verify Phone — تأكيد رقم الهاتف + إنشاء الحساب فوراً 🎉

إرسال OTP المستلم عبر WhatsApp للتحقق من الرقم. **عند النجاح، يتم إنشاء حساب العميل فوراً** باستخدام البيانات من الخطوة 1 (phone, firstName, lastName, password). يتم حذف جلسة Redis وإرجاع JWT.

| الحقل | Method | Content-Type |
|-------|--------|-------------|
| `POST /auth/register/customer/verify-phone` | **POST** | `application/json` |

#### Payload

| الحقل    | النوع   | مطلوب | الوصف                    |
| -------- | ------- | ----- | ------------------------ |
| `phone`  | string  | نعم   | نفس الرقم من الخطوة 1    |
| `otp`    | string  | نعم   | كود OTP المكون من 6 أرقام |

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

> يُرجَع فقط البيانات التي أدخلها المستخدم (id, firstName, lastName, phone, role). باقي الحقول (email, countryId, cityId, address, location, birthday, image, إلخ) لم تُدخل بعد ويمكن إضافتها لاحقاً في الخطوة 3 (اختياري).

#### Error — لا توجد جلسة تسجيل (400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "No registration session found. Please start again.",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/verify-phone"
}
```

#### Error — OTP خطأ (400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "Invalid OTP code",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer/verify-phone"
}
```

---

### الخطوة 3: Complete Registration (اختياري) — إضافة بيانات إضافية

**هذه الخطوة اختيارية.** الحساب تم إنشاؤه بالفعل في الخطوة 2. استخدم هذا الـ endpoint لإضافة بريد إلكتروني، دولة، مدينة، أو أي بيانات أخرى.

| الحقل | Method | Content-Type |
|-------|--------|-------------|
| `POST /auth/register/customer` | **POST** | `multipart/form-data` |

> **مهم:** هذا الـ endpoint محمي بـ JWT. يجب إرسال `Authorization: Bearer <token>` في الـ Header (التوكن المستلم من الخطوة 2).

#### Payload (formdata)

| الحقل       | النوع         | مطلوب | الوصف                                              |
| ----------- | ------------- | ----- | -------------------------------------------------- |
| `email`     | string        | لا    | البريد الإلكتروني                                   |
| `countryId` | number        | لا    | معرف الدولة                                        |
| `cityId`    | number        | لا    | معرف المدينة                                       |
| `address`   | string        | لا    | العنوان                                            |
| `birthday`  | string        | لا    | تاريخ الميلاد (YYYY-MM-DD)                          |
| `location`  | string (JSON) | لا    | `{"lat": 33.5138, "lng": 36.2765}` — يُرسل كنص JSON |
| `isOnline`  | boolean       | لا    | حالة الاتصال (افتراضي: false)                       |
| `image`     | file          | لا    | صورة الملف الشخصي (jpeg, png, webp, max 5MB)        |

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

> **هذه الخطوة غير ملزمة — المستخدم لا يحتاج لإكمالها لاستخدام التطبيق.** الحساب نشط ويعمل منذ الخطوة 2. تُرجَع جميع حقول المستخدم (نفس شكل Customer Login Response). الحقول التي لم تُرسَل تبقى على قيمتها السابقة.

#### Error — الإيميل مسجل مسبقًا (409 Conflict)

```json
{
  "statusCode": 409,
  "message": "Email already registered",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

#### Error — الدولة/المدينة غير موجودة (400 Bad Request)

```json
{
  "statusCode": 400,
  "message": "Country with ID 999 not found",
  "data": {},
  "timestamp": "2026-06-29T12:00:00.000Z",
  "path": "/api/v1/auth/register/customer"
}
```

---

## 4. ترتيب الشاشات للـ Frontend

```
[شاشة 1]                       [شاشة 2]                      [شاشة 3 - اختيارية]
أدخل رقم الهاتف                أدخل OTP                      أكمل البيانات (إيميل، موقع)
┌─────────────────┐           ┌─────────────────┐           ┌──────────────────────┐
│                 │           │                 │           │                      │
│  📱 +963        │           │  🔢 OTP: _ _ _  │           │  📧 الإيميل          │
│  [___912345678] │   POST    │  _ _ _          │   POST    │  📍 الموقع           │
│                 │  /init    │                 │ /verify   │  🖼️ الصورة          │
│  [إرسال OTP]    │────────►  │  [تأكيد]        │────────►  │                      │
│                 │           │                 │           │  [حفظ]               │
│                 │           │  ⏪ [رجوع]       │           │                      │
└─────────────────┘           └─────────────────┘           └──────────────────────┘
                                       │                             │
                                       │ الحساب يُنشأ هنا            │ اختيارية
                                       │ ويُرجَع JWT                 │
                                       ▼                             │
                              ┌─────────────────┐                   │
                              │  ✅ تم إنشاء    │                   │
                              │  الحساب بنجاح    │◄──────────────────┘
                              │                  │
                              │  access_token    │
                              │  + user data     │
                              │                  │
                              │  [الصفحة الرئيسية]│
                              └─────────────────┘
```

### ماذا تفعل الـ Frontend بعد Verify Phone؟
1. استقبل `access_token` و `user` من الـ response
2. خزّن `access_token` (نفس آلية Login)
3. الـ user يكون مسجل دخول تلقائيًا — وجّهه للصفحة الرئيسية (لا حاجة لـ Login بعد التسجيل)
4. **اختياري:** اعرض شاشة لإكمال البيانات (email, country, city, image) وادفعها عبر الخطوة 3 مع JWT

---

## 5. تسجيل الدخول (Login) بعد التسجيل

بعد إنشاء الحساب، يمكن للمستخدم تسجيل الدخول لاحقًا بطريقتين:

### عبر البريد الإلكتروني
```
POST /auth/login
{
  "email": "customer@example.com",
  "password": "strongPassword123"
}
```

### عبر رقم الهاتف
```
POST /auth/login
{
  "phone": "+963912345678",
  "password": "strongPassword123"
}
```

نفس الـ endpoint (`/auth/login`) يقبل `email` أو `phone` — يجب تقديم واحد منهما فقط مع `password`.

### إضافة اختيارية: تحديث Firebase Token أثناء Login
```
POST /auth/login
{
  "email": "customer@example.com",
  "password": "strongPassword123",
  "firebaseToken": "fcm_device_token_here"
}
```

> **ملاحظة للـ Frontend:** يمكن إضافة زر "تسجيل الدخول برقم الهاتف" في شاشة Login بجانب "تسجيل الدخول بالبريد الإلكتروني". كلاهما يستخدم نفس الـ endpoint.

---

## 6. أوقات المهلة (TTL)

| المدة | الوصف |
|-------|-------|
| 15 دقيقة | مهلة جلسة Redis بين Init و Verify. إذا انتهت، يجب إعادة البدء من الخطوة 1. |

---

## 7. جدول الأخطاء الكامل

| المرحلة         | HTTP Status | `message`                                      | السبب                               |
| --------------- | ----------- | ---------------------------------------------- | ----------------------------------- |
| Init            | 409         | `Phone number already registered`              | الرقم مسجل مسبقًا                     |
| Verify Phone    | 400         | `No registration session found...`             | لم يتم البدء أو انتهت المهلة          |
| Verify Phone    | 400         | `Invalid OTP code`                             | OTP غير صحيح                         |
| Complete        | 404         | `User not found`                               | التوكن غير صحيح أو المستخدم غير موجود |
| Complete        | 409         | `Email already registered`                     | الإيميل مسجل مسبقًا                   |
| Complete        | 400         | `Country with ID X not found`                  | الدولة غير موجودة                     |
| Complete        | 400         | `City with ID X does not belong to Country...` | المدينة لا تنتمي للدولة المختارة      |

---

## 8. ماذا لو كان المستخدم لديه حساب قديم بحاجة لـ Verify Account؟

الـ **Phone-First Flow** الجديد ينشئ الحساب موثّقًا تلقائيًا (لا حاجة للتحقق).  
إذا كان لديك مستخدمون قدامى (مسجلين عبر old register ولم يتحققوا بعد)، يمكنهم استخدام:

- `POST /auth/verify` — لتأكيد الحساب باستخدام OTP (كما كان سابقًا)
- `POST /auth/resend-otp` — لإعادة إرسال OTP

هذا الـ flow القديم **لم يتغير**.

---

## 9. مثال كامل بالـ cURL

```bash
# Step 1: Init
curl -X POST http://localhost:3000/api/v1/auth/register/customer/init \
  -H "Content-Type: application/json" \
  -d '{"phone": "+963912345678", "firstName": "John", "lastName": "Doe", "password": "strongPassword123"}'

# Step 2: Verify Phone ← الحساب يُنشأ هنا
curl -X POST http://localhost:3000/api/v1/auth/register/customer/verify-phone \
  -H "Content-Type: application/json" \
  -d '{"phone": "+963912345678", "otp": "123456"}'

# Step 3: Complete Registration — اختياري تماماً، غير ملزم، يتطلب JWT
curl -X POST http://localhost:3000/api/v1/auth/register/customer \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -F "email=customer@example.com" \
  -F "countryId=1" \
  -F "cityId=1" \
  -F "image=@/path/to/profile.jpg"
```
