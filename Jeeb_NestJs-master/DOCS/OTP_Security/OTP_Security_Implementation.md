# OTP Security Implementation

## تاريخ التحديث: 29 يونيو 2026

توثيق لنظام الحماية الجديد ضد هجمات التخمين (Brute Force) على OTP، وتعديل دعم التحقق برقم الهاتف.

---

## 1. المشكلة

- نظام OTP القديم لم يكن يحدد عدد محاولات التحقق — يمكن إرسال طلبات `verifyOtp` غير محدودة بدون حظر
- الـ `VerifyAccountDto` يدعم فقط `email` — لا يمكن التحقق برقم الهاتف للـ CUSTOMER
- الـ `ResendOtpDto` يدعم فقط `email` — لا يمكن إعادة إرسال OTP عبر WhatsApp

---

## 2. المكونات الجديدة

### 2.1 `OtpAttemptService`

`src/common/services/otp-attempt.service.ts`

خدمة مسؤولة عن تتبع محاولات OTP الفاشلة باستخدام Redis.

**الثوابت:**

| الثابت | القيمة | الوصف |
|---|---|---|
| `MAX_ATTEMPTS` | 5 | الحد الأقصى للمحاولات الفاشلة قبل الحظر |
| `ATTEMPT_WINDOW` | 900 (ثانية) | نافذة 15 دقيقة لتصفير العداد |
| `BLOCK_DURATION` | 900 (ثانية) | مدة الحظر 15 دقيقة |

**الدوال:**

| الدالة | الإدخال | الإرجاع | الوصف |
|---|---|---|---|
| `recordFailedAttempt(identifier)` | string | number | يزيد عداد الفشل، يرجع عدد المحاولات. إذا ≥5 ينشئ block |
| `recordSuccessfulAttempt(identifier)` | string | void | يمسح مفاتيح attempt و block |
| `isBlocked(identifier)` | string | boolean | يتحقق من وجود block نشط |
| `getBlockInfo(identifier)` | string | OtpBlockInfo \| null | يعيد معلومات الحظر أو المحاولات الحالية |
| `getRemainingAttempts(identifier)` | string | number | MAX_ATTEMPTS - current |
| `isResendAllowed(identifier)` | string | boolean | يتحقق من cooldown إعادة الإرسال |

**مفاتيح Redis:**

| المفتاح | المدة | الوصف |
|---|---|---|
| `otp:attempt:{identifier}` | 900s (15m) | عداد محاولات OTP الفاشلة |
| `otp:block:{identifier}` | 900s (15m) | حظر بعد 5 محاولات فاشلة |
| `cooldown:otp:{identifier}` | 60s | كول داون إعادة إرسال OTP |

**مثال الاستخدام:**

```typescript
const service = new OtpAttemptService(redis);
const attempts = await service.recordFailedAttempt('+963900000001');
// attempts = 1, 2, 3, 4, 5 → بعد 5 ينشئ block
const blocked = await service.isBlocked('+963900000001');
// blocked = true
```

### 2.2 `OtpBruteForceGuard`

`src/common/guards/otp-brute-force.guard.ts`

Guard يعمل قبل الـ handler لفحص إذا كان identifier (phone/email) محظور.

**السلوك:**

- يستخرج `request.body.phone` أو `request.body.email`
- إذا لا يوجد identifier → يسمح بالمرور
- ينادي `otpAttemptService.isBlocked(identifier)`
- إذا محظور → يرجع `429 TOO_MANY_REQUESTS` مع رسالة عربية و `retryAfter`

**الـ Response عند الحظر:**

```json
{
  "statusCode": 429,
  "message": "لقد تجاوزت عدد المحاولات المسموحة. حاول مرة أخرى بعد 15 دقيقة.",
  "error": "OTP_BLOCKED",
  "retryAfter": 800
}
```

### 2.3 `OtpAttemptInterceptor`

`src/common/interceptors/otp-attempt.interceptor.ts`

Interceptor يعمل بعد الـ handler لتسجيل نجاح أو فشل التحقق.

**السلوك:**

| الحالة | الإجراء |
|---|---|
| نجاح التحقق | `recordSuccessfulAttempt(identifier)` — يمسح العداد |
| BadRequestException (OTP خاطئ) | `recordFailedAttempt(identifier)` — يزيد العداد |
| أخطاء أخرى (NotFound, إلخ) | لا يتأثر، يمرر الخطأ للأعلى |

**مبدأ العمل:**

