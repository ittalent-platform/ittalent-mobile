# Mobile AI Agent Directives (AGENTS.md)

All AI agents and human developers working in `ittalent_mobile` MUST follow the structure, reuse, and design rules below. The tokens, components, and layout match `DESIGN.md` in `ittalent-web`.

---

## 1. Commands

```bash
flutter run                                      # Run on connected device / simulator
flutter analyze                                  # Run static analysis
dart format --output=none --set-exit-if-changed .# Check formatting
dart format .                                    # Auto-format all Dart files
flutter test                                     # Run unit and widget tests
flutter test test/widget_test.dart               # Run a single test file
```

Always run `flutter analyze` and `flutter test` before declaring work done.

---

## 2. Architecture

Flutter 3.x + Dart 3.x, Riverpod (State & Queries), `go_router` (declarative routing), Dio + FlutterSecureStorage (API Client), `easy_localization` (en, vi).

```text
lib/
├── api/                         # client.dart (Dio, auth interceptors), api_error.dart, generated/
├── app/                         # app.dart (MaterialApp), router.dart (go_router, shell, tabs)
├── auth/                        # auth_notifier.dart, auth_state.dart, token_storage.dart
├── components/
│   ├── ui/                      # Atomic primitives (AppButton, AppCard, AppBadge, AppTag, AppInput, AppSkeleton)
│   ├── common/                  # Reusable composites (AppEmptyState, AppErrorState, AppStatusPanel)
│   └── layout/                  # ScreenScaffold (Safe area, screen padding)
├── config/                      # env.dart, routes.dart
├── features/<area>/<feature>/   # Vertical feature slices (e.g. applicant/applications)
│   ├── <feature>_screen.dart    # Screen widget
│   ├── <feature>_constants.dart # Statuses, tone mappings, limits
│   ├── <feature>_providers.dart # Riverpod query providers (TanStack Query equivalent)
│   └── widgets/                 # Feature-specific subwidgets
├── theme/                       # app_colors.dart, app_radius.dart, app_typography.dart, app_theme.dart
└── utils/                       # double_brace_asset_loader.dart (translations); wording/format helpers live in their feature (e.g. applicant/jobs/jobs_format.dart)
test/                            # Unit & widget tests mirroring features
assets/translations/             # en.json, vi.json (1:1 matching ittalent-web locales)
```

### Feature Slice Layout
Each feature slice owns its screens and logic:
```text
features/<area>/<feature>/
├── <feature>_screen.dart         # Screen widget composing UI/common primitives
├── <feature>_constants.dart      # Status maps, limits, keys
├── <feature>_providers.dart      # Riverpod query providers over ApiClient
└── widgets/                      # Feature-specific subwidgets
```
- Never import from another feature slice. Anything needed across two features moves to `components/common/`, `components/ui/`, `api/`, or `config/`.
- UI primitives in `components/` must not import from `features/`.

---

## 3. Coding Rules

- **Strict Typing:** No `dynamic` in business logic; parse API DTOs into typed Dart classes.
- **No Hardcoded Hex Colors:** NEVER use raw `Color(0xFF...)` inside widget code. Always use `context.colors.<token>` from `lib/theme/app_colors.dart`.
- **No Hardcoded Text:** User-facing strings must use `tr('key')` from `easy_localization`. Keys mirror `ittalent-web/src/locales/{en,vi}/common.json`.
- **No Magic Numbers:** Status strings, query keys, and numerical thresholds belong in `*.constants.dart` or `config/`.
- **Borders, Not Shadows:** Follow `DESIGN.md` — static surfaces use borders (`colors.border`), not heavy elevation drop shadows.
- **Status is a Word in a Tint Pair:** Use `AppBadge(tone: BadgeTone.xyz, label: '...')` — never color alone.
- **API Errors:** Surface errors using `AppErrorState` or callout cards with a helpful message and retry action.

---

## 4. Component Reuse First

Before building custom widgets, always reuse existing primitives:

| Need | Widget to Use |
| :--- | :--- |
| Action Button (Ember, Outline, Ghost, Destructive) | `AppButton` (`components/ui/app_button.dart`) |
| Surface Card (16px border-first) | `AppCard` (`components/ui/app_card.dart`) |
| Status Badge (Tint pairs) | `AppBadge` (`components/ui/app_badge.dart`) |
| Plain Tag (type, level) | `AppTag` (`components/ui/app_tag.dart`) |
| Form Input / Text Field | `AppInput` (`components/ui/app_input.dart`) |
| Loading Placeholder | `AppSkeleton` (`components/ui/app_skeleton.dart`) |
| Empty List / Empty View | `AppEmptyState` (`components/common/app_empty_state.dart`) |
| Error State with Retry | `AppErrorState` (`components/common/app_error_state.dart`) |
| Centered Outcome Card | `AppStatusPanel` (`components/common/app_status_panel.dart`) |
| Safe Area & Screen Container | `ScreenScaffold` (`components/layout/screen_scaffold.dart`) |
| Icons | `LucideIcons.<name>` (`lucide_icons` package) |

---

## 5. Web vs Flutter Translation Guide for Web Developers

| Concept in `ittalent-web` | Equivalent in `ittalent_mobile` |
| :--- | :--- |
| `<div className="bg-card border p-4">` | `AppCard(child: ...)` |
| `<Button variant="outline">` | `AppButton(variant: AppButtonVariant.outline, ...)` |
| `useQuery(['applications'], fetchFn)` | `final asyncApps = ref.watch(myApplicationsProvider);` |
| `useNavigate()('/jobs')` | `context.go('/jobs');` |
| `t('accountNav.myApplications')` | `tr('accountNav.myApplications')` |
| `localStorage` / Cookies | `TokenStorage` (`flutter_secure_storage`) |
| `lucide-react` | `lucide_icons` (`LucideIcons.briefcase`) |
