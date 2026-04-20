# Client live delivery tracking → Admin app

This folder is a **portable copy** of the Jeeb client feature where the customer sees a **live Google Map** when the order status is **ON_THE_WAY** (“on the way”). The same **Firebase Realtime Database** instance is used (`/orders/{orderId}/status`, `deliveryId`, `routeHistory`, and `/drivers/{deliveryId}`).

## What the client does (reference)

- Listens to RTDB for status, `deliveryId`, driver GPS, and `routeHistory`.
- When `routeStatus == onTheWay` and drop-off or driver coords exist, it shows [`LiveTrackingMapCard`](lib/core/presentation/widgets/live_tracking_map_card.dart).

## 1. Merge into your admin Flutter project

1. Copy everything under `lib/` into your admin app’s `lib/` (merge folders).  
2. Copy `assets/images/order_status/` into your admin `assets/images/order_status/` (if that folder is missing in this bundle, copy it from the main `jeeb_app` repo — `pubspec` already expects those PNGs).  
3. **Rename the Dart package** in every copied file: replace `package:jeeb_app/` with `package:<your_admin_package_name>/` (IDE: replace in path `to_copy_for_admin/lib` after you paste into admin, or replace after copy).

## 2. `pubspec.yaml` dependencies

Add (versions can match your client app or newer compatible versions):

```yaml
dependencies:
  flutter_bloc: ^9.1.1
  bloc: ^9.2.0
  equatable: ^2.0.8
  easy_localization: ^3.0.8
  firebase_core: ^3.15.2
  firebase_database: ^11.3.5
  google_maps_flutter: ^2.12.3
  flutter_screenutil: ^5.9.3
  get_it: ^9.2.1   # optional; only if you register services the same way
```

**Assets** (admin `pubspec.yaml`):

```yaml
flutter:
  assets:
    - assets/images/order_status/
```

## 3. Firebase

- Use the **same** `google-services.json` / `GoogleService-Info.plist` Firebase project as the client (already shared).
- Ensure **Realtime Database** rules allow the admin app’s auth (or your chosen rules) to **read** `orders/{orderId}` and `drivers/{driverId}`.
- The RTDB URL is defined in [`order_status_rtdb_service.dart`](lib/core/infrastructure/realtime/order_status_rtdb_service.dart) as `kOrderRtdbDatabaseUrl`. If you ever change the database URL, update that constant in the admin copy.

## 4. Localization

- Merge keys from [`assets/lang/order_tracking_en.json`](assets/lang/order_tracking_en.json) and [`order_tracking_ar.json`](assets/lang/order_tracking_ar.json) into your existing Easy Localization JSON files **or** load these files alongside your current locale files.
- The bundle includes a **minimal** [`app_translation.dart`](lib/core/presentation/localization/app_translation.dart) with only tracking-related strings.

## 5. App bootstrap

- Call `Firebase.initializeApp()` before using `OrderStatusRtdbService` (same as client).
- Wrap the app (or subtree) with `ScreenUtilInit` if your admin app does not already use `flutter_screenutil` — the theme `AppFontSize` / `AppPadding` values depend on it (same as Jeeb client).

## 6. Dependency injection + route

Register a **singleton** for realtime:

```dart
sl.registerLazySingleton<OrderStatusRtdbService>(() => OrderStatusRtdbService());
```

Provide the bloc when opening the tracking screen (mirror of client `route_manager`):

```dart
BlocProvider(
  create: (_) => OrderStatusBloc(
    orderId: orderIdString,
    initialStatus: OrderStatus.fromString(initialStatusWireFromApi),
    deliveryLatitude: lat,
    deliveryLongitude: lng,
    deliveryManName: name,
    deliveryManPhone: phone,
    orderStatusRtdb: sl<OrderStatusRtdbService>(),
  ),
  child: const OrderStatusPage(),
)
```

**Navigation:** edit [`AdminOrderTrackingNav`](lib/features/basket/order_status_section/presentation/pages/order_status_page.dart) (`kAdminOrderDetailsRouteName` and the `Navigator` calls) to match your admin routing.

## 7. Google Maps (Android / iOS)

Same as any Flutter Maps setup: API key in `AndroidManifest.xml`, iOS `AppDelegate` / `Info.plist`, and billing enabled on the Google Cloud project tied to the key.

## 8. File manifest (everything in this bundle)

| Path | Role |
|------|------|
| `lib/core/infrastructure/realtime/order_status_rtdb_service.dart` | RTDB streams + driver location |
| `lib/core/infrastructure/realtime/route_history_point.dart` | Parse `routeHistory` |
| `lib/core/presentation/maps/route_history_polyline_builder.dart` | Polylines for walked path |
| `lib/core/presentation/widgets/live_tracking_map_card.dart` | Live map UI |
| `lib/core/presentation/widgets/text_widget.dart` | `CustomText` |
| `lib/core/presentation/theme/colors_manager.dart` | Colors |
| `lib/core/presentation/theme/font_manager.dart` | Fonts / sizes (ScreenUtil) |
| `lib/core/presentation/theme/styles_manager.dart` | Text styles |
| `lib/core/presentation/theme/values_manager.dart` | Spacing / radius |
| `lib/core/presentation/localization/app_translation.dart` | Minimal strings |
| `lib/core/common/utils/order_status_step_index.dart` | Timeline index helpers |
| `lib/core/common/utils/asset_manager.dart` | Order hero image paths |
| `lib/core/common/classes/order_status_step_labels.dart` | Step titles |
| `lib/features/delivery/order/order_details/domain/entities/order_status.dart` | `OrderStatus` enum |
| `lib/features/basket/order_status_section/presentation/pages/order_status_page.dart` | Full tracking page |
| `lib/features/basket/order_status_section/presentation/bloc/order_status_bloc.dart` | + `order_status_event/state` parts |
| `lib/features/basket/order_status_section/presentation/widgets/*.dart` | Timeline, hero, badge, banner |
| `docs/Firebase_Realtime_Database.md` | Backend contract reference |
| `assets/lang/order_tracking_*.json` | Strings to merge |

## 9. Optional: map only (no full timeline)

If the admin UI only needs the map, you can use **`OrderStatusBloc` + `LiveTrackingMapCard`** in your own page and drop the hero/timeline widgets — the RTDB wiring is entirely in the bloc.

---

Generated from the Jeeb client app; keep RTDB URL and Firebase project aligned with production.