```typescript
intercept(context, next) {
  return next.handle().pipe(
    switchMap(value => from(recordSuccessfulAttempt(identifier)).pipe(map(() => value))),
    catchError(err => {
      if (err instanceof BadRequestException) {
        return from(recordFailedAttempt(identifier)).pipe(switchMap(() => throwError(() => err)));
      }
      return throwError(() => err);
    }),
  );
}
```

---

## 3. التعديلات على الملفات الموجودة

### 3.1 `VerifyAccountDto`

`src/modules/auth/dto/verify-account.dto.ts`

| الحقل | النوع | مطلوب | الوصف |
|---|---|---|---|
| `email` | string (email) | اختياري | البريد الإلكتروني |
| `phone` | string | اختياري | رقم الهاتف |
| `otp` | string | **نعم** | رمز التحقق |

> يجب تقديم واحد على الأقل من `email` أو `phone`.

### 3.2 `ResendOtpDto`

`src/modules/auth/dto/resend-otp.dto.ts`

| الحقل | النوع | مطلوب | الوصف |
|---|---|---|---|
| `email` | string (email) | اختياري | البريد الإلكتروني |
| `phone` | string | اختياري | رقم الهاتف |

> يجب تقديم واحد على الأقل من `email` أو `phone`.

### 3.3 `RegistrationService.verifyAccount`

`src/modules/auth/services/registration.service.ts:191`

**قبل:** يقبل `email` فقط ويبحث عبر `findOneByEmail`

**بعد:** يقبل `identifier` — يحاول `findOneByEmail` أولاً، إذا لم يجد يحاول `findOneByPhone`

```typescript
async verifyAccount(identifier: string, otp: string) {
  let user = await this.usersService.findOneByEmail(identifier);
  if (!user) {
    user = await this.usersService.findOneByPhone(identifier);
  }
  if (!user) {
    throw new NotFoundException('User not found');
  }
  // ... rest of verification
}
```

### 3.4 `PasswordService.resendOtp`

`src/modules/auth/services/password.service.ts:54`

**قبل:** يقبل `email` فقط، يرسل عبر `EMAIL` دائماً

**بعد:** يقبل `identifier`، يحدد القناة حسب `user.notificationChannel`:

| `notificationChannel` | القناة | المستلم |
|---|---|---|
| `EMAIL` | `EMAIL` | `user.email` |
| `WHATSAPP` | `WHATSAPP` | `user.phone` |

### 3.5 `AuthService`

`src/modules/auth/auth.service.ts`

تغيير اسم الباراميتر من `email` إلى `identifier` في الدالتين:
- `verifyAccount(identifier: string, otp: string):39`
- `resendOtp(identifier: string):55`

### 3.6 `AuthController`

`src/modules/auth/auth.controller.ts`

| التغيير | الوصف |
|---|---|
| إضافة `@UseGuards(OtpBruteForceGuard)` على `POST /auth/verify` | فحص قبلي |
| إضافة `@UseInterceptors(OtpAttemptInterceptor)` على `POST /auth/verify` | تسجيل بعدي |
| `identifier = email \|\| phone` في `verify` و `resendOtp` | دعم كلا الحقلين |

### 3.7 `CommonModule`

`src/common/common.module.ts`

إضافة ثلاثة providers جدد مع التصدير:

```typescript
providers: [
  // ... existing
  OtpAttemptService,
  OtpBruteForceGuard,
  OtpAttemptInterceptor,
],
exports: [
  // ... existing
  OtpAttemptService,
  OtpBruteForceGuard,
  OtpAttemptInterceptor,
],
```

---

## 4. تدفق البيانات الكامل

```
POST /auth/verify
{
  "phone": "+963900000001",
  "otp": "123456"
}
  │
  ├─ 1. OtpBruteForceGuard
  │     └─ isBlocked("+963900000001")?
  │           ├─ true  → ❌ 429 TOO_MANY_REQUESTS
  │           └─ false → ✅ استمر
  │
  ├─ 2. AuthController.verify
  │     └─ identifier = "+963900000001"
  │
  ├─ 3. AuthService.verifyAccount → RegistrationService.verifyAccount
  │     ├─ findOneByEmail("+963900000001") → null
  │     ├─ findOneByPhone("+963900000001") → User { ... }
  │     ├─ notificationsService.verifyOtp(phone, otp)
  │     │     ├─ Redis موجود ومطابق؟ → success
  │     │     └─ غير مطابق؟ → false → BadRequestException
  │     └─ success → update verifiedAt + generate JWT
  │
  ├─ 4. OtpAttemptInterceptor
  │     ├─ نجاح → recordSuccessfulAttempt → مسح العداد
  │     └─ BadRequest → recordFailedAttempt
  │           ├─ 1-4 محاولات → incr العداد
  │           └─ 5 محاولات → set block key + مسح العداد
  │
  └─ Response { statusCode: 200, data: { access_token, user } }
```

