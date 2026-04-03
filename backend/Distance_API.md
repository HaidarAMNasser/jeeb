# Distance API Documentation

Base URL: `http://localhost:3000/api/v1`

---

## نظرة عامة

يسمح هذا الـ module بحساب المسافات وتكاليف التوصيل بين المواقع الجغرافية.

- **المسار:** `/distance`
- **الإعدادات:** `deliveryTipPerKilometer` (سعر الكيلومتر الواحد)

---

## 1. Calculate Distance

حساب المسافة بين نقطتين مع تقدير البقشيش.

- **URL:** `/distance/calculate`
- **Method:** `POST`
- **Authentication:** Required (Bearer Token)

### Request Body

| Parameter         | Type   | Required | Description  |
| ----------------- | ------ | -------- | ------------ |
| `source`          | object | Yes      | نقطة البداية |
| `source.lat`      | number | Yes      | خط العرض     |
| `source.lng`      | number | Yes      | خط الطول     |
| `destination`     | object | Yes      | نقطة النهاية |
| `destination.lat` | number | Yes      | خط العرض     |
| `destination.lng` | number | Yes      | خط الطول     |

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

### Response Example (Success - 200 OK)

```json
{
  "success": true,
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
  }
}
```

### Response Fields Description

| Field                            | Type   | Description                  |
| -------------------------------- | ------ | ---------------------------- |
| `distance`                       | number | المسافة بالمتر               |
| `distanceUnit`                   | string | وحدة المسافة (meters)        |
| `distanceKm`                     | number | المسافة بالكيلومتر           |
| `calculationMethod`              | string | طريقة الحساب (HAVERSINE)     |
| `estimatedTip`                   | number | البقشيش المقدر               |
| `tipCalculation.tipPerKilometer` | number | سعر الكيلومتر (من الإعدادات) |
| `tipCalculation.distanceKm`      | number | المسافة بالكيلومتر           |
| `tipCalculation.calculatedTip`   | number | البقشيش المحسوب              |

---

## 2. Calculate Delivery Cost

حساب تكلفة التوصيل من موقع التاجر إلى موقع العميل مع إمكانية إضافة المنتجات.

- **URL:** `/distance/calculate-delivery-cost`
- **Method:** `POST`
- **Authentication:** Required (Bearer Token)

### Request Body

