# حذف الحساب — دليل الفرونت

**Endpoint:** `DELETE /api/v1/auth/profile`

---

## العنوان (Header)

```
Authorization: Bearer <JWT>
```

لا حاجة لـ `Content-Type` أو `body`.

---

## الطلب

```bash
curl -X DELETE https://api.jeeb2.com/api/v1/auth/profile \
  -H "Authorization: Bearer <token>"
```

```js
await fetch("/api/v1/auth/profile", { method:"DELETE", headers:{ Authorization:`Bearer ${token}` }})
```

---

## الاستجابة — نجاح

`200`

```json
{
  "statusCode": 200,
  "message": "Account deleted successfully",
  "data": {}
}
```

بعدها: احذف التوكن من الجهاز ووجّه المستخدم لتسجيل الدخول. يمكنه التسجيل لاحقاً بنفس البريد/الهاتف كحساب جديد.

---

## الأخطاء المتوقعة

| الحالة | الكود | الرسالة |
|---|---|---|
| بدون توكن / منتهي | `401` | `Unauthorized` |
| المستخدم غير موجود | `404` | `User not found` |
| سائق عليه مهمة نشطة | `400` | `Cannot update account while on active delivery mission. Active orders: #123 (COMPLETE)` |
| سائق عليه طلبات غير مكتملة | `400` | `Cannot delete account while having incomplete orders. Please complete all orders first. Incomplete orders: #123 (...)` |

---

## ملاحظة للسائق

الحذف يُرفض إذا كان عنده طلب بحالة `ASSIGNED` / `NOTIFIED` / `ACCEPTED` / `PICKED` أو طلب `PENDING` → `PAID` مع assignment `ACCEPTED`. يجب إنهاء/إلغاء الطلب أولاً.

---

## بيانات اختبار

```
customer-test@jeeb.test / 123456 — +963991000001
merchant-test@jeeb.test / 123456 — +963991000002
delivery-test@jeeb.test / 123456 — +963991000003
```

`POST /api/v1/auth/login` → خذ `access_token` → استخدمه في `DELETE /auth/profile`.

