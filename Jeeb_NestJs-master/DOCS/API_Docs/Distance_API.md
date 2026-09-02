# Distance API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## نظرة عامة

يسمح هذا الـ module بحساب المسافات وتكاليف التوصيل بين المواقع الجغرافية باستخدام **خوارزمية هيفرسين (Haversine Formula)**.

- **المسار:** `/distance`
- **الإعدادات:** `deliveryTipPerKilometer` (سعر الكيلومتر الواحد)، `defaultProductCommissionRate` (نسبة عمولة الوسيط)
- **المصادقة:** مطلوبة (Bearer Token) — أي مستخدم مصادق عليه يمكنه الوصول (بدون تقييد دور)

يتم تحميل الإعدادات من `SettingsService` عند بدء التطبيق (في `onModuleInit`). إذا تعذر التحميل، تُستخدم القيم الافتراضية.

---

## 1. Calculate Distance

حساب المسافة بين نقطتين مع تقدير البقشيش.

- **URL:** `/distance/calculate`
- **Method:** `POST`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** None (أي مستخدم مصادق عليه)

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Request Body

| Parameter | Type | Required | Description |
| :------------------ | :----- | :------- | :-------------- |
| `source` | object | Yes | نقطة البداية |
| `source.lat` | Number | Yes | خط العرض. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `source.lng` | Number | Yes | خط الطول. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `destination` | object | Yes | نقطة النهاية |
| `destination.lat` | Number | Yes | خط العرض. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `destination.lng` | Number | Yes | خط الطول. Validation: `@IsNumber()` `@IsNotEmpty()` |

### Request Example

```json
{
  "source": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "destination": {
    "lat": 33.515,
    "lng": 36.28
  }
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "distance": 1500,
    "distanceUnit": "meters",
    "distanceKm": 1.5,
    "calculationMethod": "HAVERSINE",
    "estimatedTip": 750,
    "tipCalculation": {
      "tipPerKilometer": 500,
      "distanceKm": 1.5,
      "calculatedTip": 750
    }
  },
  "timestamp": "2026-03-19T10:00:00.000Z",
  "path": "/api/v1/distance/calculate"
}
```

### Response Fields Description

| Field | Type | Description |
| :---------------------------- | :----- | :------------------------------ |
| `distance` | Number | المسافة بالمتر |
| `distanceUnit` | String | وحدة المسافة (`meters`) |
| `distanceKm` | Number | المسافة بالكيلومتر (مقرب لأقرب منزلتين) |
| `calculationMethod` | String | طريقة الحساب (`HAVERSINE`) |
| `estimatedTip` | Number | البقشيش المقدر (`distanceKm × tipPerKilometer`) |
| `tipCalculation.tipPerKilometer` | Number | سعر الكيلومتر (من الإعدادات) |
| `tipCalculation.distanceKm` | Number | المسافة بالكيلومتر |
| `tipCalculation.calculatedTip` | Number | البقشيش المحسوب |

### Response (Error - 400 Bad Request)

```json
{
  "statusCode": 400,
  "message": ["destination.lat must be a number"],
  "error": "Bad Request"
}
```

---

## 2. Calculate Delivery Cost

حساب تكلفة التوصيل من موقع التاجر إلى موقع العميل مع إمكانية إضافة المنتجات.

- **URL:** `/distance/calculate-delivery-cost`
- **Method:** `POST`
- **Auth Required:** Yes (Bearer Token)
- **Roles Required:** None (أي مستخدم مصادق عليه)

### Headers

| Header | Required | Description |
| :----- | :------- | :---------- |
| `Authorization` | Yes | Bearer `{token}` |

### Request Body

| Parameter | Type | Required | Description |
| :--------------------- | :----- | :------- | :-------------- |
| `merchantId` | Number | Yes | معرف التاجر. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `destination` | object | Yes | إحداثيات العميل |
| `destination.lat` | Number | Yes | خط العرض. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `destination.lng` | Number | Yes | خط الطول. Validation: `@IsNumber()` `@IsNotEmpty()` |
| `products` | Array | No | قائمة المنتجات |
| `products[].productId` | Number | Yes* | معرف المنتج (*مطلوب إذا وجدت المصفوفة). Validation: `@IsNumber()` `@IsNotEmpty()` |
| `products[].quantity` | Number | Yes* | الكمية (*مطلوب إذا وجدت المصفوفة). Validation: `@IsNumber()` `@IsNotEmpty()` |

### Request Example (بدون منتجات)

```json
{
  "merchantId": 30114,
  "destination": {
    "lat": 33.5138,
    "lng": 36.2765
  }
}
```

### Request Example (مع منتجات)