| Parameter              | Type   | Required | Description     |
| ---------------------- | ------ | -------- | --------------- |
| `merchantId`           | number | Yes      | معرف التاجر     |
| `destination`          | object | Yes      | إحداثيات العميل |
| `destination.lat`      | number | Yes      | خط العرض        |
| `destination.lng`      | number | Yes      | خط الطول        |
| `products`             | array  | No       | قائمة المنتجات  |
| `products[].productId` | number | No       | معرف المنتج     |
| `products[].quantity`  | number | No       | الكمية          |

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
    { "productId": 102, "quantity": 1 },
    { "productId": 103, "quantity": 3 }
  ]
}
```

### Response Example (Success - 200 OK)

```json
{
  "success": true,
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
    "deliveryCost": 2600,
    "mediatorCommission": 260,
    "grandTotal": 6660,
    "destination": {
      "lat": 33.5138,
      "lng": 36.2765
    }
  }
}
```

### Response Fields Description

| Field                           | Type   | Description                                 |
| ------------------------------- | ------ | ------------------------------------------- |
| `tipPerKilometer`               | number | سعر الكيلومتر (من الإعدادات)                |
| `mediatorCommissionRate`        | number | نسبة عمولة الوسيط (من الإعدادات)            |
| `merchant`                      | object | معلومات التاجر                              |
| `merchant.id`                   | number | معرف التاجر                                 |
| `merchant.firstName`            | string | الاسم الأول                                 |
| `merchant.lastName`             | string | الاسم الأخير                                |
| `merchant.restaurantName`       | string | اسم المطعم                                  |
| `merchant.phone`                | string | رقم الهاتف                                  |
| `merchant.location`             | object | موقع التاجر                                 |
| `merchant.location.lat`         | number | خط العرض                                    |
| `merchant.location.lng`         | number | خط الطول                                    |
| `products`                      | array  | قائمة المنتجات مع تفاصيلها                  |
| `products[].id`                 | number | معرف المنتج                                 |
| `products[].name`               | string | اسم المنتج                                  |
| `products[].categoryId`         | number | معرف التصنيف                                |
| `products[].merchantId`         | number | معرف صاحب المنتج (التاجر)                   |
| `products[].price`              | number | السعر الأصلي                                |
| `products[].discount`           | number | نسبة/قيمة الخصم                             |
| `products[].discountType`       | string | نوع الخصم (PERCENTAGE/FIXED/null)           |
| `products[].priceAfterDiscount` | number | السعر بعد الخصم                             |
| `products[].finalPrice`         | number | السعر النهائي (بدون عمولة)                  |
| `products[].quantity`           | number | الكمية                                      |
| `products[].itemTotal`          | number | المجموع (السعر النهائي × الكمية)            |
| `products[].images`             | array  | صور المنتج                                  |
| `productsTotal`                 | number | مجموع أسعار المنتجات بعد الخصم              |
| `distance`                      | number | المسافة بالمتر                              |
| `distanceKm`                    | number | المسافة بالكيلومتر                          |
| `deliveryCost`                  | number | تكلفة التوصيل (المسافة × سعر الكيلومتر)     |
| `mediatorCommission`            | number | عمولة الوسيط (تكلفة التوصيل × نسبة العمولة) |
| `grandTotal`                    | number | المجموع الكلي (منتجات + توصيل + عمولة)      |
| `destination`                   | object | موقع العميل                                 |

### Response Example (Error - 404 Not Found - Merchant)

```json
{
  "success": false,
  "message": "Merchant with ID 99999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

### Response Example (Error - 404 Not Found - Location)

```json
{
  "success": false,
  "message": "Merchant location not found for ID 30114",
  "error": "Not Found",
  "statusCode": 404
}
```

### Response Example (Error - 404 Not Found - Product)

```json
{
  "success": false,
  "message": "Product with ID 999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## 3. الإعدادات (Settings)

### deliveryTipPerKilometer

| الخاصية                   | القيمة الافتراضية | الوصف                                 |
| ------------------------- | ----------------- | ------------------------------------- |
| `deliveryTipPerKilometer` | 500               | سعر الكيلومتر الواحد للتوصيل (بـ SYP) |

### defaultProductCommissionRate

| الخاصية                        | القيمة الافتراضية | الوصف                                     |
| ------------------------------ | ----------------- | ----------------------------------------- |
| `defaultProductCommissionRate` | 10.0              | نسبة عمولة الوسيط من تكلفة التوصيل (بـ %) |

**ملاحظة:** يمكن تعديل هذه القيم من خلال endpoint الإعدادات: `PATCH /api/v1/settings`

---

## 4. طريقة الحساب (Haversine Formula)

### نظرة عامة

يستخدم النظام **خوارزمية هيفرسين** (Haversine Formula) لحساب المسافة بين نقطتين على سطح الأرض.

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

### الكود

```typescript
const R = 6371; // Earth's radius in kilometers
const dLat = toRadians(lat2 - lat1);
const dLon = toRadians(lon2 - lon1);
const a =
  Math.sin(dLat / 2) * Math.sin(dLat / 2) +
  Math.cos(toRadians(lat1)) *
    Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
const distance = R * c; // Distance in kilometers
```

### مثال عملي

```
مطعم: lat=35.3659335, lng=35.9443132
عميل: lat=33.5138, lng=36.2765

المسافة: 5.2 كم
سعر الكيلومتر: 500 SYP

تكلفة التوصيل = 5.2 × 500 = 2600 SYP
```

---

## 5. رسائل الخطأ (Error Messages)

### 400 Bad Request - مدخلات غير صحيحة

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "destination.lat",
      "errors": ["destination.lat must be a number"]
    }
  ]
}
```

### 404 Not Found - التاجر غير موجود

```json
{
  "success": false,
  "message": "Merchant with ID 99999 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

### 404 Not Found - موقع التاجر غير موجود

```json
{
  "success": false,
  "message": "Merchant location not found for ID 30114",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## ملاحظات تقنية

1. **Authentication:** يتطلب توثيق (Bearer Token) - يمكن الحصول عليه من endpoint `/login`
2. **Method:** يستخدم Haversine Formula لحساب المسافة
3. **سعر التكلفة:** يعتمد على إعداد `deliveryTipPerKilometer`
4. **موقع التاجر:** يُؤخذ من حقل `location` في جدول `users` للتاجر
5. **الوحدة:** المسافة تُرجع بالمتر والكيلومتر
6. **الوقت الفعلي:** يتم تحميل سعر الكيلومتر ونسبة العمولة من الإعدادات عند بدء التطبيق
7. **المنتجات:** يمكن تمرير قائمة بالمنتجات مع الكميات للحصول على تفاصيلها وحساب المجموع الكلي
8. **عمولة الوسيط:** تُحسب من تكلفة التوصيل × نسبة `defaultProductCommissionRate`
