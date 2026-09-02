# Unassign Driver (إزالة مندوب من الطلب)

> **الأدمن فقط** — `PATCH /api/v1/orders/:id/unassign-driver`

---

## 1. Request

### Method & Endpoint

```
PATCH {{baseUrl}}/api/v1/orders/:id/unassign-driver
```

### Headers

| Key | Value |
|-----|-------|
| Authorization | `Bearer {{adminToken}}` |
| Content-Type | `application/json` |

### URL Parameter

| Param | Type | مثال |
|-------|------|------|
| `id` | number | `5` (معرف الطلب) |

### Body

```json
{
  "action": "auto_search" | "manual_assign",
  "newDeliveryId": 78
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `action` | `"auto_search"` / `"manual_assign"` | **نعم** | auto_search → يعيد الطلب للبحث عن مندوب. manual_assign → يعين مندوب محدد |
| `newDeliveryId` | number | **نعم** فقط إذا `action = manual_assign` | معرف المستخدم (المندوب) الجديد |

---

## 2. Behaviours by Action

### `auto_search`
- يتم إنهاء التعيين الحالي (`EXPIRED`)
- حالة الطلب ← `SEARCHING`
- النظام يبدأ بالبحث عن مندوب (نفس آلية البحث العادية)
- السائق القديم يُشعر بإشعار "تم إزالتك من الطلب"

### `manual_assign`
- يتم إنهاء التعيين الحالي (`EXPIRED`)
- يتم إنشاء تعيين جديد بحالة `ASSIGNED` للمندوب الجديد
- حالة الطلب ← `ASSIGNED`
- السائق القديم يُشعر بإشعار
- السائق الجديد يُشعر بإشعار "تم تعيينك للطلب"
- Firebase تحدث: document الطلب, deliveryId, driver document

---

## 3. Response (Success 200)

```json
{
  "statusCode": 200,
  "message": "Operation successful",
  "data": {
    "orderId": 5,
    "previousDriverId": 50,
    "newDriverId": 78,
    "newStatus": "ASSIGNED"
  },
  "timestamp": "2026-06-29T09:25:06.000Z",
  "path": "/api/v1/orders/5/unassign-driver"
}
```

| Field (inside `data`) | Type | Description |
|-------|------|-------------|
| `orderId` | number | معرف الطلب |
| `previousDriverId` | number | معرف المندوب الذي تمت إزالته |
| `newDriverId` | number \| null | المندوب الجديد (null إذا `auto_search`) |
| `newStatus` | string | `"ASSIGNED"` أو `"SEARCHING"` حسب الـ action |

---

## 4. Error Responses

جميع الأخطاء تأتي بنفس القالب الموحد من `AllExceptionsFilter`:

```json
{
  "statusCode": <number>,
  "message": "<error text>",
  "data": {},
  "timestamp": "2026-06-29T09:25:06.000Z",
  "path": "/api/v1/orders/5/unassign-driver"
}
```

### 404 — Order Not Found
- **message**: `"Order not found (ID: 999)"`

### 400 — No Active Assignment
- **message**: `"Order must be in SEARCHING or READY_FOR_PICKUP status to assign delivery"`
- رح يظهر إذا ما في `ACCEPTED` DeliveryAssignment على الطلب

### 400 — Driver Not Found (manual_assign)
- **message**: `"Delivery driver not found (ID: 999)"`

### 400 — Invalid Role (manual_assign)
- **message**: `"Invalid user role"`
- المستخدم اللي حاطط `newDeliveryId` مش مندوب (`UserRole.DELIVERY`)

### 400 — Driver Not Available (manual_assign)
- **message**: `"Delivery driver is not available"`
- المندوب غير `isActive`

### 400 — Already Assigned to Same Driver (manual_assign)
- **message**: `"Order already has active delivery assignment"`
- `newDeliveryId` نفس المندوب الحالي

### 400 — Driver Busy (manual_assign)
- **message**: `"Delivery driver is currently busy with another order"`
- للمندوب طلب نشط آخر (واحد أو أكثر بحالات: ASSIGNED, PREPARING, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY)

### 403 — Forbidden (ليس أدمن)
- **message**: `"Only admins can unassign drivers"`

---

## 5. Validation Rules (Frontend)

### Auto-Search mode
- ما حاجة `newDeliveryId`
- زر واحد: "إزالة المندوب والبحث عن بديل"

### Manual Assign mode
- `newDeliveryId` مطلوب validation:
  - must be integer ≥ 1
  - يُفضل عمل autocomplete/search للمندوبين قبل الإرسال
- زر واحد: "إزالة وتعيين مندوب"

### Common (both modes)
- لازم `order.status` يكون `ASSIGNED` أو `PREPARING` أو `READY_FOR_PICKUP`
- لازم يكون في `DeliveryAssignment` بحالة `ACCEPTED`
- ما دام في المندوب نشط مش مرتاح للطلب ما رح يشتغل

---

## 6. UI Notes

### Prerequisite — order has an accepted driver
- في صفحة تفاصيل الطلب، إذا الطلب بحالة `ASSIGNED` / `PREPARING` / `READY_FOR_PICKUP` وكان في مندوب نشط `ACCEPTED` → أظهر زر "إزالة المندوب"

### Dropdown / Toggle action
- خيارين: "بحث تلقائي" / "تعيين مندوب آخر"
- "تعيين مندوب آخر" يظهر field اختيار مندوب (بحث / dropdown)
- التأكيد مطلوب: "هل أنت متأكد من إزالة المندوب الحالي؟"

### Post-success
- Auto-search: حالة الطلب رح تصير `SEARCHING` — اختفاء معلومات المندوب وظهور loader بحث
- Manual assign: حالة الطلب رح تصير `ASSIGNED` — تحديث معلومات المندوب بالجديد
- السائق القديم: رح يوصل إشعار "تم إزالتك من الطلب رقم #5"
- السائق الجديد (manual): رح يوصل إشعار "تم تعيينك لتوصيل الطلب رقم #5 من قبل الإدارة"

---

## 7. Involved Statuses

### Order Statuses (قابلة للإزالة)
`ASSIGNED` / `PREPARING` / `READY_FOR_PICKUP`

### Order Status (نتيجة auto_search)
`SEARCHING`

### Order Status (نتيجة manual_assign)
`ASSIGNED`

### DeliveryAssignment Status
- القديم: `ACCEPTED` → `EXPIRED`
- الجديد (manual_assign): `ASSIGNED`
- الجديد (auto_search): ما في (لأنه البحث رح يخلق Notified جديد)

### Column DeliveryAssignment
- `unassignedAt: timestamp` (nullable) — وقت الإزالة

---

## 8. Audit Log

```
AuditAction.UNASSIGN_DRIVER
Old: { deliveryId: 50, status: "ASSIGNED" }
New: { action: "manual_assign", newDeliveryId: 78, newStatus: "ASSIGNED" }
```

---

## 9. Quick Reference

| Item | Value |
|------|-------|
| Endpoint | `PATCH /api/v1/orders/:id/unassign-driver` |
| Auth | Admin only (Bearer JWT) |
| Allowed order statuses | `ASSIGNED`, `PREPARING`, `READY_FOR_PICKUP` |
| Result statuses | `ASSIGNED` (manual) / `SEARCHING` (auto) |
| Error codes | 404, 400, 403 |
| Notifications sent | Old driver (both modes) + New driver (manual only) |
