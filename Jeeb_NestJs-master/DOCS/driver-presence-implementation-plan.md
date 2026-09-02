# خطة تنفيذ نظام Driver Online Presence — Jeeb Backend

**النسخة:** 1.0
**التاريخ:** 2026-07-26
**المسؤول:** فريق Backend (NestJS)
**الحالة:** جاهز للتنفيذ

---

## 1. نظرة عامة على الهدف

بناء نظام لمعرفة **الديلفري النشيطين (Online) لحظياً** بالاعتماد على Firebase RTDB كمصدر الحقيقة الأساسي (Source of Truth)، مع مزامنة دورية خفيفة لعمود `isOnline` فقط إلى Postgres، لغرض:

1. اختيار أقرب ديلفري متاح عند تعيين طلب جديد (قرار تشغيلي حساس — real-time)
2. عرض قائمة الديلفري النشيطين بلوحة تحكم الأدمن مع pagination/فلترة (عرض غير حساس زمنياً — eventual consistency مقبولة)

> **مبدأ حاكم يجب على كل مطور احترامه:** أي قرار يؤثر على تعيين طلب فعلي (assignment) يُبنى حصراً على الكاش المباشر من RTDB (`DriverPresenceService.getTrulyOnlineDrivers()`), **وليس** على عمود `isOnline` في Postgres. عمود Postgres هو نسخة معروضة متأخرة بحد أقصى ~15 ثانية، ولا يُستخدم لاتخاذ قرار.

---

## 2. البنية المعمارية والـ Design Patterns

النظام يعتمد على عدة أنماط تصميم متكاملة داخل بنية NestJS الحالية للمشروع:

| النمط (Pattern) | أين يُستخدم | لماذا |
|---|---|---|
| **Observer Pattern** | `DriverPresenceService` يستمع (`.on('child_changed')`) لتغييرات RTDB | فصل مصدر البيانات (Firebase) عن منطق معالجتها؛ التحديثات تصل push مو polling |
| **Repository Pattern** | `DriverRepository` (موجود مسبقاً عبر TypeORM/Prisma حسب بنية مشروعك) | فصل منطق الوصول لقاعدة البيانات عن منطق العمل (Business Logic) |
| **Singleton (Provider Scope)** | `DriverPresenceService` مسجّل كـ provider افتراضي (`DEFAULT` scope) في NestJS | حالة الكاش (in-memory Map) يجب أن تكون نسخة واحدة موحّدة طوال عمر التطبيق |
| **Strategy Pattern** | حساب "أقرب ديلفري" (`DistanceCalculatorStrategy`) | يسمح لاحقاً بتبديل خوارزمية الحساب (Haversine → PostGIS/Redis GEO) دون تعديل منطق التعيين |
| **Facade Pattern** | `DriverPresenceFacade` (اختياري) يجمع القراءة من RTDB + Postgres في واجهة واحدة للـ Controller | يبسّط استخدام الخدمة من طبقات أعلى (Controllers, other Services) |

### مبادئ SOLID المطبّقة

- **S — Single Responsibility:**
  - `DriverPresenceListenerService`: مسؤول فقط عن الاستماع لـ RTDB وتحديث الكاش بالذاكرة
  - `DriverPresenceSyncService`: مسؤول فقط عن مزامنة `isOnline` إلى Postgres (queue + flush)
  - `DriverDistanceService`: مسؤول فقط عن حساب المسافات واختيار الأقرب
  - **لا تدمج هذه المسؤوليات بكلاس واحد ضخم** — هذا كان أهم خلل بالمسودة الأولية وتم تصحيحه بهذه الخطة

- **O — Open/Closed:** خوارزمية حساب المسافة تُعرَّف كـ interface (`IDistanceCalculator`) بحيث يمكن استبدال Haversine بـ PostGIS مستقبلاً دون تعديل `DriverAssignmentService`

- **L — Liskov Substitution:** أي implementation لـ `IPresenceRepository` (سواء RTDB أو مصدر بديل مستقبلاً) يجب أن يكون قابلاً للاستبدال دون كسر المستهلكين (consumers)

- **I — Interface Segregation:** لا تجبر `DriverAssignmentService` على الاعتماد على واجهة ضخمة فيها كل شي؛ فقط `getTrulyOnlineDrivers()` و`isDriverOnline(id)`

- **D — Dependency Inversion:** `DriverAssignmentService` يعتمد على abstraction (`IDriverPresenceProvider`) وليس على `DriverPresenceListenerService` مباشرة — يسهّل الاختبار (mocking) والاستبدال

### DRY — تفادي التكرار

