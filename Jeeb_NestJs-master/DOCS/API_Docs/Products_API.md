# Products API Documentation

Base URL: `http://localhost:3000/api/v1`

## نظرة عامة ودور الصلاحيات

- **ADMIN:** يمتلك صلاحيات كاملة: إنشاء/تعديل/حذف المنتجات لأي مطعم، ورؤية جميع المنتجات.
- **MERCHANT (صاحب مطعم):**
  - يرى فقط المنتجات التابعة لمطاعمه.
  - يمكنه إنشاء/تعديل/حذف منتجات مطاعمه فقط.
  - لا يمكنه التعديل/الحذف أو حذف صور منتج لا يملكه.

### حقل isFavorite

عند جلب المنتجات (GET `/products` أو GET `/products/:id`)، كل منتج يحتوي على حقل `isFavorite`:

- `true`: المنتج موجود في قائمة المفضلات للمستخدم المسجل
- `false`: المنتج غير موجود في المفضلة أو المستخدم غير مسجل

التحقق من الملكية والتنقيح موجود في الخدمة:

- التحقق من ملكية المطعم قبل الإنشاء [ProductsService.create](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L47-L52).
- التحقق من ملكية المنتج قبل التعديل/الحذف [ProductsService.update](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L174-L177) و[remove](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L220-L224) و[deleteImage](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L262-L269).
- التقسيم حسب الدور:
  - **CUSTOMER (عميل):** يرى فقط المنتجات التي يمتلك مطعمها حالة موافقة على العمولة (`commissionConfirmed = true`).
  - تقييد عرض المنتجات للتاجر: [ProductsService.findAll](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L100-L106).

