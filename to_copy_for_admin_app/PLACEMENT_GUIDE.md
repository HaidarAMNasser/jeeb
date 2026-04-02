# Admin app porting bundle — Firebase RTDB + Google Maps + Directions + live tracking

This folder is a **self-contained export** from the **Jeeb client** Flutter app. Use it with another AI or engineer to wire the **admin** app the same way.

**Start here for behaviour:** read **`ORDER_FLOW_README.md`** (list tap → details vs tracking, route args, image paths).

> **Not WebSockets:** Order status and driver position use **Firebase Realtime Database** (`onValue` streams). The client listens to paths like `orders/{orderId}/status`, `orders/{orderId}/deliveryId`, and `drivers/{deliveryId}`.

---

## 1. Quick copy rule

| What | Action |
|------|--------|
| Everything under `lib/` in this bundle | Merge into the admin project’s `lib/` **keeping the same relative paths** (recommended), **or** move files into your admin architecture and then **fix all `import` paths**. |
| `assets/images/order_status/` | Copy into admin `assets/images/order_status/` and register in admin `pubspec.yaml`. |
| `docs/Firebase_Realtime_Database.md` | Reference for backend schema (optional). |
| `firebase_config/` | **Same Firebase project as client:** copy `google-services.json` and `GoogleService-Info.plist` into the admin app’s Android/iOS folders (see below). |
| `snippets/` | **Do not** copy as Dart sources; **merge** the text into your existing `pubspec`, `DI`, `routes`, Android, iOS files. |
| `ORDER_FLOW_README.md` | Human-readable map of **order list / details / status** navigation and folder layout. |

---

## 2. Exact destination map (recommended layout)

After merge, the admin app should contain:

### Firebase RTDB (live order + driver)

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/core/infrastructure/realtime/order_status_rtdb_service.dart` | **Same path:** `lib/core/infrastructure/realtime/order_status_rtdb_service.dart` |

**Edit inside admin:** `kOrderRtdbDatabaseUrl` must match the **same Firebase Realtime Database** the backend writes to. Admin and client can share one RTDB project.

---

### Firebase project config files (Android + iOS) — same GCP/Firebase project

These are **not** in `lib/`; they tie the native app to your Firebase project (same as the client if you use one shared project).

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `firebase_config/android/app/google-services.json` | **`android/app/google-services.json`** (replace or merge per Firebase docs) |
| `firebase_config/ios/Runner/GoogleService-Info.plist` | **`ios/Runner/GoogleService-Info.plist`** |

**Gradle:** The admin Android app must apply the Google Services plugin (same as client), typically in `android/settings.gradle.kts` / `android/app/build.gradle.kts` with `id("com.google.gms.google-services")`.

**Same project, different app ID:** If the admin Flutter app uses a **different** `applicationId` (Android) or **bundle identifier** (iOS) than the client, the copied files are **not** valid until you register those app IDs in the **same** Firebase project and download **new** config files from the Firebase console. If admin and client literally share the same package names, the copies are identical and fine.

**Dart bootstrap:** Call `await Firebase.initializeApp();` before using RTDB (see `snippets/firebase_main_merge.txt`). This repo does **not** use `firebase_options.dart`; native config files supply defaults.

---

### Google Maps SDK + Directions API (HTTP)

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/core/config/google_api_config.dart` | **Same path:** `lib/core/config/google_api_config.dart` |

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/core/infrastructure/services/location_services/google_directions_service.dart` | **Same path** under `lib/core/infrastructure/services/location_services/` |
| `lib/core/infrastructure/services/location_services/location_map_picker_page.dart` | Same folder |
| `lib/core/infrastructure/services/location_services/location_permission_helper.dart` | Same folder |
| `lib/core/infrastructure/services/location_services/location_service.dart` | Same folder |
| `lib/core/infrastructure/services/location_services/location_choice_dialog.dart` | Same folder |
| `lib/core/infrastructure/services/location_services/address_geocoding.dart` | Same folder |

**Keys (two concepts):**

1. **Maps SDK** (map tiles / `GoogleMap` widget): Android `local.properties` → `GOOGLE_MAPS_API_KEY` + manifest placeholder; iOS `AppDelegate` `GMSServices.provideAPIKey(...)`. See `snippets/`.
2. **Directions API** (HTTP, polylines): `GoogleApiConfig.directionsApiKey` — use `--dart-define=GOOGLE_DIRECTIONS_API_KEY=...` in CI or replace `defaultValue` locally. Enable **Directions API** on the Google Cloud project that owns that key.

---

### Live tracking UI (map card)

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/core/presentation/widgets/live_tracking_map_card.dart` | **Same path:** `lib/core/presentation/widgets/live_tracking_map_card.dart` |

---

### Order status screen (timeline + RTDB bloc)

| Path in this bundle | Put in admin app at |
|----------------------|---------------------|
| Whole folder `lib/features/basket/order_status_section/` | **Same path** (or rename feature folder in admin and update every import + router). |

Files inside:

- `presentation/pages/order_status_page.dart`
- `presentation/bloc/order_status_bloc.dart` (+ `order_status_event.dart`, `order_status_state.dart` — part files)
- `presentation/utils/order_status_step_labels.dart`
- `presentation/widgets/*` (hero image, timeline, badge, problem banner, rail)

---

