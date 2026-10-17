# IT-Talent Mobile (`ittalent_mobile`)

The cross-platform mobile companion application for IT-Talent, built with **Flutter**, designed with architectural and stylistic parity to [`ittalent-web`](../ittalent-web).

---

## Quickstart

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Run unit and widget tests
flutter test

# 4. Run app on simulator or connected device
flutter run
```

---

## Architectural Parity with `ittalent-web`

- **Design System:** 1:1 port of `DESIGN.md` tokens (Ember `#f2470c`, warm canvas `#fafaf8`, status tint pairs, 12px controls, 16px cards) via `AppColors` `ThemeExtension`.
- **UI Primitives:** Atomic widgets in `lib/components/ui/` (`AppButton`, `AppCard`, `AppBadge`, `AppInput`, `AppSkeleton`) mirroring web shadcn/ui.
- **State & Queries:** `flutter_riverpod` mimicking TanStack Query (`AsyncValue` with `.when()`).
- **Navigation:** `go_router` declarative path routing (`AppRoutes`).
- **Icons:** `lucide_icons` matching `lucide-react` icon names.
- **Localization:** `easy_localization` using shared JSON translation bundles from web (`assets/translations/{en,vi}.json`).
- **API Client:** Dio with `flutter_secure_storage` interceptor.

For full developer guidelines and coding rules, see [AGENTS.md](./AGENTS.md).
