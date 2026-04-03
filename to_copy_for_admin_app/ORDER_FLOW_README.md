# Order list → details vs live status (read this first)

This folder now includes **everything** for:

- Tapping an order in the list: **terminal** orders → **order details**; **non-terminal** → **order status (tracking)**.
- **Order details** screen: “Track order” button + map when `ON_THE_WAY`, same rules.
- **Order status** screen: timeline hero images, Firebase RTDB listeners, live map.

## Navigation rules (same as code)

| Situation | Where the user goes |
|-----------|---------------------|
| Order status is **delivered**, **completed**, **cancelled**, or **rejected** | **`Routes.orderDetails`** (full details only). |
| Any **other** status (pending, preparing, on the way, …) | **`Routes.orderStatus`** (live tracking + timeline). |

Implemented in:

- `lib/features/delivery/order/list_order/presentation/widgets/order_list_item.dart` — `onTap` uses `orderStatusIsTerminal`.
- `lib/features/delivery/order/order_details/presentation/widgets/order_details_content.dart` — shows “Track order” only when **not** terminal; passes `deliveryLatitude` / `deliveryLongitude` when opening tracking.

Helper: `lib/core/common/utils/order_status_step_index.dart` (`orderStatusIsTerminal`).

## Route arguments for `Routes.orderStatus`

```dart
{
  'orderId': order.id,
  'initialStatus': order.status,
  if (order.latitude != null) 'deliveryLatitude': order.latitude,
  if (order.longitude != null) 'deliveryLongitude': order.longitude,
}
```

## Where the code lives in this bundle

| Area | Path under `lib/` |
|------|-------------------|
| **Order list** (tap logic) | `features/delivery/order/list_order/` |
| **Order details** (page, bloc, widgets, API) | `features/delivery/order/order_details/` |
| **Create / manage order** (if you use same API) | `features/delivery/order/create_order/`, `manage_order/` |
| **Live status UI + bloc** | `features/basket/order_status_section/` |
| **Product rows on order details** | `features/product/list_product/` (needed by `OrderProductsSection`) |
| **RTDB service** | `core/infrastructure/realtime/order_status_rtdb_service.dart` |
| **Timeline step images** | `asset_manager.dart` + **`assets/images/order_status/*.png`** (7 files) |

## Images (hero on tracking screen)

Physical files in this bundle:

`assets/images/order_status/`

- `pending.png`, `confirmed.png`, `preparing.png`, `ready_for_pickup.png`, `assigned.png`, `on_the_way.png`, `delivered.png`

Register in `pubspec.yaml`:

```yaml
  assets:
    - assets/images/order_status/
```

## Translations

Merge keys from `snippets/order_flow_translation_keys.json` into your `en.json` / `ar.json` (or equivalent).  
If you use `AppTranslation`, mirror `app_translation.dart` getters for those keys.

## Still merge manually (native / router / DI)

See **`PLACEMENT_GUIDE.md`** and the **`snippets/`** folder: Firebase config, `pubspec`, router case, `OrderStatusRtdbService` registration, Maps keys.

After copy: global replace `package:jeeb_app/` → `package:<your_app>/`.