### Shared enums / timeline index / assets helper

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/core/common/utils/order_status_step_index.dart` | **Same path** |
| `lib/core/common/utils/asset_manager.dart` | **Merge** into your admin `asset_manager` **or** same path if you do not have one yet (it also lists other app images — trim if needed). |

| File in this bundle | Put in admin app at |
|---------------------|---------------------|
| `lib/features/delivery/order/order_details/domain/entities/order_status.dart` | **Same path** if you mirror this feature layout |

> **Imports:** Copied Dart files still say `package:jeeb_app/...`. In the admin app, run a global replace: `package:jeeb_app/` → `package:<your_admin_package>/`.

Current internal imports expect:

- `order_status_step_index.dart` → imports `features/delivery/order/order_details/domain/entities/order_status.dart`
- `order_status` bloc/widgets → same `OrderStatus` entity path as `order_status_page.dart`

If your admin app keeps `OrderStatus` elsewhere, change those imports once.

---

### Full client order feature (list + details + API + list tap rules)

| Path in this bundle | Put in admin app at |
|----------------------|---------------------|
| **`lib/features/delivery/order/`** (entire tree: `list_order`, `order_details`, `create_order`, `manage_order`) | **Same path** under `lib/features/delivery/order/` |

This includes **`order_list_item.dart`** (terminal → `orderDetails`, else → `orderStatus` with delivery coords) and the full **order details** stack (bloc, repository, `order_details_content.dart`, cards, map section).

### Product list module (required by order line items UI)

| Path in this bundle | Put in admin app at |
|----------------------|---------------------|
| **`lib/features/product/list_product/`** (entire tree) | **Same path** — `OrderProductsSection` imports `ProductEntity` and `ProductListItem`. |

---

### Tracking hero images

| Path in this bundle | Put in admin app at |
|---------------------|---------------------|
| `assets/images/order_status/*.png` (7 files) | `assets/images/order_status/` |

Register in `pubspec.yaml`:

```yaml
  assets:
    - assets/images/order_status/
```

---

## 3. Snippets you must merge manually

All under `snippets/`:

| File | Merge into |
|------|------------|
| `pubspec_dependencies.yaml` | Admin `pubspec.yaml` |
| `dependency_injection_merge.txt` | Your GetIt / `dependency_injection.dart` |
| `firebase_main_merge.txt` | Your `main.dart` — `Firebase.initializeApp()` |
| `route_order_status_merge.dart` | Your `route_manager.dart` (or equivalent) + add `Routes.orderStatus` from `routes_constant.txt` |
| `order_flow_translation_keys.json` | Merge strings into `en.json` / `ar.json` (see `ORDER_FLOW_README.md`) |
| `android_local.properties.example` | Real `android/local.properties` (gitignored) |
| `android_application_manifest_meta.xml` | Inside `<application>` in `AndroidManifest.xml` |
| `android_build_gradle_kts_merge.txt` | `android/app/build.gradle.kts` |
| `ios_appdelegate_merge.swift` | `ios/Runner/AppDelegate.swift` (and add Google Maps iOS dependency per Flutter `google_maps_flutter` docs) |

---

## 4. Firebase setup (admin app)

1. Copy **`firebase_config/`** files into `android/app/` and `ios/Runner/` as in the table above (same Firebase project as client = same files, **if** package IDs match).
2. Ensure Android **`google-services`** Gradle plugin is applied (match your client `build.gradle.kts` setup).
3. Call `Firebase.initializeApp()` before using RTDB — see `snippets/firebase_main_merge.txt`.
4. Read `docs/Firebase_Realtime_Database.md` for RTDB path contract.

---

## 5. Navigation contract for `OrderStatusPage`

When pushing the tracking route, pass at minimum:

```dart
arguments: {
  'orderId': orderIdString,
  'initialStatus': statusWireString, // e.g. PENDING, ON_THE_WAY
  'deliveryLatitude': lat,   // optional, from order deliveryCoordinates
  'deliveryLongitude': lng, // optional
};
```

---

## 6. Security

- Do **not** commit production API keys to public repositories.
- Restrict Maps SDK keys by Android package / iOS bundle ID in Google Cloud Console.
- Restrict Directions key by IP or use a backend proxy if the admin app is not a mobile store build.

---

## 7. File manifest (everything in this bundle)

- `PLACEMENT_GUIDE.md` (this file)
- `ORDER_FLOW_README.md` (navigation + what each folder does)
- `firebase_config/android/app/google-services.json`
- `firebase_config/ios/Runner/GoogleService-Info.plist`
- `docs/Firebase_Realtime_Database.md`
- `snippets/*` (merge-only helpers + `order_flow_translation_keys.json`)
- `assets/images/order_status/*.png` (**7** hero images — verify on disk)
- `lib/core/config/google_api_config.dart`
- `lib/core/infrastructure/realtime/order_status_rtdb_service.dart`
- `lib/core/infrastructure/services/location_services/*.dart` (6 files)
- `lib/core/common/utils/asset_manager.dart`
- `lib/core/common/utils/order_status_step_index.dart`
- `lib/core/presentation/widgets/live_tracking_map_card.dart`
- `lib/features/basket/order_status_section/**` (tracking UI + bloc)
- `lib/features/delivery/order/**` (full order feature: list, details, create, manage)
- `lib/features/product/list_product/**` (product entity + list row widgets for order details)

---

## 8. What the other AI should do first

1. Copy `lib/` tree + `assets/` into admin project.
2. Replace `package:jeeb_app/` with admin package name.
3. Merge `snippets/` into pubspec, DI, routes, Android, iOS.
4. Wire localization: copied widgets use `AppTranslation.*` — map those keys in admin or replace with strings.
5. Wire theme: `ColorManager`, `AppPadding`, etc. — align with admin theme or replace imports.
6. `flutter pub get` and fix any remaining missing imports.
