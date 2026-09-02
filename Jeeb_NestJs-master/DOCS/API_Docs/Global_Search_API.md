# Global Search API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة

يسمح هذا الـ endpoint بالبحث الموحد في المنتجات والعروض والتجار من خلال طلب واحد.

- **URL:** `/search`
- **Method:** `GET`
- **Authentication:** Public (متاح للجميع)

---

## 1. Global Search

إرجاع نتائج البحث مقسمة إلى أقسام منفصلة.

- **URL:** `/search`
- **Method:** `GET`

### Query Parameters

| Parameter | Type   | Required | Description                       |
| --------- | ------ | -------- | --------------------------------- |
| `q`       | string | No       | نص البحث (اختياري — إذا كان فارغاً تعيد النتائج فارغة) |
| `page`    | number | No       | رقم الصفحة (افتراضي: 1)           |
| `limit`   | number | No       | عدد العناصر لكل قسم (افتراضي: 10) |

### ملاحظة

- كل قسم (products, offers, merchants) يحتوي على عدد `limit` من العناصر
- الـ `page` يطبق على جميع الأقسام معاً

### Request Example

```bash
GET /api/v1/search?q=pizza&page=1&limit=10
```

### Response Example (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "products": {
      "data": [
        {
          "id": 15,
          "name": {
            "ar": "بيتزا مارغريتا",
            "en": "Pizza Margherita"
          },
          "price": 50000,
          "image": "http://localhost:3000/uploads/products/15/image.webp",
          "merchantId": 1,
          "categoryId": 5
        }
      ],
      "pagination": {
        "total": 25,
        "page": 1,
        "limit": 10,
        "totalPages": 3,
        "hasNextPage": true,
        "hasPreviousPage": false
      }
    },
    "offers": {
      "data": [
        {
          "id": 3,
          "name": {
            "ar": "عرض البيتزا",
            "en": "Pizza Offer"
          },
          "discountValue": 20,
          "discountType": "PERCENTAGE",
          "merchantId": 1
        }
      ],
      "pagination": {
        "total": 10,
        "page": 1,
        "limit": 10,
        "totalPages": 1,
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    },
    "merchants": {
      "data": [
        {
          "id": 1,
          "name": "Pizza Hut",
          "email": "pizzahut@example.com",
          "phone": "+96391234567",
          "image": "http://localhost:3000/uploads/users/1/image.webp",
          "merchantId": 1
        }
      ],
      "pagination": {
        "total": 5,
        "page": 1,
        "limit": 10,
        "totalPages": 1,
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    }
  },
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 40,
    "totalPages": 4,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

### Response Example (Empty Search)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "products": {
      "data": [],
      "pagination": {
        "total": 0,
        "page": 1,
        "limit": 10,
        "totalPages": 0,
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    },
    "offers": {
      "data": [],
      "pagination": {
        "total": 0,
        "page": 1,
        "limit": 10,
        "totalPages": 0,
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    },
    "merchants": {
      "data": [],
      "pagination": {
        "total": 0,
        "page": 1,
        "limit": 10,
        "totalPages": 0,
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    }
  },
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 0,
    "totalPages": 0,
    "hasNextPage": false,
    "hasPreviousPage": false
  }
}
```

---

## 2. Pagination Structure

### Pagination لكل قسم

كل قسم يحتوي على `pagination` خاص به:

```json
"products": {
  "data": [...],
  "pagination": {
    "total": 25,        // عدد النتائج الإجمالي لهذا القسم
    "page": 1,          // الصفحة الحالية
    "limit": 10,        // عدد العناصر
    "totalPages": 3,   // عدد الصفحات الكلي لهذا القسم
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

### Pagination العام

يوجد في **المستوى الأعلى** من الاستجابة (بجانب `statusCode`, `message`, `data`):

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": { ... },
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 40,         // مجموع كل الأقسام
    "totalPages": 4,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

---

## 3. أقسام الاستجابة

### Products Section

```json
"products": {
  "data": [
    {
      "id": number,
      "name": { "ar": string, "en": string },
      "price": number,
      "image": string | null,
      "merchantId": number,
      "categoryId": number
    }
  ],
  "pagination": {...}
}
```

### Offers Section

```json
"offers": {
  "data": [
    {
      "id": number,
      "name": { "ar": string, "en": string },
      "discountValue": number,
      "discountType": "PERCENTAGE" | "FIXED",
      "merchantId": number
    }
  ],
  "pagination": {...}
}
```

### Merchants Section

```json
"merchants": {
  "data": [
    {
      "id": number,
      "name": string,
      "restaurantName": string | null,
      "type": "RESTAURANT" | "STORE",
      "email": string,
      "phone": string | undefined,
      "hidePhoneNumber": boolean,
      "image": string | null,
      "merchantId": number
    }
  ],
  "pagination": {...}
}
```

---

## ملاحظات تقنية

1. **الأقسام المدعومة:** Products, Offers, Merchants (تم إزالة Categories)
2. **توزيع النتائج:** كل قسم يحصل على عدد `limit` من العناصر بشكل مستقل
3. **عناوين الصور:** يتم إرجاع روابط الصور كاملة وجاهزة للعرض
4. **اللغات:** يتم إرجاع أسماء المنتجات والعروض ككائنات `{ "ar": string, "en": string }` (JSONB). أما أسماء التجار فهي نص عادي (string)
5. **شروط الظهور:**
   - التجار: يجب أن يكون الحساب مفعل ومحقق (`verifiedAt`)
   - المنتجات: يجب أن تكون العمولة مؤكدة (`commissionConfirmed`)
   - العروض: يجب أن تكون مفعلة (`isActive`)