الصور تُرفع عبر `FilesInterceptor('images', 5)` في المتحكم [ProductsController](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.controller.ts#L37) وتُعالَج في الخدمة [processAndSaveImages](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L289-L319).

التصنيف (Category):

- يتم التحقق من وجود التصنيف عبر `CategoriesService.findOne` عند الإنشاء والتحديث.
- التصنيفات تُنشأ وتُدار من قبل ADMIN فقط عبر `/categories` API.
- حقول التصنيف: `name`, `description`, `isActive`, `displayOrder`, `images`.

الأسعار:

- حقل `price` من نوع عدد صحيح (أصغر وحدة عملة). مثال: 1299 بدلاً من 12.99.

### ملاحظة حول حساب العمولة

**العمولة معطلة حالياً (commissionAmount = 0).** هذا يعني:

- `finalPrice = priceAfterDiscount` (بدون إضافة عمولة)
- `commissionAmount = 0` (لا توجد عمولة محسوبة)

في الكود (products.service.ts):

```typescript
// Commission is disabled - set to 0
const commissionAmount = 0;

// Final price equals price after discount (no commission added)
const finalPrice = priceAfterDiscount;
```

هذا يعني أن السعر النهائي الذي يدفعه العميل هو `priceAfterDiscount` مباشرة.

الحقول الخارجية (External Integration):

- عند `isExternal = false`: يتم تجاهل `externalProvider` و`externalId` ويُحفظان بقيم `null`.
- عند `isExternal = true`: يمكن تمريرهما واستخدامهما.
  - منطق الإنشاء/التحديث: [create](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L64-L77) و[update](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L210-L226).

المسارات معرفة في [api-routes.constants.ts](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/common/constants/api-routes.constants.ts#L21-L27).

---

## 1. Create Product

إنشاء منتج جديد.

- **URL:** `/products`
- **Method:** `POST`
- **Headers:**
  - `Authorization: Bearer <access_token>`
  - `Content-Type: multipart/form-data`

### Payload (FormData)

| Key                | Type   | Required    | Description                                      |
| ------------------ | ------ | ----------- | ------------------------------------------------ |
| `name`             | Text   | Yes         | اسم المنتج.                                      |
| `description`      | Text   | No          | وصف المنتج.                                      |
| `shortDescription` | Text   | No          | وصف قصير.                                        |
| `price`            | Text   | Yes         | السعر كعدد صحيح (أصغر وحدة).                     |
| `personCount`      | Text   | No          | عدد الأشخاص الذين يكفيهم المنتج (معلومات للعرض). |
| `merchantId`       | Text   | No          | معرف التاجر (يتم تعيينه تلقائياً من المستخدم).   |
| `categoryId`       | Text   | No          | التصنيف: MENU مرتبط بتاجر المنتج، CUISINE عام.   |
| `discount`         | Text   | No          | قيمة الحسم.                                      |
| `discountType`     | Text   | No          | نوع الحسم: `PERCENTAGE` أو `FIXED`.              |
| `hasStock`         | Text   | No          | `true`/`false`.                                  |
| `stockQuantity`    | Text   | Conditional | مطلوب إذا `hasStock = true`.                     |
| `isAvailable`      | Text   | No          | `true`/`false`.                                  |
| `isExternal`       | Text   | No          | `true`/`false`.                                  |
| `externalProvider` | Text   | Conditional | مطلوب فقط إذا `isExternal = true`.               |
| `externalId`       | Text   | Conditional | مطلوب فقط إذا `isExternal = true`.               |
| `images`           | File[] | No          | حتى 5 صور (jpg، png، webp).                      |

### Response (Success - 201 Created)

```json
{
  "statusCode": 201,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Delicious Burger",
    "description": "Juicy beef burger with cheese",
    "images": [
      {
        "id": 10,
        "url": "http://localhost:3000/uploads/products/1/xxx.webp",
        "mobileUrl": "http://localhost:3000/uploads/products/1/xxx_mobile.webp",
        "thumbnailUrl": "http://localhost:3000/uploads/products/1/xxx_thumb.webp",
        "isMain": true,
        "displayOrder": 0
      }
    ],
    "price": 1299,
    "priceAfterDiscount": 1170,
    "finalPrice": 1170,
    "commissionAmount": 0,
    "merchantId": 1,
    "categoryId": 1,
    "discount": 10,
    "discountType": "PERCENTAGE",
    "hasStock": true,
    "stockQuantity": 50,
    "isAvailable": true,
    "isExternal": false,
    "externalProvider": null,
    "externalId": null,
    "commissionRate": null,
    "commissionConfirmed": false,
    "createdAt": "2026-02-23T10:00:00.000Z",
    "updatedAt": "2026-02-23T10:00:00.000Z"
  },
  "timestamp": "2026-02-23T10:00:00.000Z",
  "path": "/api/v1/products"
}
```

### Response (Error - 403 Forbidden)

إذا كان التاجر لا يملك الحساب المرسل:

```json
{
  "message": "You do not own this merchant",
  "error": "Forbidden",
  "statusCode": 403
}
```

### ملاحظات

- يتم ضبط `merchantId` تلقائياً من مالك الحساب.
- معالجة الصور وإنتاج نسخ mobile/thumbnail تتم في الخدمة [processAndSaveImages](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts#L289-L319).

---

## 2. Get All Products (Filter & Search)

إرجاع قائمة المنتجات مع دعم الفلاتر والبحث والصفحات.

- **URL:** `/products`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`

### Query Parameters

| Parameter    | Description                                      |
| ------------ | ------------------------------------------------ |
| `page`       | رقم الصفحة (افتراضي: 1).                         |
| `limit`      | عدد العناصر في الصفحة (افتراضي: 10).             |
| `search`     | البحث بالاسم (يدعم العربية والإنجليزية).         |
| `categoryId` | الفلترة حسب التصنيف.                             |
| `merchantId` | الفلترة حسب معرف التاجر (متاح لجميع المستخدمين). |
| `minPrice`   | السعر الأدنى (عدد يعبر عن السعر).                |
| `maxPrice`   | السعر الأقصى (عدد يعبر عن السعر).                |
| `minRating`  | التقييم الأدنى (من 1 إلى 5).                     |

### سلوك الدور

- عند الدور MERCHANT، يعرض فقط منتجاته (`merchantId = user.id`).
- عند الدور ADMIN، يعرض جميع المنتجات.
- عند الدور CUSTOMER أو كزائر، يعرض فقط المنتجات التي `commissionConfirmed = true`.

### أمثلة الاستخدام

```bash
# فلتر حسب تاجر معين
GET /api/v1/products?merchantId=1

# فلتر مع فلترات أخرى
GET /api/v1/products?merchantId=1&minPrice=10&maxPrice=100

# مع البحث
GET /api/v1/products?merchantId=1&search=برجر

# مع التقييم
GET /api/v1/products?merchantId=1&minRating=4

# مع الصفحة
GET /api/v1/products?merchantId=1&page=1&limit=10
```

### ملاحظات الفلتر الجديد

- **merchantId** متاح لجميع المستخدمين (ADMIN, MERCHANT, CUSTOMER, الزوار)
- يمكن دمجه مع جميع الفلاتر الأخرى
- يقبل أرقام فقط
- اختياري وليس إجبارياً

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": [
    {
      "id": 1,
      "name": "Delicious Burger",
      "description": "Juicy beef burger with cheese",
      "price": 1299,
      "priceAfterDiscount": 1299,
      "finalPrice": 1299,
      "commissionAmount": 0,
      "merchantId": 1,
      "categoryId": 1,
      "hasStock": true,
      "stockQuantity": 50,
      "isAvailable": true,
      "isFavorite": true,
      "images": [
        {
          "id": 10,
          "url": "http://localhost:3000/uploads/products/1/xxx.webp",
          "isMain": true,
          "displayOrder": 0
        }
      ],
      "createdAt": "2026-02-23T10:00:00.000Z",
      "updatedAt": "2026-02-23T10:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "timestamp": "2026-02-23T10:00:00.000Z",
  "path": "/api/v1/products?page=1&limit=10"
}
```

### ملاحظة حول حقل isFavorite

- **isFavorite**: قيمة boolean indicating whether the product is in the authenticated user's favorites list.
  - إذا كان المستخدم **مسجلاً دخوله** (يملك token صالح): يرجع `true` إذا المنتج في المفضلة، `false` otherwise.
  - إذا كان المستخدم **غير مسجل** (بدون token): يرجع دائماً `false`.

---

## 3. Get One Product

- **URL:** `/products/:id`
- **Method:** `GET`
- **Headers:** `Authorization: Bearer <access_token>`

### Response (Success - 200 OK)

يشمل الصور والروابط المطلقة بعد المعالجة.

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Delicious Burger",
    "description": "Juicy beef burger with cheese",
    "images": [...],
    "price": 1299,
    "priceAfterDiscount": 1170,
    "finalPrice": 1170,
    "commissionAmount": 0,
    "merchantId": 1,
    "categoryId": 1,
    "hasStock": true,
    "stockQuantity": 50,
    "isAvailable": true,
    "isFavorite": false,
    "commissionRate": 10,
    "commissionConfirmed": true
  },
  "timestamp": "2026-02-23T10:00:00.000Z",
  "path": "/api/v1/products/1"
}
```

---

## 4. Update Product

تحديث منتج قائم. يدعم إضافة صور جديدة وتحديث ترتيب الصور وتعيين الصورة الرئيسية.

- **URL:** `/products/:id`
- **Method:** `PATCH`
- **Headers:**
  - `Authorization: Bearer <access_token>`
  - `Content-Type: multipart/form-data`

### Payload (FormData) — جميع الحقول اختيارية

| Key                | Type   | Description                                                                         |
| ------------------ | ------ | ----------------------------------------------------------------------------------- |
| `name`             | Text   | اسم جديد.                                                                           |
| `description`      | Text   | وصف جديد.                                                                           |
| `shortDescription` | Text   | وصف قصير جديد.                                                                      |
| `personCount`      | Text   | عدد الأشخاص الذين يكفيهم المنتج (معلومات للعرض).                                    |
| `price`            | Text   | سعر جديد كعدد صحيح.                                                                 |
| `stockQuantity`    | Text   | الكمية.                                                                             |
| `isAvailable`      | Text   | `true`/`false`.                                                                     |
| `hasStock`         | Text   | `true`/`false`.                                                                     |
| `categoryId`       | Text   | نقل المنتج لتصنيف جديد (MENU يجب أن يتبع للمطعم، CUISINE مسموح).                    |
| `discount`         | Text   | قيمة الحسم.                                                                         |
| `discountType`     | Text   | `PERCENTAGE` أو `FIXED`.                                                            |
| `isExternal`       | Text   | إذا `false` يتم تصفير الحقول الخارجية، إذا `true` يمكن تمريرها.                     |
| `externalProvider` | Text   | عند `isExternal = true`.                                                            |
| `externalId`       | Text   | عند `isExternal = true`.                                                            |
| `imagesMetadata`   | Text   | نص JSON لتحديث ترتيب/الصورة الرئيسية: `[{"id":10,"isMain":true,"displayOrder":0}]`. |
| `images`           | File[] | إضافة صور جديدة تُلحق بنهاية الترتيب.                                               |
| `deleteImageIds`   | Text   | مصفوفة من أرقام معرفات الصور المراد حذفها: `[1,2,3]`.                               |

### تسلسل العمليات

1. **حذف الصور** (`deleteImageIds`): يتم حذف الصور المحددة أولاً.
2. **إضافة الصور** (`images`): يتم إضافة الصور الجديدة بنهاية الترتيب.
3. **تحديث الترتيب** (`imagesMetadata`): يتم تحديث ترتيب/الصورة الرئيسية.

#### مثال على payload كامل

```json
{
  "name": "اسم المنتج الجديد",
  "price": "15000",
  "imagesMetadata": "[{\"id\": 1, \"isMain\": true, \"displayOrder\": 0}, {\"id\": 2, \"isMain\": false, \"displayOrder\": 1}]",
  "deleteImageIds": "[3, 5]"
}
```

**الملفات (images):** يتم إرسالها كـ multipart/form-data

---

ملاحظة هامة: لا يمكن للمطعم (MERCHANT) تعديل حقلي نسبة العمولة (`commissionRate`) وحالة تأكيد العمولة (`commissionConfirmed`). يتم تعديلها من قبل الإدارة فقط عبر رابط مخصص.

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": { "id": 1, "name": "Updated", "isAvailable": true, "images": [ ... ] },
  "timestamp": "2026-02-23T10:05:00.000Z",
  "path": "/api/v1/products/1"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن التاجر مالكاً للمنتج/المطعم:

```json
{
  "message": "You do not own this product",
  "error": "Forbidden",
  "statusCode": 403
}
```

### Response (Error - 400 Bad Request)

أخطاء متعلقة بالصور:

```json
// صورة غير موجودة
{
  "message": "Image with ID 5 not found for this product",
  "error": "Bad Request",
  "statusCode": 400
}

// الصورة لا تنتمي للمنتج
{
  "message": "Image with ID 5 does not belong to product with ID 1",
  "error": "Bad Request",
  "statusCode": 400
}

// ليست صورة منتج
{
  "message": "Image with ID 5 is not a product image",
  "error": "Bad Request",
  "statusCode": 400
}
```

---

## 5. Delete Product

حذف منتج مع التعامل مع الطلبات والتقييمات والصور المرتبطة.

- **URL:** `/products/:id`
- **Method:** `DELETE`
- **Headers:** `Authorization: Bearer <access_token>`
- **Roles:** `MERCHANT`, `ADMIN`

### تسلسل الحذف

عند حذف منتج، تتم العمليات التالية بالترتيب:

1. **التحقق من الملكية**: التاجر يمكنه حذف منتجاته فقط.
2. **الطلبات**:
   - طلبات PENDING (غير مؤكدة): يتم حذف الـ order items المرتبطة بالمنتج.
   - باقي الطلبات (مؤكدة/ملغية/مكتملة): يتم وضع `productId = null`.
3. **الصور**: حذف صور المنتج من التخزين والقاعدة.
4. **التقييمات**: حذف جميع تقييمات المنتج.
5. **المنتج**: حذف المنتج نفسه.

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-02-23T10:06:00.000Z",
  "path": "/api/v1/products/1"
}
```

### Response (Error - 403 Forbidden)

إذا لم يكن التاجر مالكاً للمنتج:

```json
{
  "message": "You do not own this product",
  "error": "Forbidden",
  "statusCode": 403
}
```

### Response (Error - 404 Not Found)

```json
{
  "message": "Product with ID 1 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## 6. Set Product Commission (Admin Only)

تعيين نسبة عمولة التطبيق على المنتج وتأكيدها. هذه العملية تؤدي إلى إظهار المنتج في قوائم استعراض تطبيق العملاء.

- **URL:** `/products/:id/commission`
- **Method:** `PATCH`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <access_token>`
- **Roles:** `ADMIN`

### Payload (Request Body)

| Key              | Type   | Required | Description                                       |
| ---------------- | ------ | -------- | ------------------------------------------------- |
| `commissionRate` | Number | Yes      | نسبة العمولة (رقم موجب، مثلاً النسبة 10 تمثل 10%) |

### Request Example

```json
{
  "commissionRate": 15.5
}
```

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Delicious Burger",
    "commissionRate": 15.5,
    "commissionConfirmed": true
  },
  "timestamp": "2026-03-04T12:00:00.000Z",
  "path": "/api/v1/products/1/commission"
}
```

---

## 7. Delete Product Image

- **URL:** `/products/images/:imageId`
- **Method:** `DELETE`
- **Headers:** `Authorization: Bearer <access_token>`

### Response (Success - 200 OK)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2026-02-23T10:06:30.000Z",
  "path": "/api/v1/products/images/10"
}
```

