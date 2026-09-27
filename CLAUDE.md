# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Baytouti (بيتوتي) — the producing family's app**: the vendor side of a
Kuwaiti marketplace for home-made goods. A family signs up, waits for
approval, then runs its store: orders, products, offers, the store profile.

The design is `Baytouti Vendor App.dc.html` in the Claude Design project
"Dual App Design: Customer and Vendor" (`abedcbee-1f5b-4ec4-b8fb-6675543c7a53`),
beside `Baytouti Customer App.dc.html` and **`Baytouti API Spec.dc.html` — the
API contract** every model here reads. Read them with the `DesignSync` tool
(`get_file`). `lib/core` started as a copy of the Cloak vendor app's core
(`../cloack_vendor`) and was re-branded here; the two are not linked.

**There is no server yet.** Every feature runs on fixtures. The contract names
the base URL `https://api.baytouti.com/v1/` and every path is declared in
`ApiEndPoint`, but no endpoint is called.

## Commands

The `flutter` on `PATH` is **3.47.3 (Dart 3.13.3)**, which `sdk: ^3.13.3`
needs; the older SDKs in `~/flutter_ver` cannot resolve it.

```bash
flutter pub get
flutter analyze                    # must be clean — no issues, not "no errors"
flutter test                       # whole suite
flutter test test/route_guard_test.dart
flutter run

# The screen tour: signs in and up through the real UI on a simulator and
# photographs every screen (iPhone 16 Pro is the design's 402×874 frame).
SCREENSHOT_DIR=build/screenshots flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screen_tour_test.dart -d "iPhone 16 Pro"
```

**Do not run the app, the tests or the screen tour until the user asks.**
`flutter run`, `flutter test` and `flutter drive` wait for the user's go-ahead,
even to check a change. (The Stop hook below still runs `flutter analyze` —
static analysis, not a run.)

**Do not run `dart format`.** The core is not formatted with the current
formatter (Dart 3.7 changed the style), so running it rewrites unrelated
indentation across most files. Match the surrounding style by hand: `=>`
bodies continue at 6 spaces with their block indented 8.

**Project hooks** (`.claude/settings.json`, scripts in `.claude/hooks/`)
enforce three of these rules: `dart format`/`flutter format` is blocked, a
page file past 200/250 lines is flagged after an edit, and a turn cannot end
while `flutter analyze` reports anything (it skips the run when no Dart file
changed since the last clean one).

### Build-time switches

```bash
flutter run --dart-define=USE_MOCK_DATA=false      # see below
flutter run --dart-define=BASE_URL=https://staging.example.com/v1/
```

`useMockData` (in `core/di/injection_container.dart`) defaults to **true**.
Since no feature has a remote source yet, it decides only what the onboarding
button says ("Simulate approval" vs "Check status"). When a feature gains a
remote source, register it beside the mock and pick between them with it —
the doc comment there shows the shape.

`lib/main.dart` is one line; everything before the first frame is in
`core/app/bootstrap.dart`, in order: binding → localization → timezone → DI →
session restore → `runApp`.

## Current state

Every screen of the design exists: onboarding (V01), dashboard (V02), orders
(V03), order details (V04), products (V05), the product form (V06), offers
(V07), store profile (V08) and notifications (V09). Not in the vendor design,
and built in its style: the splash, sign-in / sign-up and the code screen
(from the customer design's screens 02–03), editing a product (the V06 form
over `/products/:id`), the reject sheet, and an account card (language,
sign-out) at the foot of the store tab.

- **Fixtures, and how they behave.** Each feature has a `*DataSource`
  interface and a `*MockDataSource` answering in the contract's JSON shapes,
  parsed by the same models a remote source will use. They live as lazy
  singletons, so changes last the run (an accepted order, a new product), and
  they refuse what the server would (a move that is not `next_status`,
  publishing before review, a fourth offer). `OrderFixtures` and
  `ProductFixtures` are shared with the dashboard fixture so its counts agree
  with the tabs. Latency is `mockLatency` (350 ms).
- **Fixtures answer in the app's language** (`MockLocale`), as the contract
  says the server does (`Accept-Language`). They read the stored language
  code, which `LocaleSync` (`core/app/`) writes whenever the locale changes —
  nothing wrote it before, so the network header was always Arabic. Tabs stay
  alive across a switch, so they re-read through `LocaleChangeListener`.