---

## 5. السيناريوهات والأمان

### سيناريو 1: مستخدم حقيقي يتحقق بشكل صحيح

1. يسجل رقم هاتف
2. يستلم OTP عبر WhatsApp
3. يدخل OTP الصحيح → يتحقق الحساب
4. **العداد يُمسح** — لا أثر

### سيناريو 2: مهاجم يخمن OTP

1. يرسل 5 أرقام OTP مختلفة
2. كل مرة: `recordFailedAttempt` تزيد العداد
3. بعد 5 محاولات: إنشاء `otp:block:{phone}` لمدة 15 دقيقة
4. أي محاولة إضافية → `OtpBruteForceGuard` يمنع بـ 429

### سيناريو 3: مستخدم يعيد إرسال OTP

1. طلب `POST /auth/resend-otp { phone: "+963..." }`
2. `cooldown:otp:{phone}` يمنع الإرسال لمدة 60 ثانية
3. OTP جديد يُرسل عبر WhatsApp (يكتب فوق القديم في Redis)
4. **عداد المحاولات لا يُمسح** — الحماية مستمرة

### سيناريو 4: مهاجم يضغط على resend لتجاوز الحظر

1. بعد حظر من verify، يحاول إعادة إرسال OTP
2. OTP جديد يُرسل → يكتب فوق القديم
3. **لكن**: `otp:block:{phone}` ما زال موجوداً
4. verify لا يزال ممنوعاً → 429

---

## 6. اختبارات الوحدة

### ملفات الاختبار الجديدة

| الملف | عدد الاختبارات | الوصف |
|---|---|---|
| `test/unit/common/services/otp-attempt.service.spec.ts` | 13 | اختبارات OtpAttemptService |
| `test/unit/common/guards/otp-brute-force.guard.spec.ts` | 4 | اختبارات Guard |
| `test/unit/common/interceptors/otp-attempt.interceptor.spec.ts` | 4 | اختبارات Interceptor |

### الملفات المحدثة

| الملف | التحديث |
|---|---|
| `test/unit/modules/auth/auth.controller.spec.ts` | إضافة mock لـ OtpAttemptService + اختبار verify بالـ phone |
| `test/unit/modules/auth/auth.service.spec.ts` | إضافة اختبار verifyAccount بالـ phone |
| `test/unit/modules/auth/registration.service.spec.ts` | إضافة `findOneByPhone` للـ mock + اختبار verify بالـ phone |
| `test/unit/modules/auth/password.service.spec.ts` | إضافة `findOneByPhone` للـ mock + اختبار resend بالـ phone |

### إجمالي الاختبارات: **526 passing, 1 skipped, 62 suites**

---

## 7. ملخص التغييرات

| الملف | الحالة |
|---|---|
| `src/common/services/otp-attempt.service.ts` | **جديد** |
| `src/common/guards/otp-brute-force.guard.ts` | **جديد** |
| `src/common/interceptors/otp-attempt.interceptor.ts` | **جديد** |
| `src/common/common.module.ts` | معدل |
| `src/modules/auth/dto/verify-account.dto.ts` | معدل |
| `src/modules/auth/dto/resend-otp.dto.ts` | معدل |
| `src/modules/auth/services/registration.service.ts` | معدل |
| `src/modules/auth/services/password.service.ts` | معدل |
| `src/modules/auth/auth.service.ts` | معدل |
| `src/modules/auth/auth.controller.ts` | معدل |
| `test/unit/common/services/otp-attempt.service.spec.ts` | **جديد** |
| `test/unit/common/guards/otp-brute-force.guard.spec.ts` | **جديد** |
| `test/unit/common/interceptors/otp-attempt.interceptor.spec.ts` | **جديد** |

---

## 8. المراجع

- `SECURITY_IMPLEMENTATION.md` — توثيق الأمان العام للنظام
- `AUTH_API.md` — توثيق endpoints المصادقة
- `src/common/services/login-attempt.service.ts` — النمط المماثل لحماية تسجيل الدخول