- **DTO/Interface موحّد** لبيانات الديلفري (`DriverPresenceDto`) يُستخدم بكل الطبقات (Listener, Sync, Controller) بدل ما كل ملف يعرّف شكله الخاص
- **ثابت واحد للـ staleness threshold** (`PRESENCE_STALE_THRESHOLD_MS`) يُعرَّف مرة وحدة بـ `constants/presence.constants.ts` ويُستورد بكل مكان — **ممنوع تكرار الرقم 45000 بأكثر من ملف**
- **دالة `isPresenceStale()` مشتركة** بدل تكرار منطق `Date.now() - lastSeen > threshold` بأكثر من مكان

---

## 3. بنية المجلدات المقترحة (متوافقة مع بنية NestJS الحالية)

بافتراض إن مشروعك يتبع بنية Feature Modules القياسية (حسب ما هو موثق من عملك السابق على Jeeb)، أضف الموديول التالي دون المساس بأي موديول قائم:

```
src/
└── modules/
    └── driver-presence/
        ├── driver-presence.module.ts
        ├── constants/
        │   └── presence.constants.ts
        ├── interfaces/
        │   ├── driver-presence.interface.ts
        │   └── presence-provider.interface.ts
        ├── dto/
        │   └── driver-presence.dto.ts
        ├── services/
        │   ├── driver-presence-listener.service.ts     # Observer + Cache
        │   ├── driver-presence-sync.service.ts          # Debounced Postgres sync
        │   ├── driver-presence-reconciliation.service.ts # Initial full sync on boot
        │   └── driver-distance.service.ts                # Strategy: nearest driver calc
        ├── controllers/
        │   └── driver-presence.controller.ts
        ├── repositories/
        │   └── driver-presence.repository.ts             # يعتمد على Repository موجود مسبقاً إن وُجد
        └── tests/
            ├── driver-presence-listener.service.spec.ts
            ├── driver-presence-sync.service.spec.ts
            ├── driver-presence-reconciliation.service.spec.ts
            └── driver-distance.service.spec.ts
```

> **مهم:** لا تُنشئ Firebase Admin SDK initialization جديد إذا كان مُهيّأ مسبقاً بمشروعك (مثلاً بـ `FirebaseModule` أو `shared/firebase`). استخدم نفس الـ provider الموجود لتفادي تكرار الاتصال بـ Firebase (تناقض مباشر مع DRY وقد يسبب تعدد listeners غير مقصود على نفس المسار).

---

## 4. خطوات التنفيذ التفصيلية (Backlog مرتب)

### المرحلة 1 — تحضير قاعدة البيانات والقواعد

- [ ] **Migration:** إضافة عمود `is_online BOOLEAN DEFAULT false` لجدول `drivers` بـ Postgres (إن لم يكن موجوداً)؛ استخدم أداة الـ migration المعتمدة بالمشروع (TypeORM migration / Prisma migrate) — **لا تعدّل الجدول يدوياً بالـ production**
- [ ] **RTDB Rules:** إضافة حقل `lastSeen` بقواعد `database.rules.json` مع `.validate: newData.isNumber()` (راجع القسم 5)
- [ ] نشر (deploy) قواعد RTDB المحدّثة عبر Firebase CLI بعد مراجعة فريق الـ Flutter لتأكيد التوافق مع تحديثاتهم على `onDisconnect`

### المرحلة 2 — طبقة الـ Interfaces والـ Constants (الأساس المشترك)

- [ ] تعريف `IDriverPresenceProvider` interface (القراءة فقط: `getTrulyOnlineDrivers()`, `isDriverOnline(id: string)`)
- [ ] تعريف `DriverPresenceDto` (id, currentLat, currentLng, isOnline, lastSeen)
- [ ] تعريف ثابت `PRESENCE_STALE_THRESHOLD_MS = 45_000` ودالة `isPresenceStale(lastSeen: number): boolean`

### المرحلة 3 — Listener Service (Observer Pattern)

- [ ] تنفيذ `DriverPresenceListenerService` بمسؤولية وحيدة: الاستماع لـ `drivers` بـ RTDB وتحديث `Map` بالذاكرة
- [ ] التأكد من استخدام نفس `admin.database()` instance الموجود بالمشروع (عدم تكرار التهيئة)
- [ ] **عدم لمس أي منطق قائم بخدمات الطلبات (`OrdersModule`)** — هذا الموديول read-only تجاه بيانات RTDB الحالية، لا كتابة أبداً من جهة السيرفر على `drivers/`

### المرحلة 4 — Reconciliation Service (معالجة الإقلاع/الانهيار)

- [ ] تنفيذ `DriverPresenceReconciliationService.onModuleInit()`: قراءة كاملة لمسار `drivers` مرة واحدة عند إقلاع السيرفر، لملء الكاش وقائمة المزامنة الأولية قبل بدء الاستماع اللحظي
- [ ] **ترتيب التنفيذ إلزامي:** Reconciliation أولاً → ثم بدء Listener → هذا يمنع فقدان بيانات لو السيرفر انطفى أثناء تحديثات معلّقة