- **Who is signed in** reaches the fixtures through the token, as it reaches
  the server: `MockSessionToken` encodes new-or-returning family, phone and
  family name. The sign-in tab opens the fixture family ("أسرة أم عبدالله",
  approved); the sign-up tab opens a new family under review. **Any number
  gets code `1234`**, which the code screen states on fixtures (`demo_code`).
  A mock token sent to a real server is refused and the 401 handling ends the
  session.
- **Auth** follows the contract: `POST /auth/request-otp` (`mode` login or
  signup, `full_name` for signup) → `POST /auth/verify-otp` → token and user,
  kept by `AuthLocalDataSource`. The phone is entered in
  `PhoneTextFormField` (Kuwait and Egypt, Kuwait first) and sent as the
  E.164 number the field reports — see Localization.
- **The onboarding gate**: `AccountGate` wraps the shell and every pushed
  route; until `GET /vendor/application` says `approved`, the family sees
  `ApplicationStatusPage` (V01). `ApplicationCubit` is app-wide and follows
  `SessionNotifier`. On fixtures "Simulate approval" moves the review a step
  (`advanceReview`); against the API that method should re-read the
  application — approval is the back office's.
- **Orders**: `GET /vendor/orders?state=all|new|preparing|done` answers with
  every tab's `counts`; details carry `next_status` and `can_reject`, and the
  one advance button sends `next_status` (the server owns the machine). Reject
  asks for a `reason` in a sheet. The details page pops `true` after a move so
  the opener re-reads. The customer's number is masked; the call button says
  calling is coming (the proxied-call endpoint is not specified).
- **Products**: list with debounced search and the publish switch
  (`PATCH …/visibility`, refused before review or at stock 0). The form covers
  every field of `POST /vendor/products`; photos upload as soon as they are
  picked (`POST /uploads`, the `uploads` feature) and go out as
  `image_upload_ids`, first is the cover. Review needs a photo; a draft does
  not. `GET /vendor/products/{id}` and the images' `upload_id` are guesses —
  the contract lists only the `PATCH`.
- **Offers**: store-wide percentage discounts inside the contract's `limits`
  (5–70 % in 5s, three at once) with an end date (`ends_at` is required by the
  contract, not drawn in the design).
- **Store**: cover, name, story, city, documents; `PATCH /vendor/store`.
  Cities are sent as keys (`hawalli`); the contract's example sends the
  Arabic name — check which the server wants.
- **Notifications**: opening the list marks everything read (the bell's dot
  goes) while the rows keep their unread highlight for the visit.
