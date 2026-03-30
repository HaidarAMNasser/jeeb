# Firebase Security Rules

> هذه القواعد يجب تطبيقها في Firebase Console

---

## Driver Collection (`/drivers`)

### القواعد:

```json
{
  "rules": {
    "drivers": {
      "$driverId": {

        ".read": true,

        ".create": false,

        ".update": "auth != null &&
                   (
                     (newData.hasChild('currentLat') && newData.child('currentLat').isNumber()) ||
                     (newData.hasChild('currentLng') && newData.child('currentLng').isNumber()) ||
                     (newData.hasChild('isOnline') && newData.child('isOnline').isBool())
                   ) &&
                   !newData.hasChild('id') &&
                   !newData.hasChild('createdAt')",

        ".delete": false
      }
    }
  }
}
```

### ملخص الصلاحيات:

| الإجراء | المسموح؟                            | من؟         |
| ------- | ----------------------------------- | ----------- |
| قراءة   | ✅ نعم                              | الجميع      |
| إنشاء   | ❌ لا                               | Backend فقط |
| تحديث   | ✅ currentLat, currentLng, isOnline | الديلفري    |
| حذف     | ❌ لا                               | Backend فقط |

---

## Orders Collection (`/orders`)

### القواعد:

```json
{
  "rules": {
    "orders": {
      "$orderId": {

        ".read": true,

        ".create": false,

        ".update": "
          auth != null &&
          (
            (newData.hasChild('routeHistory') && newData.child('routeHistory').isArray()) ||
            (newData.hasChild('speed') && newData.child('speed').isNumber())
          ) &&
          !newData.hasChild('id') &&
          !newData.hasChild('orderId') &&
          !newData.hasChild('status') &&
          !newData.hasChild('customerId') &&
          !newData.hasChild('ownerId') &&
          !newData.hasChild('deliveryId') &&
          !newData.hasChild('restaurantLocation') &&
          !newData.hasChild('customerLocation') &&
          !newData.hasChild('createdAt')
        ",

        ".delete": false
      }
    }
  }
}
```

### ملخص الصلاحيات:

| الإجراء | المسموح؟               | من؟      |
| ------- | ---------------------- | -------- |
| قراءة   | ✅ نعم                 | الجميع   |
| إنشاء   | ❌ لا                  | -        |
| تحديث   | ✅ routeHistory, speed | الديلفري |
| حذف     | ❌ لا                  | -        |

---

## كيفية التطبيق

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Realtime Database** → **Rules**
4. انسخ القواعد المناسبة
5. اضغط **Publish**

---

## ملاحظات

- هذه القواعد تسمح لـ Frontend بتحديث مواقع محددة فقط
- الحقول الحساسة (id, createdAt, إلخ) محمية من التعديل
- الإنشاء والحذف يتم من Backend فقط
