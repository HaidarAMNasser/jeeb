# تقرير التنفيذ الأمني الشامل

## نظرة عامة

يوضح هذا المستند جميع المشاكل الأمنية التي تم تحديدها وإصلاحها في مشروع Delivery Jeeb Backend، بالإضافة إلى كيفية اختبار كل حماية.

---

## جدول المحتويات

1. [حماية Brute Force / Credential Stuffing](#1-حماية-brute-force--credential-stuffing)
2. [حماية DDoS / Layer 7 Flood](#2-حماية-ddos--layer-7-flood)
3. [أمان الطلبات (Request Security)](#3-أمان-الطلبات)
4. [حماية SQL Injection](#4-حماية-sql-injection)
5. [CORS لأجل تطبيقات Mobile](#5-cors-لأجل-تطبيقات-mobile)
6. [جدار الحماية متعدد الطبقات](#6-جدار-الحماية-متعدد-الطبقات)
7. [كيفية الاختبار](#7-كيفية-الاختبار)
8. [الحزم المستخدمة](#8-الحزم-المستخدمة)

---

## 1. حماية Brute Force / Credential Stuffing

### المشكلة

كانت الخدمة عرضة لهجمات brute force حيث يمكن للمهاجم تجربة آلاف كلمات المرور في دقيقة واحدة.

### الحل المُنفذ

#### 1.1 تتبع محاولات登录 الفاشلة (Redis)

- **الملف:** `src/common/services/login-attempt.service.ts`
- **الوصف:** يستخدم Redis لتتبع عدد المحاولات الفاشلة لكل بريد إلكتروني
- **الحد:** 5 محاولات فاشلة في 15 دقيقة
- **TTL:** 900 ثانية (15 دقيقة)

#### 1.2 حظر IP التلقائي

- **الملف:** `src/common/services/ip-block.service.ts`
- **الوصف:** يحظر الـ IP تلقائياً عند تجاوز 20 محاولة فاشلة
- **مدة الحظر:** 1 ساعة
- **القائمة البيضاء:** 127.0.0.1, ::1, localhost

#### 1.3 حظر الحساب المتدرج

- **الملف:** `src/database/entities/login-block.entity.ts`
- **الوصف:** جدول جديد لتتبع حظر الحسابات في قاعدة البيانات

| مستوى الحظر | المدة   | الشرط     |
| ----------- | ------- | --------- |
| المستوى 1   | 24 ساعة | أول حظر   |
| المستوى 2   | أسبوع   | ثاني حظر  |
| المستوى 3   | شهر     | ثالث حظر  |
| المستوى 4   | سنة     | رابع حظر  |
| المستوى 5   | دائم    | خامس حظر+ |

#### 1.4 إشعارات الأمان

- **الملف:** `src/modules/notifications/security-notification.service.ts`
- **الوصف:** إرسال إشعارات للمستخدم عند:
  - محاولة تسجيل دخول فاشلة
  - قفل الحساب
  - فتح الحساب
  - تسجيل دخول من جهاز جديد

#### 1.5 APIs管理员 للتحكم

- **الملف:** `src/modules/auth/controllers/admin-security.controller.ts`
- **الوصف:** واجهات برمجة تطبيقات للتحكم بالحظر:
  - `GET /api/v1/admin/security/blocks` - عرض جميع الحظر النشطة
  - `POST /api/v1/admin/security/unblock` - فتح حساب محظور
  - `POST /api/v1/admin/security/block-ip` - حظر IP
  - `POST /api/v1/admin/security/unblock-ip` - فتح IP محظور

---

## 2. حماية DDoS / Layer 7 Flood

### المشكلة

كان التطبيق عرضة لهجمات DDoS التي ترسل آلاف الطلبات لاستنزاف الموارد.

### الحل المُنفذ

#### 2.1 NestJS Throttler مع Redis

- **الملف:** `src/app.module.ts`
- **الحزمة:** `@nestjs/throttler` + `@nest-lab/throttler-storage-redis`
- **الوصف:** تحديدRate Limiting على مستوى التطبيق باستخدام Redis لدعم_multiple PM2 instances

##### الـ Throttlers المُفعّلين:

| الاسم         | TTL     | الحد          | الاستخدام      |
| ------------- | ------- | ------------- | -------------- |
| default       | 1 دقيقة | 30 طلب/دقيقة  | عام            |
| get           | 1 دقيقة | 50 طلب/دقيقة  | GET requests   |
| long          | 1 ساعة  | 600 طلب/ساعة  | عمليات ثقيلة   |
| auth-login    | 1 دقيقة | 5 طلبات/دقيقة | /auth/login    |
| auth-register | 1 دقيقة | 3 طلبات/دقيقة | /auth/register |
| search        | 1 دقيقة | 30 طلب/دقيقة  | /search        |
| upload        | 1 دقيقة | 5 طلبات/دقيقة | /upload        |

#### 2.2 تطبيق_limits على Controllers

| Controller      | الملف                                                   | الحد   |
| --------------- | ------------------------------------------------------- | ------ |
| Auth (login)    | `src/modules/auth/auth.controller.ts`                   | 5/min  |
| Auth (register) | `src/modules/auth/auth.controller.ts`                   | 3/min  |
| Global Search   | `src/modules/global-search/global-search.controller.ts` | 30/min |
| Orders (create) | `src/modules/orders/orders.controller.ts`               | 20/min |
| Cart            | `src/modules/cart/cart.controller.ts`                   | 30/min |
| Products        | `src/modules/products/products.controller.ts`           | 50/min |

#### 2.3 Nginx Rate Limiting

- **ملف التكوين:** `/etc/nginx/nginx.conf`
- **ملف الموقع:** `/etc/nginx/sites-available/api.jeeb2.com`

##### Zones المُفعّلين:

| Zone         | Rate      | Burst | المسارات                       |
| ------------ | --------- | ----- | ------------------------------ |
| api_limit    | 30req/sec | 20    | /api/\*                        |
| auth_limit   | 10req/sec | 10    | /api/v1/auth/login, register   |
| upload_limit | 5req/sec  | 5     | /api/v1/auth/profile, products |
| search_limit | 20req/sec | 15    | /api/v1/search, global-search  |
| conn_limit   | 10conn    | -     | Connection limiting per IP     |

#### 2.4 Fail2Ban

- **الملف:** `/etc/fail2ban/jail.local`
- **الوصف:** حظر تلقائي للـ IPs المشبوهة

##### Jail Configuration:

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
maxretry = 5
```

---

## 3. أمان الطلبات (Request Security)

### الحل المُنفذ

#### 3.1 Helmet Headers

- **الملف:** `src/main.ts`
- **الحزمة:** `helmet`
- **الوصف:** إضافة headers حماية تلقائية

| Header                    | الوظيفة               |
| ------------------------- | --------------------- |
| X-Content-Type-Options    | منع MIME sniffing     |
| X-Frame-Options           | منع clickjacking      |
| X-XSS-Protection          | حماية XSS قديمة       |
| Strict-Transport-Security | 强制 HTTPS            |
| Content-Security-Policy   | منع XSS/Injection     |
| Referrer-Policy           | تحكم بالمسار          |
| Permissions-Policy        | تحكم بالـ permissions |

#### 3.2 Nginx Security Headers

- **الملف:** `/etc/nginx/nginx.conf`
- **الوصف:** إضافة headers أمنية على مستوى Nginx

| Header                    | القيمة                                       |
| ------------------------- | -------------------------------------------- |
| X-Frame-Options           | SAMEORIGIN                                   |
| X-Content-Type-Options    | nosniff                                      |
| X-XSS-Protection          | 1; mode=block                                |
| Referrer-Policy           | strict-origin-when-cross-origin              |
| Permissions-Policy        | geolocation=(), microphone=(), camera=()     |
| Strict-Transport-Security | max-age=31536000; includeSubDomains; preload |

#### 3.3 CORS للـ Flutter Mobile

- **الملف:** `src/main.ts`
- **الوصف:** إعداد CORS لتطبيقات Mobile

```typescript
app.enableCors({
  origin: [
    'app://*',
    'capacitor://*',
    'io.ionic*',
    'com.jeeb*',
    'http://localhost',
    'http://localhost:*',
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  credentials: true,
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'Accept',
    'Origin',
    'X-Requested-With',
    'X-Custom-Header',
  ],
});
```

##### Nginx CORS Configuration:

```nginx
set $cors_origin "";
if ($http_origin ~* "^app://|^capacitor://|^io\.ionic|^com\.jeeb|^http://localhost") {
    set $cors_origin $http_origin;
}

location ~* ^/api/ {
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin $cors_origin always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, PATCH, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, Accept, Origin, X-Requested-With, X-Custom-Header" always;
        add_header Access-Control-Max-Age 1728000;
        return 204;
    }
}
```

#### 3.4 حدود حجم الطلب (Body Size Limits)

- **الملف:** `src/main.ts` + Nginx

| النوع       | الحد         |
| ----------- | ------------ |
| JSON Body   | 100KB        |
| URL Encoded | 100KB        |
| File Upload | 10MB (Nginx) |

#### 3.5 طلب Timeout

- **الملف:** `src/common/middleware/request-timeout.middleware.ts`
- **الوصف:** إنهاء الطلبات التي تستغرق أكثر من 30 ثانية

#### 3.6 SSL/TLS Configuration

- **الوصف:** استخدام TLS 1.2/1.3 فقط

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;
```

---

## 4. حماية SQL Injection

### التحليل

تم تحليل الكود للتحقق من وجود ثغرات SQL Injection:

| التقنية               | الحالة | الوصف                                 |
| --------------------- | ------ | ------------------------------------- |
| TypeORM Query Builder | ✅ آمن | يستخدم parameterized queries تلقائياً |
| TypeORM Repositories  | ✅ آمن | يستخدم prepared statements            |
| class-validator       | ✅ آمن | يوفر input validation                 |
| ILIKE/LIKE            | ✅ آمن | يستخدم parameterized values           |

### النتيجة

**التطبيق محمي ضد SQL Injection** بفضل استخدام TypeORM مع parameterized queries.

---

## 5. CORS لأجل تطبيقات Mobile

### المشكلة

كان التطبيق لا يدعم CORS بشكل صحيح لتطبيقات Flutter Mobile.

### الحل المُنفذ

#### 5.1 Flutter Mobile Origins

- **app://\*** - Android Flutter apps
- **capacitor://\*** - Capacitor hybrid apps
- **io.ionic\*** - Ionic framework apps
- **com.jeeb\*** - Jeeb branded apps
- **http://localhost\*** - Development

#### 5.2 Preflight Handling

```nginx
location ~* ^/api/ {
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin $cors_origin always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, PATCH, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, Accept, Origin, X-Requested-With, X-Custom-Header" always;
        add_header Access-Control-Max-Age 1728000;
        return 204;
    }
}
```

---

## 6. جدار الحماية متعدد الطبقات

```
┌─────────────────────────────────────────────┐
│                الـ Client                    │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│         Layer 1: UFW Firewall               │
│         (SSH, HTTP, HTTPS only)             │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│         Layer 2: Nginx Rate Limiting        │
│    (30req/s API, 10req/s auth, 5req/s)     │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│      Layer 3: Fail2Ban (SSH + Nginx)       │
│   (SSH: 3 attempts → 24h ban)               │
│   (Nginx: 5 attempts → 1h ban)              │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│      Layer 4: NestJS Throttler (Redis)      │
│   (5/min login, 30/min search, إلخ)       │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│       Layer 5: Helmet + Body Limits         │
│   (Security Headers + 100KB max body)      │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│       Layer 6: CORS (Mobile Apps)           │
│   (Flutter Mobile + Web Apps)              │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│          Layer 7: Application Logic         │
│   (Brute Force Protection + Validation)     │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│          Layer 8: TypeORM + Database        │
│        (SQL Injection Protection)            │
└─────────────────────────────────────────────┘
```

---

## 7. كيفية الاختبار

### 7.1 اختبار CORS للـ Flutter Mobile

```bash
# اختبار Preflight request
curl -I -X OPTIONS https://api.jeeb2.com/api/v1/auth/profile \
  -H "Origin: app://jeeb-android" \
  -H "Access-Control-Request-Method: GET"

# النتيجة المتوقعة:
# Access-Control-Allow-Origin: app://jeeb-android
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
# Access-Control-Allow-Headers: Content-Type, Authorization, Accept, Origin
```

```bash
# اختبار مع Capacitor app
curl -I -X OPTIONS https://api.jeeb2.com/api/v1/orders \
  -H "Origin: capacitor://localhost" \
  -H "Access-Control-Request-Method: GET"
```

### 7.2 اختبار Security Headers

```bash
# التحقق من وجود_headers الأمنية
curl -I https://api.jeeb2.com/api/v1/auth/profile

# يجب أن تتضمن:
# - X-Frame-Options: SAMEORIGIN
# - X-Content-Type-Options: nosniff
# - X-XSS-Protection: 1; mode=block
# - Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
# - Referrer-Policy: strict-origin-when-cross-origin
```

### 7.3 اختبار Brute Force Protection

```bash
# اختبار محاولة تسجيل دخول فاشلة متعددة
for i in {1..6}; do
  curl -X POST https://api.jeeb2.com/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrongpassword"}'
  echo "Attempt $i"
done

# النتيجة المتوقعة:
# المحاولات 1-5: response طبيعي (invalid credentials)
# المحاولة 6: HTTP 429 أو 403 مع رسالة "Too many attempts"
```

### 7.4 اختبار DDoS Protection

```bash
# اختبار NestJS Throttler
for i in {1..15}; do
  curl -I https://api.jeeb2.com/api/v1/auth/login
done

# النتيجة: HTTP 429 بعد 5 طلبات
```

```bash
# اختبار Nginx Rate Limiting (إذا تجاوز NestJS)
for i in {1..30}; do
  curl -I https://api.jeeb2.com/api/v1/auth/login
done

# النتيجة: HTTP 503 بعد تجاوز الحد
```

### 7.5 اختبار Fail2Ban

```bash
# التحقق من حالة Fail2Ban
fail2ban-client status

# النتيجة:
# Status
# |- Number of jail:  2
# `- Jail list: nginx-http-auth, sshd
```

```bash
# عرض الـ banned IPs
fail2ban-client status sshd
fail2ban-client status nginx-http-auth
```

### 7.6 اختبار Body Size Limits

```bash
# اختبار تجاوز حد JSON (100KB)
curl -X POST https://api.jeeb2.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"data":"'$(python3 -c 'print("x"*101000))'"}'

# النتيجة: HTTP 413 Payload Too Large
```

### 7.7 اختبار Request Timeout

```bash
# النتيجة: HTTP 408 Request Timeout بعد 30 ثانية
# (يتطلب endpoint يدعم طلبات طويلة)
```

---

## 8. الحزم المستخدمة

### الحزم الجديدة المُضافة:

| الحزمة                              | الإصدار | الغرض                       |
| ----------------------------------- | ------- | --------------------------- |
| `@nest-lab/throttler-storage-redis` | ^1.2.0  | Redis storage للـ Throttler |
| `helmet`                            | ^8.0.0  | headers حماية أمنية         |
| `@nestjs/schedule`                  | ^6.1.1  | Cron jobs للـ timeouts      |

### الحزم المعدلة:

| الحزمة              | الإصدار | ملاحظات                |
| ------------------- | ------- | ---------------------- |
| `@nestjs/throttler` | ^6.5.0  | مفعّل مع Redis storage |
| `pg`                | ^8.18.0 | PostgreSQL driver      |

---

## ملاحظات للتشغيل

### التحقق من عمل Nginx Rate Limiting:

```bash
nginx -t
systemctl reload nginx
```

### التحقق من عمل Fail2Ban:

```bash
systemctl status fail2ban
fail2ban-client status
```

### التحقق من Firewall:

```bash
ufw status verbose
```

### إعادة تشغيل التطبيق:

```bash
# باستخدام PM2
cd /root/var/www/src_v1/Jeeb_NestJs
pm2 restart delivery-jeeb
pm2 logs delivery-jeeb --lines 20
```

---

## الخلاصة

| المشكلة الأمنية                   | الحالة  | الطبقة                 |
| --------------------------------- | ------- | ---------------------- |
| Brute Force / Credential Stuffing | ✅ محمي | Application + Fail2Ban |
| DDoS / Layer 7 Flood              | ✅ محمي | Nginx + NestJS         |
| Request Security                  | ✅ محمي | Application (Helmet)   |
| SQL Injection                     | ✅ آمن  | Database (TypeORM)     |
| Large Payload Attack              | ✅ محمي | Application + Nginx    |
| Slowloris Attack                  | ✅ محمي | Application (Timeout)  |
| CORS (Mobile Apps)                | ✅ محمي | Application + Nginx    |

---

## معلومات السيرفر

| العنصر           | القيمة                           |
| ---------------- | -------------------------------- |
| Server IP        | 187.124.28.146                   |
| Domain           | api.jeeb2.com                    |
| SSL Certificate  | Let's Encrypt                    |
| Application Path | /root/var/www/src_v1/Jeeb_NestJs |
| PM2 Process      | delivery-jeeb                    |

---

**تاريخ الإنشاء:** 03 أبريل 2026
**آخر تحديث:** 08 أبريل 2026
**الإصدار:** 2.0.0