- **App-wide cubits** (`core/app/app.dart`): `NetworkCubit`, `AuthCubit`,
  `ApplicationCubit`, `OrdersBadgeCubit` (fed by whichever screen read the
  server's new-order count last — it reads nothing itself),
  `NotificationBadgeCubit`.
- **Guessed response shapes.** The contract gives examples, not schemas. Money
  is read from `*_fils` and times from ISO fields (the contract's conventions),
  never from its `_display` strings, so the app formats both itself
  (`Money.display`, `relativeTimeLabel`). Each model's doc comment shows the
  JSON it reads and names its guesses.
- **Not done**: the vendor sign-up *application* form (documents upload,
  `POST /vendor/applications`) is not in the design; the splash is Flutter
  only (no native splash or launcher icons generated); identifiers are still
  the template's `com.example.baytoti_vendor`; Android release is signed with
  the debug key.

## Architecture

Clean architecture per feature under `lib/features/<name>/`, with layers added
only as needed: `data/` + `domain/` + `presentation/`.

Data flows one way: **data source → repository → use case → cubit → widget**.
A cubit depends on use cases, never on a repository. Only the data layer knows
about HTTP or storage; everything above sees `Either<Failure, T>` (dartz).

`lib/features/orders` is the reference feature (pagination, a details screen
with actions, fixtures behind the contract); `auth` for forms and sessions;
`products` for debounced search, uploads and a form with its own controllers.

### Dependency injection

`get_it` as `sl`, wired once by `initDependencies()` in
`core/di/injection_container.dart` (a `part of` `di_exports.dart`). A feature
adds its own `_registerXFeature()` there. The registration style is
deliberate:

- `registerSingleton` — core services, created eagerly at startup
- `registerLazySingleton` — data sources, repositories, use cases, app-wide
  cubits
- `registerFactory` — one cubit per screen

`core/di/di_exports.dart` re-exports the whole core surface, the app-wide
cubits and `sl`, so a feature reaches everything with one import.

Cubits that outlive a route are lazy singletons provided at the root in
`core/app/app.dart`. A second instance would let two screens disagree about
who is signed in.

State that belongs to an account must be read when a session begins and
forgotten when it ends. Listen to `SessionNotifier`, not to a cubit — it is
the one place every way of gaining or losing a session reports to: sign-in, a
restored token, sign-out, and an unrecoverable 401. Forgetting is local: a
sign-out must never call a `DELETE`.

### Error handling — MANDATORY

This project uses `Either` for all fallible operations.
Errors are caught in the DATA SOURCE, never in the repository.
Do NOT introduce the "data source throws, repository catches" pattern.
If existing code contradicts these rules, follow the rules and flag the file.

Let `AppError` be the project's error type and `Failure` its `Left` side.
Use whatever the project already defines — do not invent a new error type.
**In this project that type is `Failure`** (`core/domain/failure.dart`):
**sealed** and `Equatable`, with `NetworkFailure` (offline, retryable),
`ServerFailure`, `CacheFailure`, `UnexpectedFailure` and `ValidationFailure`
(422, carries `fieldErrors`). The subtype is the point — a cubit has to tell
offline from refused.

What sits underneath: `NetworkServiceImpl` throws raw exceptions.
`AppException` (`core/exceptions/app_exceptions.dart`) is **sealed**:
`ConnectionException`, `RequestException`, `RedundantRequestException`,
`SessionExpiredException`, `CacheException`. `checkedResponse(response)` parses
the envelope and throws `RequestException` unless the call succeeded.
`mapExceptionToFailure(e, fallbackMessage: '<key>')`
(`core/domain/failure_mapper.dart`) turns those exceptions into a `Failure` —
call it from the data source's catch, and do not re-derive the mapping per
feature. Fixtures throw the same `RequestException`s the server would
(`RequestException('order_not_found', statusCode: 404)`).

`mapExceptionToFailure` is the boundary where a message becomes safe to show.
Below it a message may be a translation key, the API's own prose, or developer
text. **Above it, `Failure.message` is always displayable** — it resolves
through `.tr()`, which returns prose unchanged. So any sentinel string used as
an error message needs an entry in `assets/translations/`, or users read the
raw slug. Add it to `errorMessageKeys` in `test/translations_test.dart`.

#### Data source — the ONLY place that catches

Every data source method returns `Future<Either<AppError, T>>`.
Never `Future<T>`. Never `Future<T?>`. Never a raw model.

In this project a method's whole body goes inside `guardedRequest('XDataSource.method', () async { … }, fallbackMessage: '<key>')`
(`core/network/guarded_request.dart`): it logs through `logError`, maps an
`AppException` with `mapExceptionToFailure`, and turns anything else into an
`UnexpectedFailure`. `messageForStatus: {404: 'order_not_found'}` renames one
status. Local sources use `guardedStorage` (storage errors → `CacheFailure`,
unparseable stored data → `UnexpectedFailure`).

- Wrap every call in try/catch. Nothing escapes as an exception.
- Never return an empty/argument-less error. Every `Left` carries either a
  server-provided message or a translation key.
- Every catch logs before returning, with the method name as the reason.
- Distinguish the two failure paths and never merge them:
  - the transport/client reported a failure → map it to a typed error
  - anything else (parsing, type errors, unexpected null) → map it to a
    separate "unexpected" error
  Never label a parsing failure as a connection error — it lies to the user.
- Keep model parsing inside the try, but classify it as unexpected, not network.
- Never swallow: `return []`, `return null`, or `return Right(fallback)` on
  failure are all forbidden.
- If one method needs to rename a specific error (a 404 → "not found"), do it
  in the mapping, still returning a `Left`.

Models read with the lenient helpers in `core/utils/json_read.dart`
(`asInt`, `asString`, `asMapList`, `requireString`, …): a number sent as a
string still reads, and only what a model cannot exist without — an id —
throws.

#### Repository — no try/catch, pure orchestration

- Never wrap a data source call in try/catch. It already returns `Either`.
- Single-call methods are pass-through expressions:
  `Future<Either<AppError, T>> x() => _dataSource.x();`
- For multi-step flows, fold once and guard the extra steps explicitly.
  Side effects (secure storage, cache, token refresh, analytics) are NOT
  covered by the `Either` and WILL escape as exceptions if left unguarded:

```dart
  final result = await _dataSource.doThing(...);
  return result.fold(
    Left.new,
    (model) async {
      try {
        await _sideEffect(model);
        return Right(model);
      } catch (e, s) {
        log(e, s, reason: '_sideEffect');
        return Left(/* specific error for the side-effect failure */);
      }
    },
  );
```

- `fold` is not async-aware. Never write bare `await result.fold(...)` where
  one branch returns a Future and the other returns null.
- If the repository combines several sources (remote + cache), decide the
  fallback here — that is the repository's job, not the data source's.

#### Presentation (cubit / bloc / controller) — never catch

- Never write try/catch around a repository call.
- Always `fold` into an emitted state. Both branches must emit.
- The error branch emits a specific error status, never leaves a loading state.
- Read the message off the error object; do not build user-facing strings here.
- Only exception: platform SDK calls not behind a repository (social sign-in,
  camera, permissions). There, catch — but check for user cancellation first
  and do not emit an error state for it. `pickGalleryPhotos`
  (`core/utils/photo_picker.dart`) is this app's one.
- Use `fold`, not `getOrElse`, to read an `Either` from a repository: the
  right side is a model at runtime, and a default typed as the entity fails
  `getOrElse`'s runtime check.

#### Adding a new feature

Copy the shape of an existing feature. The layer signatures are:

- data source:   `Future<Either<AppError, T>>`
- repository:    `Future<Either<AppError, T>>`
- presentation:  `Future<void>` + emit

Any deviation from this triple is a bug, not a style choice.

### Networking

**Check the envelope first when the API lands.** The core still parses Cloak's
Laravel envelope: `ApiResponse` (`core/network/api_response.dart`) expects
`{success, message, data, errors}` and `checkedResponse` checks `success`. The
Baytouti contract answers bare objects and refuses with
`{"error": {"code", "message", "field", "details"}}`. Whichever the server
really does, adapt `ApiResponse` / `api_error_handler.dart` once, in core —
never per feature. The contract's `code`s the app handles: `otp_invalid`,
`otp_expired`, `rate_limited`, `vendor_not_approved`, `product_pending_review`.

`ApiEndPoint` (`core/network/api_endpoints.dart`) holds every path, relative to
`baseUrl`, which already carries the version prefix **and a trailing slash**
— dropping it collapses `/v1/vendor/orders` into `/v1vendor/orders`.

Authenticated calls get the token for free by passing no `headers`. A 401 on
a call sent with the stored token ends the session: `NetworkServiceImpl` drops
the token and throws `SessionExpiredException`, and
`AuthCubit.sessionExpired()` forgets the rest. The contract does issue a
`refresh_token` and lists `POST /auth/refresh`; `TokenStore` keeps it, but
nothing refreshes yet. Pass `skipAuthRefresh: true` for the public endpoints
(the OTP pair), where a 401 means a wrong code, not a dead session.

**Nothing may reach the network before `runApp`.** The requests inspector's
controller is a singleton created by whoever asks first; when that is the Dio
interceptor instead of the `RequestsInspector` widget, it is created disabled
and silently drops every request for the rest of the run.

Limits and lengths live on the **domain entity** (`ProductRules`,
`StoreRules`, `FamilyName`, `KuwaitPhone`), not only in a validator or a
widget, so the UI and the wire cannot drift apart. The contract states none,
so these are the app's own until the API publishes its rules. **Money is
integer fils** (`price_fils: 4250` = 4.250 KWD); `Money.display(fils)` prints
it with Western digits and the currency in the app's language.

### Pagination

The core pages by number: `ApiResponse` reads `meta` (siblings of `data`) into
`currentPage`, `lastPage`, `perPage`, `total`, `hasMore`, and one page becomes
`Paged<T>` (`core/domain/paged.dart`) with `hasMore`, `nextPage` and `append`.
The fixtures answer with `meta` inside the payload. **The contract pages with
cursors** (`?cursor=&limit=` → `{items, next_cursor}`) — if the server does,
the list models and query objects change together.

**`meta` decides whether another page exists. Never the row count.** A
filtered page can be shorter than `perPage` without being the last one, and a
page past the end comes back empty while `meta` still reports the real
`lastPage`.

A paginated cubit owes three guards:

1. **`loadMore()` returns early** when a load is in flight or `hasMore` is
   false. `NetworkService` fingerprints in-flight requests by URL and query,
   so a double-fired page surfaces as a spurious `RedundantRequestException`.
2. **A generation counter.** Every read that replaces the list bumps it; a
   page that lands under an older generation is dropped.
3. **A failed next page keeps the list**, reporting through a toast. Only a
   failed *first* read becomes an error screen.

The trigger is `LazyLoadScrollView(isLoading:, onEndOfPage:, child:)` over a
single scrollable (`CustomScrollView` + slivers). **Pass `isLoading`**: the
widget latches after firing and re-arms only when it goes false. The package
is vendored under `third_party/` because every published version caps at
`sdk: <3.0.0`; see its `VENDORING.md`.

A search box that hits the server is debounced in the cubit with rxdart —
`BehaviorSubject` → `debounceTime(500ms).distinct()`, closed in `close()`.
Query objects **omit absent values**: the network layer does not strip nulls,
and `q=` on the wire searches for the empty string.

### Routing

One `GoRouter` in `core/routing/app_router.dart`, paths in `routes.dart`. The
five tabs (home, orders, products, offers, store) are `StatefulShellRoute`
branches; order details, the product form and notifications are pushed on the
root navigator over the tab bar, each behind `AccountGate`. The product form
is registered as `/products/new` before `/products/:id`, which would read
"new" as an id (the route test pins it).

The guard reads `SessionNotifier` (a `ChangeNotifier` used as
`refreshListenable`), **not** a cubit, so a sign-out re-runs it immediately.
The auth cubit should be the only thing that calls `signedIn()`/`signedOut()`.

Adding a route means adding it to `protectedRoutes` or `publicRoutes`.
`test/route_guard_test.dart` asserts the two sets cover every registered route
exactly, so a forgotten classification fails a test instead of silently being
reachable.

## Presentation conventions

**Page files stay under 200 lines, 250 absolute maximum.** When a page grows
past that:

- A widget goes in its own file under that feature's `presentation/widgets/`.
  Never leave private `StatelessWidget` classes at the bottom of a page file.
- Layout specific to one page stays in that page as a `_buildX` method.

Extract whole coherent units — a form with its own controllers — and give the
extracted widget a callback API (`onSubmit(Params)`) so the page keeps only
navigation, cubit wiring and messages. When the submit button lives outside
the form (a bottom bar), the page reaches the form through a `GlobalKey` to
its public state and calls `submit()`, which answers the values or null
(`ProductForm`, `StoreDetailsCard`).

**Provider placement:** put `BlocProvider` in an outer widget and the
consumer in a separate inner one (`XPage` → `_XView`). A provider created
inside the same `build` that reads it is a descendant of that element, so
`context.read<T>()` in a `State` callback throws `ProviderNotFoundException` —
it renders fine and only fails on tap.

**Responsive sizing — ScreenUtil everywhere.** The design frame is 402×874
(`SizeConfig`). Every literal dimension carries its unit: `.w` for widths and
horizontal space, `.h` for heights and vertical space, `.r` for radii and
square boxes, and type goes through `AppStrings` (which applies `.sp`). A
widget's size parameters take already-scaled values, and its defaults scale
themselves. Type scales by the smaller axis, as boxes do.

**Styling:** colors come from `context.palette`, an `AppPalette` `ThemeData`
extension holding the design's tokens — `bg`, `surf`, `surf2`, `muted`,
`line`, `line2`, `disabled`, `fg`, `ink`, `fg2`, `fg3`, `accent` (the family
green), `accentHi`, `accentInk`, `accentSoft`, `accentSoft2`, `onAccent`,
`amber`/`amberBg`/`amberInk` (attention) and `bad`/`badBg`. `gold` also
exists, as an alias of `accent`, only because `PhoneTextFormField` (brought
from Cloak unchanged) uses it — write `accent` in new code. The design is
light only; a dark set would be a second palette and theme. Type is
`AppStrings.textNNwNNN` named after the design's `font:` shorthand, color
applied at the call site: `AppStrings.text19w800.c(p.fg)`. Latin text is
Archivo and Arabic falls through to IBM Plex Sans Arabic
(`fontFamilyFallback`), as the design's font stack does. Icons are the
design's own SVG paths (`AppIcon(AppIcons.bell, size: 16.r)`), mirrored in RTL
where directional. Shared widgets are in `core/widgets/` (`ScreenHeader`,
`AppCard`, `PrimaryButton`, `PillChip`, `AppSwitch`, `CapsLabel`, …).

**The header kicker** is the screen's name in the *other* language
(`kicker_*` keys: "Dashboard" in `ar.json`, اللوحة in `en.json`).
`CapsLabel` uppercases and letter-spaces only Latin text — spacing Arabic
pulls its joined letters apart.

**Cubits** extend `BaseCubit`, which drops an `emit` after close. A state's
`copyWith` deliberately **clears** `errorMessage`/`fieldErrors` unless they
are passed again — an error belongs to one attempt.

**Errors are shown in a toast**, via `showAppToast(context, message,
isError: true)`; inputs carry local validation only. List every field error
one per line (`displayError`). **Inside a bottom sheet** the toast would sit
behind the sheet (it belongs to the page's Scaffold), so a sheet that calls
the server shows the refusal with `SheetErrorNote` above its buttons; the
sheets here only collect (the reject reason) and the page makes the call.

**Length limits** are checked with `validateTextLength`
(`core/utils/validators/validator_messages.dart`), which trims and counts
code points. A field's `maxLength` counts graphemes and lets an emoji built
from several code points past a code-point limit, so keep both.

## Localization

`easy_localization`, Arabic and English, RTL (Arabic) by default. Keys live in
`assets/translations/{en,ar}.json` and **both files must hold the same key
set** — `test/translations_test.dart` asserts it, along with no empty values,
plural keys plural in both, and the same number of `{}` arguments per
language. User-facing strings are always `'key'.tr()`, never literals. Counts
use `.plural()` with Arabic's forms (`order_items`, `offer_uses`).

Numbers print with Western digits in both languages, as the design does
(`Money`, dates through `AppDateUtils`' month tables).

Phone numbers are collected by `PhoneTextFormField`
(`core/widgets/phone_text_form_field.dart`), a palette-styled wrapper around
the `intl_phone_number_input` package (^0.7.5, libphonenumber through the
pure-Dart `dlibphonenumber`). **Use it for every phone input, and do not edit
the file** — it is kept exactly as the user supplied it. What it needs from
the rest of core stays in core: `AppPalette.gold` (an alias of `accent`) and
the `text12w500`, `text13w500` and `text13w400Notif` styles in `AppStrings`,
and the `search_by_country` translation. Adapt it from the outside, through
its parameters: the sign-in form passes the design's `48.h` height and `12.r`
radius and draws the design's `CapsLabel` above it instead of the field's
own `label`.

The picker offers Kuwait and Egypt, so **which country was chosen is not
recoverable from the digits** — keep the `PhoneNumber` the field reports
through `onInputChanged` and send its E.164 `phoneNumber`, never the
controller text (`AuthForm` does). Give it a `FocusNode` the form owns: the
field regroups the number when it is left. Its messages are
`phone_required`, `invalid_phone` and `phone_length` (`lengthMessage`, which
names the digit count the country expects).

**Nothing assumes a country.** `KuwaitPhone.display` only groups a number
that is already `+965` and eight digits, for the code screen; any other
number is shown exactly as it went out. Prefixing `965` onto a number
without `+` is how the Cloak shopper app once stored an Egyptian number as
`965201064780620`.