### المرحلة 5 — Sync Service (Debounced Write لعمود واحد)

- [ ] تنفيذ `DriverPresenceSyncService` بمسؤولية وحيدة: تجميع تغييرات `isOnline` بـ `Map<driverId, boolean>` وتنفيذ `flush` كل **15 ثانية** (حسب توجيهك)
- [ ] **تحديث عمود `is_online` فقط** — ممنوع تمرير أي حقل إضافي بـ `update()` كي لا يتم الكتابة فوق بيانات أخرى بالخطأ (خطر شائع عند استخدام partial update بدون تحديد صريح للحقول)
- [ ] معالجة الأخطاء: عند فشل `flush`، إعادة العناصر الفاشلة لقائمة الانتظار بدل فقدانها صامتاً + تسجيل بالـ Logger
- [ ] استخدام `ConfigService` لجعل الفاصل الزمني (15000ms) قابل للتهيئة عبر environment variable (`PRESENCE_SYNC_INTERVAL_MS`) بدل hardcode — يسهّل التعديل لاحقاً دون نشر كود جديد

### المرحلة 6 — Distance Service (Strategy Pattern)

- [ ] تنفيذ `IDistanceCalculator` interface و`HaversineDistanceCalculator` كتنفيذ افتراضي
- [ ] تنفيذ `DriverAssignmentService.findNearestDriver()` بالاعتماد على `IDriverPresenceProvider` و`IDistanceCalculator` (حقن تبعيات، مو استدعاء مباشر لكلاسات ملموسة — Dependency Inversion)
- [ ] **مراجعة منطق تعيين الطلبات الحالي** (`OrderAssignmentService` أو ما يعادله بمشروعك) والتأكد من دمج `findNearestDriver()` بدون كسر أي حالة موجودة (AUTO_SEARCH / MANUAL_PICK المذكورة بتوثيق دورة حياة الطلب لديك)

### المرحلة 7 — Controller (للاستخدام من لوحة التحكم)

- [ ] Endpoint `GET /drivers/online` يرجّع القائمة مباشرة من الكاش (real-time، للخريطة الحية)
- [ ] Endpoint `GET /drivers?isOnline=true&page=&limit=` يستعلم من Postgres (pagination/فلترة، للوحة الأدمن) — استخدام DTO validation عبر `class-validator` لضبط query params

### المرحلة 8 — الاختبارات (Unit Tests حقيقية)

راجع القسم 6 بالتفصيل. لا تُعتبر المرحلة منتهية دون تغطية اختبارية فعلية (مو placeholder tests).

### المرحلة 9 — المراجعة والنشر

- [ ] Code Review من مطور آخر بالفريق يركّز على: عدم كسر منطق `OrdersModule` القائم، الالتزام ببنية المجلدات، عدم وجود أي كتابة على RTDB من جهة السيرفر
- [ ] نشر تدريجي (staged rollout): تفعيل الـ Listener والـ Reconciliation أولاً بدون تفعيل استخدامه بمنطق التعيين الفعلي، مراقبة الـ logs لمدة يوم كامل، ثم تفعيل الاستخدام الفعلي بـ `DriverAssignmentService`

---