```json
{
  "merchantId": 30114,
  "destination": {
    "lat": 33.5138,
    "lng": 36.2765
  },
  "products": [
    { "productId": 101, "quantity": 2 },
    { "productId": 102, "quantity": 1 }
  ]
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "tipPerKilometer": 500,
    "mediatorCommissionRate": 10,
    "merchant": {
      "id": 30114,
      "firstName": "حيدر",
      "lastName": "نبيل",
      "restaurantName": "مطعم تازا",
      "phone": "646464664",
      "location": {
        "lat": 35.3659335,
        "lng": 35.9443132
      }
    },
    "products": [
      {
        "id": 101,
        "name": "شاورما دجاج",
        "categoryId": 5,
        "merchantId": 30114,
        "price": 1000,
        "discount": 10,
        "discountType": "PERCENTAGE",
        "priceAfterDiscount": 900,
        "finalPrice": 900,
        "quantity": 2,
        "itemTotal": 1800,
        "images": [
          {
            "id": 1,
            "url": "products/101/image.webp",
            "mobileUrl": "products/101/mobile/image.webp",
            "thumbnailUrl": "products/101/thumb/image.webp",
            "isMain": true
          }
        ]
      },
      {
        "id": 102,
        "name": "عصير برتقال",
        "categoryId": 8,
        "merchantId": 30114,
        "price": 2000,
        "discount": 0,
        "discountType": null,
        "priceAfterDiscount": 2000,
        "finalPrice": 2000,
        "quantity": 1,
        "itemTotal": 2000,
        "images": []
      }
    ],
    "productsTotal": 3800,
    "distance": 5200,
    "distanceKm": 5.2,
    "deliveryCost": 2340,
    "mediatorCommission": 260,
    "deliveryCostWithCommission": 2600,
    "grandTotal": 6400,
    "destination": {
      "lat": 33.5138,
      "lng": 36.2765
    }
  },
  "timestamp": "2026-03-19T10:00:00.000Z",
  "path": "/api/v1/distance/calculate-delivery-cost"
}
```

### Response Fields Description

| Field | Type | Description |
| :----------------------------------- | :----- | :-------------------------------------------------------------------- |
| `tipPerKilometer` | Number | سعر الكيلومتر (من الإعدادات: `deliveryTipPerKilometer`) |
| `mediatorCommissionRate` | Number | نسبة عمولة الوسيط (من الإعدادات: `defaultProductCommissionRate`) |
| `merchant` | Object | معلومات التاجر |
| `merchant.id` | Number | معرف التاجر |
| `merchant.firstName` | String | الاسم الأول |
| `merchant.lastName` | String | الاسم الأخير |
| `merchant.restaurantName` | String | اسم المطعم |
| `merchant.phone` | String | رقم الهاتف |
| `merchant.location` | Object | موقع التاجر (من حقل `location` في جدول `users`) |
| `merchant.location.lat` | Number | خط العرض |
| `merchant.location.lng` | Number | خط الطول |
| `products` | Array | قائمة المنتجات مع تفاصيلها |
| `products[].id` | Number | معرف المنتج |
| `products[].name` | String | اسم المنتج |
| `products[].categoryId` | Number | معرف التصنيف |
| `products[].merchantId` | Number | معرف صاحب المنتج (التاجر) |
| `products[].price` | Number | السعر الأصلي |
| `products[].discount` | Number | نسبة/قيمة الخصم |
| `products[].discountType` | String | نوع الخصم (`PERCENTAGE` / `FIXED` / `null`) |
| `products[].priceAfterDiscount` | Number | السعر بعد الخصم |
| `products[].finalPrice` | Number | السعر النهائي (يساوي `priceAfterDiscount`) |
| `products[].quantity` | Number | الكمية |
| `products[].itemTotal` | Number | المجموع (`finalPrice × quantity`) |
| `products[].images` | Array | صور المنتج |
| `products[].images[].id` | Number | معرف الصورة |
| `products[].images[].url` | String | رابط الصورة الأصلي |
| `products[].images[].mobileUrl` | String | رابط صورة الموبايل |
| `products[].images[].thumbnailUrl` | String | رابط الصورة المصغرة |
| `products[].images[].isMain` | Boolean | هل هي الصورة الرئيسية |
| `productsTotal` | Number | مجموع أسعار المنتجات (`∑ itemTotal`) |
| `distance` | Number | المسافة بالمتر |
| `distanceKm` | Number | المسافة بالكيلومتر (مقرب لأقرب منزلتين) |
| `deliveryCost` | Number | تكلفة التوصيل بعد خصم عمولة الوسيط (`originalDeliveryCost - mediatorCommission`) |
| `mediatorCommission` | Number | عمولة الوسيط (`originalDeliveryCost × mediatorCommissionRate / 100`) |
| `deliveryCostWithCommission` | Number | تكلفة التوصيل قبل خصم العمولة (`distanceKm × tipPerKilometer`) |
| `grandTotal` | Number | المجموع الكلي (`productsTotal + deliveryCostWithCommission`) |
| `destination` | Object | موقع العميل |

### Response (Error - 404 Not Found — Merchant)

