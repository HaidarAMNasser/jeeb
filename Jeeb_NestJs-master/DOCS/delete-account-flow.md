# مسار حذف الحساب — الحقول والعلاقات

**آخر تحديث:** 2026-07-26  
**الغرض:** توضيح ماذا يحدث عند حذف حساب `CUSTOMER` / `DELIVERY` / `MERCHANT` بدون كود تقني

---

## 1. نقطة الدخول

| من يحذف | الواجهة | من يُحذف | نوع الحذف |
|---|---|---|---|
| المستخدم نفسه (أي دور) | `DELETE /api/v1/auth/profile` | نفسه فقط | نهائي Hard Delete |
| ADMIN | `DELETE /api/v1/users/customers/:id` | أي عميل | نهائي |
| ADMIN | `DELETE /api/v1/users/merchants/:id` | أي تاجر | نهائي |
| ADMIN | `DELETE /api/v1/users/deliveries/:id` | أي سائق | منطقي Soft Delete + حذف من RTDB |
| مالك المكتب | `DELETE /api/v1/users/deliveries/:id` | سائقيه فقط | منطقي Soft Delete + حذف من RTDB |

`DELETE /api/v1/users/:id` و `DELETE /api/v1/users/office-owners/:id` مسارات عامة لنفس المنطق.

---

## 2. الشروط قبل الحذف

| الدور | الشرط | الرسالة إذا فشل | التأثير |
|---|---|---|---|
| DELIVERY | لا يوجد مهمة نشطة (`ASSIGNED` / `NOTIFIED` / `ACCEPTED` / `PICKED`) | `Cannot delete account while on active delivery mission` | يمنع حذف سائق في الطريق |
| DELIVERY | لا يوجد طلبات غير مكتملة (`PENDING` → `PAID` + assignment `ACCEPTED`) | `Cannot delete account while having incomplete orders` | يمنع حذف سائق عليه التزامات |
| CUSTOMER | لا شرط | — | يحذف مباشرة |
| MERCHANT | لا شرط | — | يحذف مباشرة |

---

## 3. جدول الحقول المتأثرة

| الجدول | الحقل | النوع | ماذا يحدث عند الحذف | التأثير |
|---|---|---|---|---|
| `users` | `id` | number PK | يُحذف نهائياً (أو `deletedAt` يُملأ في Soft Delete) | الحساب يختفي من تسجيل الدخول والبحث |
| `users` | `deletedAt` | timestamp | يُملأ بالتاريخ الحالي فقط في Soft Delete | TypeORM يستبعد السجل تلقائياً من `find()` |
| `users` | `phone` / `email` | string | يُحذف مع السجل | يمكن إعادة استخدام الرقم لاحقاً |
| `orders` | `customerId` | FK → users.id `SET NULL` | يبقى الطلب لكن `customer` يصبح `null` | سجل الطلبات لا يُفقد للمحاسبة |
| `orders` | `ownerId` | FK → users.id `SET NULL` | يبقى الطلب لكن `owner` يصبح `null` | طلبات التاجر تُحفظ |
| `delivery_assignments` | `deliveryId` | FK | تُحذف جميع السجلات المرتبطة بالسائق | ينقطع ربط السائق بطلباته |
| `images` | `entityId` + `url` | FK + storage | تُحذف السجلات وتُحذف الملفات من التخزين | صور البروفايل تُزال نهائياً |
| `products` | `merchantId` | FK | تُحذف عند حذف MERCHANT عبر ADMIN (ليس عبر الحذف الذاتي) | كتالوج التاجر يُزال |
| `merchant` | `userId` | FK `CASCADE` | يُحذف تلقائياً عند حذف `users` | ملف التاجر يختفي |
| `wallet` / `loyalty_account` | `userId` | FK `CASCADE` | يُحذف تلقائياً | رصيد المحفظة ونقاط الولاء تُفقد |
| `favorites` / `reviews` | `userId` | FK | تُحذف تبعاً لإعدادات `onDelete` | المفضلة والمراجعات تُزال |
| RTDB `drivers/{id}` | document | JSON | يُحذف عبر `deleteDriverDocument()` (DELIVERY فقط) | السائق يختفي من الخريطة الحية |

---

## 4. الفروق حسب الدور

| الدور | يحذف الطلبات؟ | يحذف الصور؟ | يحذف المنتجات؟ | يحذف RTDB؟ | نوع الحذف |
|---|---|---|---|---|---|
| **CUSTOMER** (ذاتي) | نعم — فقط `PENDING` و `CONFIRMED` | نعم — كل صوره | لا | لا | نهائي |
| **DELIVERY** (ذاتي) | لا (يُفحص فقط) | نعم | لا | نعم | نهائي |
| **MERCHANT** (ذاتي) | لا | لا | لا | لا | نهائي (ناقص) |
| **MERCHANT** (عبر ADMIN) | لا | ضمنياً عبر cascade | نعم — كل منتجاته | لا | نهائي |
| **DELIVERY** (عبر ADMIN/مالك) | لا | لا | لا | نعم | منطقي Soft Delete |

> ملاحظة: حذف MERCHANT الذاتي حالياً لا يحذف `Product` ولا الصور — يُنصح بتوحيده مع مسار ADMIN.

---

## 5. التسلسل المبسط

```
العميل يطلب DELETE /auth/profile
        ↓
التحقق من الدور + الشروط (DELIVERY فقط)
        ↓
بدء Transaction
        ↓
CUSTOMER → حذف صور → حذف طلبيات PENDING/CONFIRMED → حذف assignments → حذف User
DELIVERY → حذف صور → حذف assignments → حذف User → حذف RTDB document
MERCHANT → حذف assignments → حذف User (cascade يحذف merchant profile)
        ↓
Commit → { message: "Account deleted successfully" }
```

- ADMIN/OFFICE_OWNER يستخدم نفس الخطوات لكن DELIVERY يصبح `softDelete` بدل `delete`.
