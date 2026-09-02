# Firebase Security Rules

> هذه القواعد يجب تطبيقها في Firebase Console
>
> **ملاحظة مهمة:** `newData` في Firebase RTDB Rules يمثل البيانات **بعد الدمج** مع البيانات الموجودة. لذلك، التحقق من الحقول المحمية يستخدم المقارنة `data` vs `newData` وليس `!newData.hasChild(...)`. أنظر الشرح في قسم "ملاحظات فنية" أدناه.

---

## نظرة عامة

القواعد المحدثة تعتمد على نظام **Custom Token Authentication** للديلفري:

- كل سائق يحصل على Firebase UID بصيغة `delivery_{userId}`
- الكتابة في الطلبات مسموحة فقط للديلفري صاحب الطلب (عبر مطابقة `auth.uid` مع `deliveryUid`)
- القراءة مسموحة للجميع

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

        ".update": "
          auth != null &&
          auth.uid == 'delivery_' + $driverId &&
          (
            newData.hasChild('currentLat') ||
            newData.hasChild('currentLng') ||
            newData.hasChild('onLine') ||
            newData.hasChild('isOnline') ||
            newData.hasChild('location')
          ) &&
          (!data.hasChild('id') || data.child('id').val() === newData.child('id').val()) &&
          (!data.hasChild('createdAt') || data.child('createdAt').val() === newData.child('createdAt').val())
        ",

        ".delete": false
      }
    }
  }
}
```

### ملخص الصلاحيات:

| الإجراء | المسموح؟ | من؟ |
| ------- | ----------------------------------- | ----------------------- |
| قراءة | ✅ نعم | الجميع |
| إنشاء | ❌ لا | Backend فقط |
| تحديث | ✅ currentLat, currentLng, onLine, isOnline, location | الديلفري صاحب الملف فقط |
| حذف | ❌ لا | Backend فقط |

### التحقق من الملكية:

```
auth.uid == 'delivery_' + $driverId
```

هذا يضمن أن السائق يمكنه تحديث ملفه الشخصي فقط.

### ملاحظات:

- **`onLine`** (بـ L صغيرة) هو اسم الحقل المستخدم في `updateDriverOnlineStatus()`. وُجد `isOnline` أيضاً للتوافق مع `createDriverDocument()`.
- **`location`**: مسار فرعي `drivers/{id}/location` يستخدم من `FirebaseLocationStrategy` لتحديث الموقع بشكل لحظي (`lat`, `lng`, `timestamp`). القاعدة في المستوى الأعلى تسمح بهذا المسار بشكل غير مباشر لأن `newData` في `$driverId` يتضمن الحقول الموجودة.

---

## Orders Collection (`/orders`)

### القواعد المحدثة (مع التحقق من الملكية):

```json
{
  "rules": {
    "orders": {
      "$orderId": {

        ".read": true,

        ".create": false,

        ".update": "
          auth != null &&
          root.child('orders').child($orderId).child('deliveryUid').val() == auth.uid &&
          (
            newData.hasChild('routeHistory') ||
            newData.hasChild('speed')
          ) &&
          (!data.hasChild('id') || data.child('id').val() === newData.child('id').val()) &&
          (!data.hasChild('orderId') || data.child('orderId').val() === newData.child('orderId').val()) &&
          (!data.hasChild('status') || data.child('status').val() === newData.child('status').val()) &&
          (!data.hasChild('customerId') || data.child('customerId').val() === newData.child('customerId').val()) &&
          (!data.hasChild('ownerId') || data.child('ownerId').val() === newData.child('ownerId').val()) &&
          (!data.hasChild('deliveryId') || data.child('deliveryId').val() === newData.child('deliveryId').val()) &&
          (!data.hasChild('deliveryUid') || data.child('deliveryUid').val() === newData.child('deliveryUid').val()) &&
          (!data.hasChild('restaurantLocation') || data.child('restaurantLocation').val() === newData.child('restaurantLocation').val()) &&
          (!data.hasChild('customerLocation') || data.child('customerLocation').val() === newData.child('customerLocation').val()) &&
          (!data.hasChild('createdAt') || data.child('createdAt').val() === newData.child('createdAt').val())
        ",

        ".delete": false
      }
    }
  }
}
```

### ملخص الصلاحيات:

| الإجراء | المسموح؟ | من؟ |
| ------- | ---------------------- | ----------------------- |
| قراءة | ✅ نعم | الجميع |
| إنشاء | ❌ لا | Backend فقط |
| تحديث | ✅ routeHistory, speed | الديلفري صاحب الطلب فقط |
| حذف | ❌ لا | Backend فقط |

### التحقق من الملكية:

```
root.child('orders').child($orderId).child('deliveryUid').val() == auth.uid
```

هذا يضمن أن الديلفري يمكنه تحديث بيانات التتبع فقط للطلبات المسندة إليه.

### الحقول المحمية من التعديل:

| الحقل | ملاحظة |
| :------------------ | :------------------------------------------------ |
| `id` | رقم الطلب — محمي (لا يمكن تغيير قيمته) |
| `orderId` | رقم الطلب — محمي |
| `status` | حالة الطلب — محمي (يتم التحديث من Backend فقط) |
| `customerId` | رقم العميل — محمي |
| `ownerId` | رقم صاحب المطعم — محمي |
| `deliveryId` | رقم السائق — محمي (يتم التحديث من Backend عبر `setDeliveryId()`) |
| `deliveryUid` | Firebase UID للسائق — محمي |
| `restaurantLocation` | موقع المطعم — محمي |
| `customerLocation` | موقع العميل — محمي |
| `createdAt` | وقت الإنشاء — محمي |
| `updatedAt` | **غير محمي** — يمكن تحديثه (يتم ضبطه تلقائياً مع كل عملية تحديث) |

### ملاحظة حول التحقق من الحقول المحمية:

بدلاً من استخدام `!newData.hasChild('field')` (الذي يمنع جميع التحديثات لأن `newData` هو البيانات بعد الدمج)، يستخدم التحقق الصيغة التالية:

```
(!data.hasChild('field') || data.child('field').val() === newData.child('field').val())
```

هذا يعني: "إما الحقل غير موجود أصلاً، أو قيمته لم تتغير." هذا يسمح بتحديث `routeHistory` و `speed` مع ضمان عدم تغيير الحقول المحمية.

---

## كيفية التطبيق

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Realtime Database** → **Rules**
4. انسخ القواعد المناسبة
5. اضغط **Publish**

---

## Security Rules كاملة (Copy-Paste)

### الوضع الإنتاج (Production Mode)

```json
{
  "rules": {
    "orders": {
      "$orderId": {
        ".read": true,
        ".create": false,
        ".update": "
          auth != null &&
          root.child('orders').child($orderId).child('deliveryUid').val() == auth.uid &&
          (
            newData.hasChild('routeHistory') ||
            newData.hasChild('speed')
          ) &&
          (!data.hasChild('id') || data.child('id').val() === newData.child('id').val()) &&
          (!data.hasChild('orderId') || data.child('orderId').val() === newData.child('orderId').val()) &&
          (!data.hasChild('status') || data.child('status').val() === newData.child('status').val()) &&
          (!data.hasChild('customerId') || data.child('customerId').val() === newData.child('customerId').val()) &&
          (!data.hasChild('ownerId') || data.child('ownerId').val() === newData.child('ownerId').val()) &&
          (!data.hasChild('deliveryId') || data.child('deliveryId').val() === newData.child('deliveryId').val()) &&
          (!data.hasChild('deliveryUid') || data.child('deliveryUid').val() === newData.child('deliveryUid').val()) &&
          (!data.hasChild('restaurantLocation') || data.child('restaurantLocation').val() === newData.child('restaurantLocation').val()) &&
          (!data.hasChild('customerLocation') || data.child('customerLocation').val() === newData.child('customerLocation').val()) &&
          (!data.hasChild('createdAt') || data.child('createdAt').val() === newData.child('createdAt').val())
        ",
        ".delete": false
      }
    },
    "drivers": {
      "$driverId": {
        ".read": true,
        ".create": false,
        ".update": "
          auth != null &&
          auth.uid == 'delivery_' + $driverId &&
          (
            newData.hasChild('currentLat') ||
            newData.hasChild('currentLng') ||
            newData.hasChild('onLine') ||
            newData.hasChild('isOnline') ||
            newData.hasChild('location')
          ) &&
          (!data.hasChild('id') || data.child('id').val() === newData.child('id').val()) &&
          (!data.hasChild('createdAt') || data.child('createdAt').val() === newData.child('createdAt').val())
        ",
        ".delete": false
      }
    }
  }
}
```

---

## ملاحظات فنية

### لماذا `!newData.hasChild()` كان خطأ؟

في Firebase RTDB Security Rules:

- **`data`**: البيانات **الحالية** في المسار قبل الكتابة
- **`newData`**: البيانات **بعد تطبيق** عملية الكتابة (الدمج)

عند استخدام `.update()`، `newData` هو دمج البيانات الموجودة مع البيانات الجديدة. لذلك، إذا كان المستند موجوداً وله حقل `status`، فإن `newData.hasChild('status')` سيعيد `true` دائماً — حتى لو لم يتم تضمين `status` في التحديث.

التحقق الصحيح هو مقارنة `data` مع `newData` للتأكد من أن الحقول المحمية لم تتغير.

### لماذا `.isArray()` غير مدعوم؟

Firebase Realtime Database Security Rules تدعم فقط ثلاث دوال للتحقق من النوع:
- `.isString()`
- `.isNumber()`
- `.isBoolean()`

**لا تدعم** `.isArray()` أو `.isObject()`. هذه الدوال موجودة فقط في Cloud Firestore Security Rules.

تم إزالة التحقق من نوع `routeHistory` واستبداله بالتحقق من وجود الحقل فقط (`newData.hasChild('routeHistory')`).

### الفرق بين `isOnline` و `onLine`

| المصدر | اسم الحقل |
| :---------------------------- | :--------- |
| `createDriverDocument()` | `isOnline` |
| `updateDriverOnlineStatus()` | `onLine` |
| `getAllDriverLocations()` | يقرأ `isOnline` |

`updateDriverOnlineStatus()` يكتب الحقل باسم `onLine` (حرف L صغير) بينما `createDriverDocument()` يكتب `isOnline`. القواعد تدعم كلا الاسمين للتوافق.

---

## ملاحظات

### للأمان:

1. **التحقق من الملكية**: القواعد الجديدة تضمن أن كل سائق يمكنه تحديث:
   - ملفه الشخصي فقط في `/drivers/{id}`
   - بيانات التتبع فقط للطلبات المسندة إليه في `/orders/{id}`

2. **الحقول المحمية**: الحقول الحساسة (`id`, `status`, `locations`, إلخ) محمية من التعديل — يتم التحقق من أن قيمها لم تتغير بدلاً من التحقق من عدم وجودها.

3. **الإنشاء والحذف**: يتم من Backend فقط عبر Firebase Admin SDK (الذي يتجاوز Security Rules).

4. **Custom Token**: يُنشأ من السيرفر ويحتوي على `deliveryId` مطابق للـ Firebase UID.

5. **`updatedAt`**: غير محمي لأنه يتم تحديثه تلقائياً مع كل عملية تحديث للموقع أو الحالة.

### للتحقق من القواعد:

1. افتح Firebase Console → Realtime Database → Rules
2. انقر على "Validate Security Rules"
3. جرب عمليات القراءة والكتابة المختلفة
4. تأكد من أن:
   - DELIVERY يمكنه تحديث `routeHistory` و `speed` فقط لطلباته
   - DELIVERY يمكنه تحديث ملفه الشخصي فقط في `/drivers/{id}`
   - باقي الأدوار يمكنهم القراءة فقط

---

## Troubleshooting

### خطأ: PERMISSION_DENIED

**السبب**: الديلفري ليس صاحب الطلب أو الـ token غير صالح

**الحل**:

1. تأكد من أن `deliveryUid` في الطلب يطابق `auth.uid`
2. تأكد من أن Custom Token حديث ولم ينتهِ من الصلاحية

### خطأ: Validation Failed

**السبب**: محاولة تعديل حقل محمي أو كتابة بيانات بصيغة غير صحيحة

**الحل**: راجع الحقول المحمية في القواعد أعلاه. تأكد من أنك تُحدث فقط `routeHistory` و `speed` في orders، أو `currentLat`/`currentLng`/`onLine`/`isOnline`/`location` في drivers.

### التحقق من deliveryUid:

```javascript
// في Firebase Console، تحقق من:
/orders/{orderId}/deliveryUid == auth.uid
```

مثال:

```
/orders/56/deliveryUid == "delivery_57" // auth.uid يجب أن يكون "delivery_57"
```

### خطأ: Invalid rule expression

**السبب**: استخدام دوال غير مدعومة مثل `.isArray()` في القواعد

**الحل**: استخدم فقط الدوال المدعومة: `.isString()`، `.isNumber()`، `.isBoolean()`. للتحقق من وجود حقل من نوع array، استخدم `newData.hasChild('field')` فقط دون التحقق من النوع.
