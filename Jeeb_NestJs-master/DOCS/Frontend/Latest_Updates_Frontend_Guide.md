# دليل آخر التحديثات - دليل الربط مع الواجهة الأمامية (Frontend)

تاريخ التحديث: 2026-06-17

---

## 1. إضافة `areaId` إلى المستخدم (User)

### 1.1 الوصف

أصبح المستخدم (CUSTOMER, DELIVERY, MERCHANT) يمكن أن يرتبط بمنطقة (Area) عبر `areaId` — نفس pattern `countryId` و `cityId`.

### 1.2 الحقول الجديدة في الـ User Response

| الحقل | النوع | الوصف |
|:---|---:|:---|
| `areaId` | number or null | معرف المنطقة |
| `area` | object or null | كائن المنطقة كامل: `{ id, name, price, description }` |

### 1.3 مثال Response (Login/Profile)

```json
{
    "user": {
        "id": 1,
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "phone": "+963912345678",
        "role": "CUSTOMER",
        "notificationChannel": "FIREBASE",
        "firebaseToken": null,
        "countryId": 1,
        "country": {
            "id": 1,
            "name": "Syria",
            "code": "SY"
        },
        "cityId": 1,
        "city": {
            "id": 1,
            "name": "Damascus"
        },
        "areaId": 1,
        "area": {
            "id": 1,
            "name": "المزة",
            "price": "3000.00",
            "description": "منطقة المزة - دمشق"
        },
        "address": "123 Street",
        "isOnline": false,
        "isActive": true,
        "verifiedAt": "2026-06-17T10:00:00.000Z",
        "location": null,
        "lastLoginAt": "2026-06-17T10:00:00.000Z",
        "lastLoginIp": "192.168.1.100"
    }
}
```

### 1.4 شكل Payload كامل للتسجيل (Register) لكل دور

جميع الحقول اختيارية ما لم يذكر غير ذلك. الـ Content-Type هو `application/json` للتسجيل العادي.