### Response (Error - 404 Not Found)

```json
{
  "message": "Image with ID 10 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

### Response (Error - 400 Bad Request)

```json
{
  "message": "Image with ID 10 is not a product image",
  "error": "Bad Request",
  "statusCode": 400
}
```

### Response (Error - 404 Not Found)

إذا كان المنتج المرتبط بالصورة غير موجود (للتاجر):

```json
{
  "message": "Product with ID 1 not found",
  "error": "Not Found",
  "statusCode": 404
}
```

---

## تفاصيل تقنية إضافية

- **المتحكم:** [ProductsController](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.controller.ts)
  - إنشاء: `POST /products` مع `FilesInterceptor('images', 5)`.
  - عرض: `GET /products` ويمرر هوية المستخدم والدور للخدمة.
  - عرض واحد: `GET /products/:id`.
  - تعديل: `PATCH /products/:id` مع رفع صور جديدة.
  - تعيين العمولة: `PATCH /products/:id/commission` متاح للإدارة فقط.
  - حذف: `DELETE /products/:id`.
  - حذف صورة: `DELETE /products/images/:imageId`.

- **الخدمة:** [ProductsService](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/modules/products/products.service.ts)
  - التحقق من الملكية: `checkProductOwnership`.
  - منطق الصور: `processAndSaveImages`, `updateImagesMetadata` (تعيين الصورة الرئيسية وإعادة ترتيب الصور)، `deleteProductImage` (حذف صورة محددة).
  - حذف عدة صور: دعم `deleteImageIds` في التحديث لحذف صور متعددة دفعة واحدة.
  - **منطق حذف المنتج**: `remove` - يتعامل مع:
    - حذف order items للطلبات PENDING
    - وضع productId = null للطلبات الأخرى
    - حذف صور المنتج
    - حذف تقييمات المنتج
    - حذف المنتج نفسه
  - منطق التصنيف: التحقق من وجود التصنيف عبر `CategoriesService.findOne`.
  - تقييد قائمة المنتجات للتاجر: `findAll` يفلتر `merchantId = user.id`.

- **الكائن (Entity):** [Product](file:///c:/Users/RYZEN/Desktop/Jeeb_BackEnd/delivery-jeeb/src/database/entities/product.entity.ts)
  - نصوص محلية `name`, `description`, `shortDescription` مخزّنة كـ JSONB باستخدام محوّل.
  - صور منتج تُحمّل يدوياً عبر الخدمة (علاقة متعددة الأشكال مع جدول الصور).
  - حقول التكامل الخارجي: `isExternal`, `externalProvider`, `externalId`, `externalMetadata`.
  - حقول محسوبة في الـ response: `priceAfterDiscount`, `finalPrice`, `commissionAmount` (العمولة معطلة).