```json
{
  "statusCode": 404,
  "message": "Merchant with ID 99999 not found",
  "error": "Not Found"
}
```

### Response (Error - 404 Not Found — Location)

```json
{
  "statusCode": 404,
  "message": "Merchant location not found for ID 30114",
  "error": "Not Found"
}
```

### Response (Error - 404 Not Found — Product)

```json
{
  "statusCode": 404,
  "message": "Product with ID 999 not found",
  "error": "Not Found"
}
```

---

## 3. الإعدادات (Settings)

### deliveryTipPerKilometer

| الخاصية | القيمة الافتراضية | الوصف |
| :---------------------- | :-------------- | :------------------------------ |
| `deliveryTipPerKilometer` | `500` | سعر الكيلومتر الواحد للتوصيل (بـ SYP) |

### defaultProductCommissionRate

| الخاصية | القيمة الافتراضية | الوصف |
| :-------------------------- | :-------------- | :-------------------------------- |
| `defaultProductCommissionRate` | `10.0` | نسبة عمولة الوسيط من تكلفة التوصيل (بـ %) |

**ملاحظة:** يمكن تعديل هذه القيم من خلال endpoint الإعدادات: `PATCH /api/v1/settings` (يتطلب دور `ADMIN`).

**تحميل الإعدادات:** يتم تحميل القيم عند بدء التطبيق عبر `SettingsService.getSettingByKey()`. إذا تعذر التحميل، تُستخدم القيم الافتراضية أعلاه.

---

## 4. طريقة الحساب (Haversine Formula)

### نظرة عامة

يستخدم النظام **خوارزمية هيفرسين** (Haversine Formula) لحساب المسافة بين نقطتين على سطح الأرض. جميع الحسابات تتم عبر `HaversineDistanceStrategy`.

### المعادلة

```
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)
c = 2 × atan2(√a, √(1-a))
d = R × c
```

حيث:

- `Δlat` = الفرق بين خطي العرض
- `Δlng` = الفرق بين خطي الطول
- `R` = نصف قطر الأرض (6371 كم)

### الكود (من `src/modules/distance/strategies/haversine-distance.strategy.ts`)

```typescript
const EARTH_RADIUS_M = 6371 * 1000; // Earth's radius in meters
const fromLat = toRadians(from.lat);
const fromLng = toRadians(from.lng);
const toLat = toRadians(to.lat);
const toLng = toRadians(to.lng);
const dLat = toLat - fromLat;
const dLng = toLng - fromLng;
const a =
  Math.sin(dLat / 2) * Math.sin(dLat / 2) +
  Math.cos(fromLat) *
    Math.cos(toLat) *
    Math.sin(dLng / 2) *
    Math.sin(dLng / 2);
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
const distanceInMeters = EARTH_RADIUS_M * c;
return Math.round(distanceInMeters);
```

### مثال عملي

```
مطعم: lat=35.3659335, lng=35.9443132
عميل: lat=33.5138, lng=36.2765

المسافة: 5.2 كم
سعر الكيلومتر: 500 SYP
نسبة العمولة: 10%

تكلفة التوصيل (قبل العمولة) = 5.2 × 500 = 2600 SYP
عمولة الوسيط = 2600 × 10% = 260 SYP
تكلفة التوصيل (بعد العمولة) = 2600 - 260 = 2340 SYP
```

---

## ملاحظات تقنية

1. **المصادقة:** يتطلب توثيق (Bearer Token) — يمكن الحصول عليه من endpoint `/login`. لا يتطلب دوراً محدداً (أي مستخدم مصادق عليه).
2. **طريقة الحساب:** يستخدم Haversine Formula لحساب المسافة (يتم تقريب النتيجة لأقرب متر صحيح).
3. **سعر التكلفة:** يعتمد على إعداد `deliveryTipPerKilometer` (افتراضي: 500 SYP).
4. **موقع التاجر:** يُؤخذ من حقل `location` في جدول `users` للتاجر (JSON: `{ lat, lng }`).
5. **الوحدة:** المسافة تُرجع بالمتر والكيلومتر.
6. **تحميل الإعدادات:** يتم تحميل سعر الكيلومتر ونسبة العمولة من `SettingsService` عند بدء التطبيق (`onModuleInit`).
7. **المنتجات:** يمكن تمرير قائمة بالمنتجات مع الكميات للحصول على تفاصيلها وحساب المجموع الكلي.
8. **عمولة الوسيط:** تُحسب من تكلفة التوصيل الأصلية × نسبة `defaultProductCommissionRate`.
9. **حساب الخصم:** إذا كان `discountType = PERCENTAGE`، يتم حساب الخصم كنسبة مئوية من السعر. إذا كان `FIXED`، يُطرح المبلغ مباشرة.
10. **تحويل البيانات:** يستخدم المتحكم `ValidationPipe({ transform: true, whitelist: true })` مع `@Type(() => ...)` لتحويل أنواع البيانات المتداخلة.