#### CUSTOMER

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
    "address": "123 Street, Damascus",
    "notificationChannel": "FIREBASE",
    "birthday": "1990-01-01",
    "isOnline": false,
    "location": {
        "lat": 33.5138,
        "lng": 36.2765
    }
}
```

| الحقل | النوع | مطلوب | الوصف |
|:---|---:|:---:|:---|
| `email` | string | ✅ | البريد الإلكتروني |
| `password` | string | ✅ | كلمة المرور (6 أحرف كحد أدنى) |
| `firstName` | string | ✅ | الاسم الأول |
| `lastName` | string | ✅ | اسم العائلة |
| `phone` | string | ✅ | رقم الهاتف |
| `role` | string | ❌ | `CUSTOMER` (افتراضي) أو `MERCHANT` |
| `countryId` | number | ❌ | معرف الدولة |
| `cityId` | number | ❌ | معرف المدينة |
| `areaId` | number | ❌ | معرف المنطقة (جديد) |
| `address` | string | ❌ | العنوان |
| `notificationChannel` | enum | ❌ | `FIREBASE` (افتراضي), `EMAIL`, `WHATSAPP`, `SMS` |
| `birthday` | string | ❌ | تاريخ الميلاد (YYYY-MM-DD) |
| `isOnline` | boolean | ❌ | حالة الاتصال |
| `location` | object | ❌ | `{ "lat": number, "lng": number }` |

#### MERCHANT

```json
{
    "email": "merchant@example.com",
    "password": "password123",
    "firstName": "Ahmad",
    "lastName": "Hassan",
    "phone": "+963912345678",
    "role": "MERCHANT",
    "countryId": 1,
    "cityId": 1,
    "areaId": 1,
    "address": "Merchant Street, Damascus",
    "notificationChannel": "FIREBASE",
    "birthday": "1985-03-15",
    "restaurantName": "مطعم البرغر اللذيذ",
    "description": "أشهى المأكولات الشرقية",
    "type": "RESTAURANT",
    "isOpen": true,
    "location": {
        "lat": 33.5138,
        "lng": 36.2765
    }
}
```

| الحقل | النوع | مطلوب | الوصف |
|:---|---:|:---:|:---|
| `email` | string | ✅ | البريد الإلكتروني |
| `password` | string | ✅ | كلمة المرور (6 أحرف كحد أدنى) |
| `firstName` | string | ✅ | الاسم الأول |
| `lastName` | string | ✅ | اسم العائلة |
| `phone` | string | ✅ | رقم الهاتف |
| `role` | string | ✅ | `MERCHANT` (مطلوب) |
| `countryId` | number | ❌ | معرف الدولة |
| `cityId` | number | ❌ | معرف المدينة |
| `areaId` | number | ❌ | معرف المنطقة (جديد) |
| `address` | string | ❌ | العنوان |
| `notificationChannel` | enum | ❌ | `FIREBASE` (افتراضي), `EMAIL`, `WHATSAPP`, `SMS` |
| `birthday` | string | ❌ | تاريخ الميلاد (YYYY-MM-DD) |
| `restaurantName` | string | ❌ | اسم المطعم (موصى به للتاجر) |
| `description` | string | ❌ | وصف المطعم |
| `type` | enum | ❌ | `RESTAURANT` (افتراضي), `STORE` |
| `isOpen` | boolean | ❌ | حالة فتح المحل |
| `location` | object | ❌ | `{ "lat": number, "lng": number }` |

#### DELIVERY (عبر Admin فقط — غير متاح للتسجيل العام)

```json
{
    "email": "driver@example.com",
    "password": "password123",
    "firstName": "Khalid",
    "lastName": "Ali",
    "phone": "+963987654321",
    "role": "DELIVERY",
    "countryId": 1,
    "cityId": 1,
    "areaId": 1,
    "address": "Delivery Street, Damascus",
    "notificationChannel": "FIREBASE",
    "birthday": "1995-07-20",
    "isOnline": true,
    "currentLat": 33.5138,
    "currentLng": 36.2765,
    "location": {
        "lat": 33.5138,
        "lng": 36.2765
    },
    "officeOwnerId": 10
}
```

| الحقل | النوع | مطلوب | الوصف |
|:---|---:|:---:|:---|
| `email` | string | ✅ | البريد الإلكتروني |
| `password` | string | ✅ | كلمة المرور (6 أحرف كحد أدنى) |
| `firstName` | string | ✅ | الاسم الأول |
| `lastName` | string | ✅ | اسم العائلة |
| `phone` | string | ✅ | رقم الهاتف |
| `role` | string | ✅ | `DELIVERY` (مطلوب) |
| `countryId` | number | ❌ | معرف الدولة |
| `cityId` | number | ❌ | معرف المدينة |
| `areaId` | number | ❌ | معرف المنطقة (جديد) |
| `address` | string | ❌ | العنوان |
| `notificationChannel` | enum | ❌ | `FIREBASE` (افتراضي), `EMAIL`, `WHATSAPP`, `SMS` |
| `birthday` | string | ❌ | تاريخ الميلاد (YYYY-MM-DD) |
| `isOnline` | boolean | ❌ | حالة الاتصال |
| `currentLat` | number | ❌ | خط العرض الحالي |
| `currentLng` | number | ❌ | خط الطول الحالي |
| `location` | object | ❌ | `{ "lat": number, "lng": number }` |
| `officeOwnerId` | number | ❌ | معرف صاحب المكتب (لربط السائق) |

> **ملاحظة:** DELIVERY لا يمكنه التسجيل عبر `/auth/register` العام. يتم إنشاؤه عبر Admin أو Office Owner من `/users/deliveries`.

### 1.5 واجب الـ Frontend

- إضافة `areaId` إلى تسجيل المستخدم الجديد (اختياري)
- إظهار المنطقة (Area name) في الملف الشخصي (Profile) إذا كانت موجودة
- **Admin Panel**: إضافة حقل اختيار المنطقة عند إنشاء/تعديل أي مستخدم

---

## 2. تغيير القناة الافتراضية للإشعارات

### 2.1 الوصف

القناة الافتراضية عند تسجيل مستخدم جديد تغيرت من `WHATSAPP` إلى `FIREBASE`.

| | قبل | بعد |
|:---|---:|:---:|
| **القناة الافتراضية** | `WHATSAPP` | `FIREBASE` |

### 2.2 التأثير

- المستخدمين الجدد سيستلمون OTP عبر Firebase (إذا كان `firebaseToken` موجودًا) أو عبر Email
- Admin لا يزال بإمكانه اختيار أي قناة عند إنشاء المستخدمين يدويًا
- **OTP عبر WhatsApp لا يزال مدعومًا** — إذا اختار المستخدم `WHATSAPP` كقناة، سيستلم OTP عبر واتساب طبيعي

### 2.3 واجب الـ Frontend

1. **طلب الإذن (permission)** لإشعارات Firebase فور التسجيل
2. **إرسال `firebaseToken`** إلى `PATCH /auth/firebase-token` بعد الحصول عليه
3. **اختيار القناة**: إذا لم يختر المستخدم قناة محددة، سيتم استخدام `FIREBASE` افتراضيًا
4. **لا تغيير** على واجهة اختيار القناة — المستخدم لا يزال يملك `notificationChannel` في الملف الشخصي ويمكنه تغييره

---

## 3. إلغاء رسالة الترحيب عبر WhatsApp بعد التحقق

### 3.1 الوصف

بعد التحقق من الحساب (Verify Account)، لم يعد يتم إرسال رسالة ترحيب عبر WhatsApp. الإيميل هو القناة الوحيدة للترحيب حاليًا.

| | قبل | بعد |
|:---|---:|:---:|
| **بعد التحقق** (DELIVERY/MERCHANT) | WhatsApp Welcome | لا رسالة ترحيب فورية |
| **بعد التفعيل من ADMIN** (Confirm Merchant) | WhatsApp Welcome | Firebase Notification + Email (حسب قناة المستخدم) |

### 3.2 التأثير على الـ Frontend

- **لا تغيير** — الـ Frontend لا يتعامل مع رسائل الترحيب مباشرة
- **ملاحظة**: إذا كان هناك أي نص في الـ UI مثل "سيتم إرسال رسالة ترحيب إلى واتسابك"، قم بإزالته

---

## 4. ملخص الحقول الجديدة والمعدلة

| الحقل | مكان الظهور | النوع | مطلوب؟ | ملاحظة |
|:---|---:|:---:|:---:|:---|
| `areaId` | Request (Register) | number | No | معرف المنطقة عند التسجيل |
| `areaId` | Response (User) | number or null | — | يظهر في Login, Profile, CRUD لجميع الأدوار |
| `area` | Response (User) | object or null | — | كائن المنطقة كامل |
| `notificationChannel` | Request (Register) | enum | No | القيمة الافتراضية: `FIREBASE` (تغيرت من `WHATSAPP`) |

---

## 5. Areas API — جلب المناطق أصبح عامًا + Redis Caching

### 5.1 الوصف

أصبحت endpoints جلب المناطق (`GET /areas` و `GET /areas/:id`) **عامة (Public)** — لا تحتاج JWT توكن. هذا يتوافق مع نفس pattern الـ Countries و Cities.

تمت إضافة **Redis Caching** لتحسين الأداء وتقليل الضغط على قاعدة البيانات.

| الـ Endpoint | قبل | بعد |
|:---|---:|:---:|
| `GET /areas` | يتطلب JWT | **عام (Public)** + Redis Cache (10 دقائق) |
| `GET /areas/:id` | يتطلب JWT | **عام (Public)** + Redis Cache (10 دقائق) |
| `POST /areas` | Admin فقط | Admin فقط (لا تغيير) |
| `PATCH /areas/:id` | Admin فقط | Admin فقط (لا تغيير) |
| `DELETE /areas/:id` | Admin فقط | Admin فقط (لا تغيير) |

### 5.2 آلية الـ Redis Caching

- **`GET /areas`**: يتم تخزين نتيجة الـ query في Redis لمدة **10 دقائق** (600 ثانية)
  - مفتاح الـ cache: `areas:list:{page}:{limit}:{search}:{min_price}:{max_price}`
  - عند تعديل أو إضافة أو حذف منطقة → يتم مسح cache الـ list
- **`GET /areas/:id`**: يتم تخزين المنطقة في Redis لمدة **10 دقائق**
  - مفتاح الـ cache: `areas:{id}`
  - عند تعديل أو حذف المنطقة → يتم مسح cache الخاص بها
- **`POST /areas`**: بعد الإنشاء → مسح `areas:list:*`
- **`PATCH /areas/:id`**: بعد التعديل → مسح `areas:list:*` + `areas:{id}`
- **`DELETE /areas/:id`**: بعد الحذف → مسح `areas:list:*` + `areas:{id}`

### 5.3 التأثير على الـ Frontend

- **لا يحتاج الـ Frontend إلى JWT توكن** لجلب المناطق بعد الآن
- يمكن جلب المناطق حتى قبل تسجيل الدخول (مفيد لصفحات إنشاء الطلب للزوار)
- **البيانات مؤقتة (cached)** — إذا تم تعديل منطقة من Admin Panel، قد يبقى cache لمدة تصل إلى 10 دقائق
- لجلب البيانات الحديثة فورًا بعد تعديل منطقة، يمكن للمستخدم إعادة تحميل الصفحة (سيتم مسح cache تلقائيًا عند التعديل)

### 5.4 واجب الـ Frontend

- **إزالة شرط JWT** من طلبات `GET /areas` و `GET /areas/:id`
- يمكن الآن جلب المناطق في أي وقت (حتى بدون تسجيل دخول)
- **تخزين مؤقت (Caching)**: cache في localStorage لمدة 10 دقائق اختياري — الـ API نفسه يستخدم Redis caching

---

## 6. Admin Panel — التحديثات

### 6.1 إنشاء/تعديل المستخدمين

- **إضافة** حقل `areaId` في نماذج إنشاء وتعديل جميع الأدوار (CUSTOMER, DELIVERY, MERCHANT, ADMIN)
- القناة الافتراضية أصبحت `FIREBASE` — لكن ADMIN يمكنه اختيار أي قناة أخرى

### 6.2 شكل Request الجديد (Create User by Admin)

```json
{
    "email": "user@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "countryId": 1,
    "cityId": 1,
    "areaId": 1,
    "notificationChannel": "FIREBASE"
}
```

### 6.3 شكل Response الجديد (User)

```json
{
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "phone": "+963912345678",
    "role": "CUSTOMER",
    "notificationChannel": "FIREBASE",
    "countryId": 1,
    "country": {
        "id": 1,
        "name": "Syria",
        "code": "SY"
    },
    "cityId": 1,
    "city": {
        "id": 1,
        "name": "Damascus"
    },
    "areaId": 1,
    "area": {
        "id": 1,
        "name": "المزة",
        "price": "3000.00",
        "description": "منطقة المزة - دمشق"
    },
    "address": "123 Street",
    "isOnline": false,
    "isActive": true,
    "verifiedAt": "2026-06-17T10:00:00.000Z"
}
```

---

## 7. تحديث الملف الشخصي (Update Profile) — إضافة `areaId`

### 7.1 الوصف

تمت إضافة حقل `areaId` إلى **تحديث الملف الشخصي** (Update Profile — `PATCH /auth/profile`).

يمكن للمستخدم الآن تحديث منطقته (Area) من خلال إرسال `areaId` مع الـ profile update.

### 7.2 دوال التحديث الأخرى (Admin)

تمت إضافة `areaId` إلى جميع دوال التحديث الخاصة بالأدمن:

| الـ DTO | الملف |
|:---|---:|
| `UpdateUserAdminDto` | `auth/dto/update-user-admin.dto.ts` |
| `UpdateMerchantDto` | `auth/dto/update-merchant.dto.ts` |
| `UpdateDeliveryByOfficeDto` | `auth/dto/update-delivery-by-office.dto.ts` |
| `UpdateOfficeOwnerDto` | `auth/dto/update-office-owner.dto.ts` |

### 7.3 مثال Request (Update Profile مع areaId)

```json
{
    "firstName": "John",
    "countryId": 1,
    "cityId": 1,
    "areaId": 1,
    "address": "Updated Address"
}
```

### 7.4 آلية العمل

- جميع الـ services تستخدم `{ ...dto }` أو `Object.assign` مما يعني أن `areaId` يمر تلقائيًا إلى الـ User entity
- `ProfileService` يقوم بالتحقق من وجود المنطقة (`AreasService.findOne`)
- باقي الـ services (مثل UsersAdminService, OfficeOwnersService) يمررون `areaId` بدون تحقق إضافي (التأكد من وجود المنطقة يتم عند إدخال البيانات)

### 7.5 واجب الـ Frontend

- **Update Profile**: يمكن إرسال `areaId` كحقل اختياري عند update profile
- **Admin User Management**: عند تحديث مستخدم من لوحة التحكم، يمكن إرسال `areaId` كحقل اختياري