## 5. تحديث قواعد RTDB (`database.rules.json`)

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "drivers": {
      "$driverId": {
        ".read": true,
        ".write": "auth != null && auth.uid === $driverId",
        "id": { ".validate": "!data.exists()" },
        "createdAt": { ".validate": "!data.exists()" },
        "currentLat": { ".validate": "newData.isNumber()" },
        "currentLng": { ".validate": "newData.isNumber()" },
        "isOnline": { ".validate": "newData.isBoolean()" },
        "lastSeen": { ".validate": "newData.isNumber()" },
        "$other": { ".validate": false }
      }
    },
    "orders": {
      "...": "بدون تعديل — يبقى كما هو حالياً"
    }
  }
}
```

> **ملاحظة أمنية مطلوب تأكيدها مع فريق Flutter:** القاعدة `auth.uid === $driverId` أكثر أماناً من `auth != null` المستخدمة حالياً (تمنع أي ديلفري من تعديل بيانات ديلفري آخر). التفعيل يتطلب تأكيد أن الـ Flutter app يستخدم Firebase Auth بـ `uid` مطابق لـ `driverId` بقاعدة بياناتك — يُنصّح بالتنسيق مع فريق الموبايل قبل النشر لتفادي كسر تسجيل الدخول الحالي.

---

## 6. خطة الاختبارات (Unit Tests)

يجب أن تكون الاختبارات **حقيقية وفعّالة** (Mock لـ Firebase Admin SDK وRepository، وليس اختبارات سطحية). أمثلة الحد الأدنى المطلوب لكل ملف:

### `driver-presence-listener.service.spec.ts`
```typescript
describe('DriverPresenceListenerService', () => {
  it('يضيف الديلفري للكاش عند child_added مع isOnline=true');
  it('يزيل الديلفري من الكاش عند تحديث isOnline=false');
  it('يزيل الديلفري من الكاش عند child_removed');
  it('لا يضيف للكاش إذا كانت البيانات ناقصة (currentLat/currentLng مفقودة)');
});
```

### `driver-presence-sync.service.spec.ts`
```typescript
describe('DriverPresenceSyncService', () => {
  it('يجمّع عدة تحديثات لنفس الديلفري بقيمة واحدة فقط قبل الـ flush (آخر قيمة تفوز)');
  it('ينفذ update لعمود isOnline فقط بدون أي حقل إضافي');
  it('يفرّغ الـ queue بعد flush ناجح');
  it('يعيد العناصر الفاشلة للـ queue عند فشل الكتابة بقاعدة البيانات');
  it('لا ينفذ أي عملية عندما تكون الـ queue فارغة');
});
```

### `driver-presence-reconciliation.service.spec.ts`
```typescript
describe('DriverPresenceReconciliationService', () => {
  it('يعتبر الديلفري online فقط إذا isOnline=true و lastSeen حديث (< threshold)');
  it('يستبعد ديلفري بـ isOnline=true لكن lastSeen قديم (stale)');
  it('يملأ الكاش وقائمة المزامنة بشكل صحيح عند الإقلاع');
});
```

### `driver-distance.service.spec.ts`
```typescript
describe('HaversineDistanceCalculator', () => {
  it('يحسب المسافة الصحيحة بين نقطتين معروفتين (قيمة مرجعية محسوبة يدوياً)');
  it('يرجّع صفر عند نفس الإحداثيات تماماً');
});

describe('DriverAssignmentService.findNearestDriver', () => {
  it('يختار الديلفري الأقرب من عدة مرشحين online');
  it('يرجّع null عندما لا يوجد أي ديلفري online');
  it('يستبعد الديلفري ذو lastSeen قديم حتى لو موجود بالكاش الخام');
});
```

**متطلبات إلزامية لكل الاختبارات:**
- استخدام `jest.mock()` لـ `firebase-admin` — ممنوع الاتصال الفعلي بـ RTDB أثناء الاختبار
- استخدام in-memory repository أو mock repository لـ TypeORM/Prisma — ممنوع الاتصال بقاعدة بيانات حقيقية بالـ unit tests (اختبارات التكامل integration tests منفصلة إن رغب الفريق بإضافتها لاحقاً)
- تغطية Edge Cases: بيانات ناقصة، قيم null، تزامن عدة تحديثات بنفس اللحظة

---

## 7. مخاطر ونقاط يجب الانتباه لها أثناء التنفيذ

| الخطر | التخفيف |
|---|---|
| كسر منطق `OrderAssignmentService` القائم (AUTO_SEARCH/MANUAL_PICK) | الدمج يتم عبر إضافة اعتماد جديد (`IDriverPresenceProvider`) وليس استبدال أي كود موجود؛ مراجعة كود شاملة قبل الدمج |
| فقدان بيانات presence عند إعادة تشغيل السيرفر | Reconciliation Service إلزامي قبل بدء الـ Listener (مرحلة 4) |
| تسرّب Listener مكرر عند Hot Reload أثناء التطوير | التأكد من `ref.off()` بـ `onModuleDestroy()` لتفادي تراكم listeners بالبيئة المحلية |
| كتابة سيرفر خاطئة على RTDB تكسر منطق onDisconnect بالموبايل | السيرفر **read-only** تجاه `drivers/` — أي كتابة (لو لزم مستقبلاً) يجب مراجعتها منفصلاً مع فريق Flutter |
| تغيير قواعد RTDB يكسر تسجيل دخول أو تحديث حالة الديلفري الحالي بالتطبيق | تنسيق واختبار مشترك مع فريق Flutter قبل نشر القواعد الجديدة على الإنتاج |

---

## 8. تعريف "تم الإنجاز" (Definition of Done)

- [ ] كل الملفات ضمن `modules/driver-presence/` منفّذة حسب البنية المذكورة بالقسم 3
- [ ] لا يوجد أي تعديل مباشر على موديولات أخرى (`OrdersModule`, إلخ) سوى إضافة اعتماد (dependency injection) واحد بـ `DriverAssignmentService`
- [ ] كل الاختبارات بالقسم 6 مكتوبة وتنجح (`npm run test`)
- [ ] قواعد RTDB منشورة ومختبرة مع فريق Flutter
- [ ] Migration عمود `is_online` منفّذ على بيئة Staging ومُختبر قبل الإنتاج
- [ ] مراقبة الـ logs لمدة 24 ساعة على الأقل بعد التفعيل الكامل بدون أخطاء متكررة بـ `flushSyncQueue`
