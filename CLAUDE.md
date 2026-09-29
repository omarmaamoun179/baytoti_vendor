# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Baytouti (بيتوتي) — the producing family's app**: the vendor side of a
marketplace for home-cooked food. A family signs up, waits for approval,
then runs its store: orders, products, offers, the store profile.

The design is `Baytouti Vendor App.dc.html` in the Claude Design project
"Dual App Design: Customer and Vendor" (`abedcbee-1f5b-4ec4-b8fb-6675543c7a53`),
beside `Baytouti Customer App.dc.html` and `Baytouti API Spec.dc.html` (the
design-time contract the fixtures still answer in). Read them with the
`DesignSync` tool (`get_file`). `lib/core` started as a copy of the Cloak
vendor app's core (`../cloack_vendor`) and was re-branded here; the two are
not linked, but the two backends are the same Laravel family, so Cloak's
remote sources and their notes are the best guide to what an answer holds.

**The server is the Betouti Laravel API** at
`https://betouti.alqudiry-solutions.com/api/v1/`. Its OpenAPI (Scramble) is at
`https://betouti.alqudiry-solutions.com/docs/api.json` — the authoritative
reference for paths and request bodies, per the backend's *Mobile API
Integration Guide v1.0*. The spec types most answers only as "object", so
the models read leniently and name their guesses. The backend says *vendor*
for the family and *store* for its shop; products live under a store.

**Repository**: `github.com/omarmaamoun179/baytoti_vendor`, branch `main`.

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
# On fixtures only — it signs in with their code.
SCREENSHOT_DIR=build/screenshots flutter drive \
  --dart-define=USE_MOCK_DATA=true \
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
flutter run --dart-define=USE_MOCK_DATA=true       # fixtures instead of the API
flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1/
```

`useMockData` (in `core/di/injection_container.dart`) defaults to **false** —
the live API. Every feature with an endpoint registers its remote source
beside its fixtures and picks between them with it (the doc comment there
shows the shape); offers have no endpoint and stay on fixtures either way.
It also decides what the onboarding button says ("Simulate approval" on
fixtures, "Check status" live).

`lib/main.dart` is one line; everything before the first frame is in
`core/app/bootstrap.dart`, in order: binding → localization → timezone → DI →
session restore → `runApp`.

## Current state

Every screen of the design exists: the splash, onboarding (V01), dashboard
(V02), orders (V03), order details (V04), products (V05), the product form
(V06), offers (V07), store profile (V08) and notifications (V09). Not in the
vendor design, and built in its style: sign-in / sign-up and the code screen
(from the customer design's screens 02–03), editing a product (the V06 form
over `/products/:id`), the reject sheet, an account card (language,
location, sign-out) at the foot of the store tab, and the location page it
opens.

- **Two sources per feature.** Each feature has a `*DataSource` interface, a
  `*RemoteDataSource` for the live API and a `*MockDataSource` for fixtures.
  The fixtures still answer in the design contract's shapes; a model reads
  those with `fromJson` and the live API with `fromApi` (or
  `fromProfile`/`fromMessage`), both building the same entity. Fixture sources
  are lazy singletons, so changes last the run, and they refuse what the
  server would. `OrderFixtures` and `ProductFixtures` are shared with the
  dashboard fixture so its counts agree with the tabs. Latency is
  `mockLatency` (350 ms).
- **Language.** Fixtures answer in the app's language (`MockLocale`), read
  from the stored code that `LocaleSync` (`core/app/`) writes; tabs re-read
  through `LocaleChangeListener`. Requests send `Accept-Language` and
  `x-custom-lang`, but on 2026-09-28 the server answered validation errors in
  Arabic whatever either said, and some messages ("Invalid OTP.") are English
  only — the server's to fix.
- **Who is signed in** reaches the fixtures through the token:
  `MockSessionToken` encodes new-or-returning family, phone and family name.
  On fixtures a number signs in to the fixture family ("أسرة أم عبدالله",
  approved) unless it registered this run; **any number gets code `1234`**.
  A mock token sent to the live API is refused, and the 401 ends the session.
- **Auth.** Sign-in: `POST auth/request-otp {phone}` → `POST auth/verify-otp
  {phone, otp}`. The API names no OTP request, so the code is checked
  against the number, sent as digits (`^[0-9]{8,15}$`, the E.164 from
  `PhoneTextFormField` without `+`); a resend asks again. While SMS is
  stubbed the server puts the code at the end of its message (`"… demo otp
  :561228"`), shown under the boxes (`otp_demo_hint`), and its length sets
  the boxes (six otherwise). A wrong code is a 422 on `otp`. Sign-up first
  sends `POST auth/vendor/register` — the whole `VendorRegisterRequest`:
  the account (an optional photo, name, email, phone, password twice —
  each with an eye to show it), the family's business
  (name required; phone, email, commercial licence, civil ID, bank account,
  IBAN and address optional) and its store (name required, description
  optional), in `AuthForm` and `VendorDetailsFields`. There is no terms
  checkbox. Blanks are left out
  of the body, numbers go as digits, the IBAN in capitals without spaces,
  and `device_name` is the app and platform. A chosen photo goes as the
  `avatar` file (`AvatarPicker`, from the gallery), which makes the body
  multipart; one past 5120 KB is refused before sending
  (`checkAvatarSize`). It issues no token, then the
  app asks for the code. If the
  code fails after the account exists, the family is told to log in with the
  same number (`signup_code_failed`). `verify-otp`'s answer is read leniently
  (token flat or nested, user wrapped or not); a token without an account is
  kept and `GET auth/me` read with it. **Unverified live:** that answer's
  exact shape, and whether sign-in by code works for every vendor account.
- **The onboarding gate is off** (2026-09-28, the user's call): a signed-in
  family goes straight to the dashboard whatever its review says. The
  onboarding feature is kept but not routed: `AccountGate` would show
  `ApplicationStatusPage` (V01) in place of any store screen until approval,
  and wrapping the shell and `_fullScreen`'s builder in it again turns it
  back on. Live, the review is `GET vendor/profile`'s `status`: `active` /
  `approved` open the store, a refusal (`rejected`, `suspended`…) reads as
  rejected, anything else is under review. The timeline is drawn from that
  one status. `ApplicationCubit` is app-wide, follows `SessionNotifier` and
  still reads the profile on sign-in.
- **The store** is the first of `GET vendor/stores` — registration makes
  exactly one. `VendorStoreResolver` keeps its id for the session (forgotten
  on sign-out) for the store and products sources. The store tab saves with
  `PUT vendor/stores/{store}`: name, description, and — when one is chosen —
  `country_id` + `governorate_id`. Only edited fields go out: Laravel
  updates from the validated input, and image URLs are never echoed back. The
  place is a `StoreArea`: live, the governorates of the store's country
  (`GET countries/{id}/governorates`, cached; a store with no country is
  offered the first active one's — on 2026-09-28 only Egypt existed); on
  fixtures the design's five Kuwaiti cities. The API takes `logo`/`banner`
  only as stored paths and has no upload, so "Change cover" is not offered
  live (`StoreProfile.coverEditable`); it keeps no documents, so the
  verification card is hidden there.
- **Location** (`features/location`) is the account's own, apart from the
  store's area: a row in the store tab's account card shows it
  (`LocationContextCubit`, per screen), and `/location` changes it —
  `GET countries` and `countries/{id}/governorates` (public, cached) as
  chips, saved with `POST location/context {mode: manual, country_id,
  governorate_id}`; the page pops with the saved `LocationContext`. A
  family that has just signed up is sent to the same page first
  (`/location/setup`), which goes to the dashboard on save instead.
  **The answer's shape is a guess** (the spec types it "object"): the
  `selected_*` pair, then `resolved_*`, then plain `country_id`, maybe under
  `context`; `data: null` or a 404 is no location. Names missing from it are
  filled from the lists, and a save that answers without the location reads
  as the one sent. `auto` (coordinates) is not offered: the app has no
  device-location package. Fixtures offer Kuwait and Egypt, in the API's
  shape — there is no design contract for location.
- **Products** live under the store: `GET/POST vendor/stores/{store}/products`,
  `GET/PUT …/{product}`, `POST …/{product}/submit-review`; categories are
  `GET categories/active`, flattened. State is moderation first
  (`approval_status`: draft · pending_review · approved · rejected), then the
  vendor's switch (`status`): approved + on is published, approved + off
  hidden. **The API keeps no stock count for food**, only `is_available`, so
  the domain, the form (a switch beside the price), the list and the fixtures
  speak of availability. Preparation time is `preparation_time_minutes`
  (the three chips carry `PreparationTime.minutes`). Money is `base_price` in
  dinars, read into fils. The list's switch is the product's own `status`
  (`VendorProductSummary.isSwitchedOn`), sent as `PUT {status}` and shown
  as the server keeps it, whatever the review: on 2026-09-28 the server
  took `status: true` on a `pending_review` product and answered with it.
  The review is the row's label; `isLive` (approved + on + available) is
  whether it is on sale. A save
  never sends to review itself: the repository calls `submitForReview` once
  it lands, and a refused review is carried on the result
  (`ProductSaveResult.reviewRefusal`), never reported as a failed save — a
  retry would make the product twice. Search is sent as `search` and matched
  on the rows too (the spec documents none). **Photos are a guess to confirm
  with the backend**: live there is no upload endpoint, so
  `DeviceUploadsDataSource` checks the 5120 KB limit and keeps the file
  (`device:` upload ids), and the save goes multipart (update as `POST` +
  `_method=PUT`) with `images[i]` — `image` as the file for a picked photo,
  `id` for a kept one, the cover `is_primary`. The guide's food product has an
  `images` gallery, but the spec still types photos under the clothing-era
  `colors[].images` (each colour needing a size variant). Photos are read
  from `images`, then `colors[].images`, then `thumbnail`.
- **Orders**: `GET vendor/orders`, `GET vendor/orders/{order}`,
  `PATCH vendor/orders/{order}/status`. The API's six statuses are read onto
  the app's and sent back exactly: pending → placed, confirmed → accepted,
  processing → preparing, shipped → out for delivery, delivered, cancelled.
  The resource carries no next move, so the next step on that path is
  offered; only a new order can be turned down, which is `cancelled` — the
  reason sheet's answer stays with the app (the API takes none). The endpoint
  takes no filter: tabs filter the rows they read, a filtered tab reading up
  to five pages to fill the screen; the counts come from the first page
  (`all` = `meta.total`, "done" = the rest) and `OrdersCubit.loadMore` keeps
  them. The customer is the address's recipient, their number masked; the
  gross is the order's total (no payout breakdown live). The details page
  pops `true` after a move so the opener re-reads. The call button says
  calling is coming.
- **Dashboard**: `GET vendor/home?period=today`, and beside it
  `?period=week` for the chart, drawn only when the answer's `period.key` is
  `week` (Cloak's server answered every period with today) — otherwise the
  card is left out. Stats give new orders, today's orders and products
  switched off ("Not available", `out_of_stock_products`). When
  `recent_orders` is empty or today's count is missing, the first page of
  `vendor/orders` fills in. **Checked live on 2026-09-28**: the answer is
  the shape `VendorDashboardModel.fromApi` documents; `period` is ignored
  (no period, `today` and `week` answer alike, so the week card never
  shows); there is no `orders_today`, so the orders page is always read;
  `alerts` (e.g. `out_of_stock`) and `vendor.status` (`pending` for a
  family not yet approved, which is still served) are sent but not read.
  An account without the vendor role (account #25 that day, which
  `auth/me` answers for) is refused every `vendor/*` call with
  `403 "User does not have the right roles."` (Spatie), shown as sent.
- **Offers**: fixtures only — the API has no offers endpoint. Store-wide
  percentage discounts (5–70 % in 5s, three at once) with an end date.
- **Notifications**: `GET notifications`, `PATCH notifications/read-all` —
  the account's own, shared by both apps. Unread is a null `read_at`; the
  kind is the `type` key or the words of a Laravel class name; the target is
  `data.entity`/`entity_id`. The page carries no unread count, so its own
  unread rows feed the bell. Opening the list marks everything read.
- **App-wide cubits** (`core/app/app.dart`): `NetworkCubit`, `AuthCubit`,
  `ApplicationCubit`, `OrdersBadgeCubit` (fed by whichever screen read the
  new-order count last — it reads nothing itself), `NotificationBadgeCubit`.
- **Money and time.** The app works in integer fils and formats both itself
  (`Money.display`, `relativeTimeLabel`). Live money arrives as dinar
  strings (`"4.250"`) and is converted at the model; the currency is printed
  as KWD whatever the store's country — worth deciding now that the server's
  only country is Egypt.
- **Backend issues seen on 2026-09-28**, for the backend team: debugging is
  on in production (a 404 or 500 answers with the exception, file paths and
  trace — the app shows `server_error` for any 5xx and renames 404s); the
  public `GET products` and `GET stores` answer 500 without a token
  (`LocationContextService` given a null user); validation messages ignore
  the language headers.
- **Splash**: the design's, on the vendor amber (`palette.brandGround`),
  mirroring the customer app's (`../baytoti`): one `AnimationController`
  over `SplashTimeline.length` (3.5 s) drives the painted mark
  (`SplashMark`) and the text, and its end moves on — to the dashboard or
  sign-in — as a tap does. It never repeats, so `pumpAndSettle` settles.
  Before it, the native launch screen (`flutter_native_splash`, config in
  `pubspec.yaml`) is the same amber alone, so the two read as one; it is
  not preserved, since no frame is drawn before `runApp`. After
  `dart run flutter_native_splash:create`, revert `ios/Runner/Info.plist`:
  it re-indents the file to add `UIStatusBarHidden = false`, the default.
- **App icon**: the vendor icon from Claude Design's "Baytouti App Icons"
  (the house, leaf and bird on amber, an awning over the door), kept as SVG
  in `assets/icons/` beside the 1024 PNGs `flutter_launcher_icons` reads
  (config in `pubspec.yaml`). To change it, render the SVGs again (headless
  Chrome) and run `dart run flutter_launcher_icons`. Afterwards revert
  `ios/Runner.xcodeproj/project.pbxproj`: 0.14.4 writes `AppIcon` into
  `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`, a yes/no
  setting.
- **Not done**: identifiers are still the template's
  `com.example.baytoti_vendor`; Android release is signed with the debug key;
  nothing refreshes a token (Sanctum tokens do not refresh); the location is
  set by hand only (`mode: auto` would need a device-location package).

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

**The envelope** is Laravel's, parsed once in `ApiResponse`
(`core/network/api_response.dart`): `{success, message, data, errors}`, with
`links`/`meta` beside `data` on a paginated answer. `checkedResponse` throws
`RequestException` unless `success`; a 422 carries `errors` (first message per
field, flattened by `flattenFieldErrors`). A dead token is refused with a bare
`401 {"message": "Unauthenticated."}`. A 5xx never shows the server's own
words — with debugging on they are Laravel's exception and trace — so
`ensureOk` sends up `server_error`. Rename a 404 per call with
`messageForStatus` for the same reason.

`ApiEndPoint` (`core/network/api_endpoints.dart`) holds every path, relative to
`baseUrl`, which already carries the version prefix **and a trailing slash**
— dropping it collapses `/v1/vendor/orders` into `/v1vendor/orders`.

Authenticated calls get the token for free by passing no `headers` (a
Sanctum bearer token). A 401 on a call sent with the stored token ends the
session: `NetworkServiceImpl` drops the token and throws
`SessionExpiredException`, and `AuthCubit.sessionExpired()` forgets the rest.
Sanctum tokens do not refresh. Pass `skipAuthRefresh: true` for the public
endpoints (register, the OTP pair, categories, countries), where a 401 means
a refusal, not a dead session.

**Nothing may reach the network before `runApp`.** The requests inspector's
controller is a singleton created by whoever asks first; when that is the Dio
interceptor instead of the `RequestsInspector` widget, it is created disabled
and silently drops every request for the rest of the run.

Limits and lengths live on the **domain entity** (`ProductRules`,
`StoreRules`, `SignupDetails`, `VendorDetails`, `OtpChallenge.codeLength`), not
only in a validator or a widget, so the UI and the wire cannot drift apart;
each sits inside the OpenAPI schema's own. **Money is integer fils** in the
app (4250 = 4.250 KWD); `Money.display(fils)` prints it with Western digits
and the currency in the app's language.

### Pagination

The core pages by number: `ApiResponse` reads `meta` (siblings of `data`)
into `currentPage`, `lastPage`, `perPage`, `total`, `hasMore`, and one page
becomes `Paged<T>` (`core/domain/paged.dart`) with `hasMore`, `nextPage` and
`append`. The live API pages the same way (Laravel's `meta`/`links`); the
fixtures answer with `meta` inside the payload.

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
and `search=` on the wire searches for the empty string.

### Routing

One `GoRouter` in `core/routing/app_router.dart`, paths in `routes.dart`. The
five tabs (home, orders, products, offers, store) are `StatefulShellRoute`
branches; order details, the product form, notifications and the location
page are pushed on the root navigator over the tab bar. A confirmed code leaves the form through
the guard: the session flips and `redirectForMember` sends `/login` and
`/otp` to the dashboard — or, when the code finished a sign-up
(`SessionNotifier.isNewAccount`), to `/location/setup`: the location page
as the last step of signing up, with no back, going on to the dashboard
once the location is saved. The product form
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
one per line (`displayError`). **The sign-in / sign-up form is the
exception:** it validates as it is typed in (`AutovalidateMode
.onUserInteraction`), and a 422's field messages are drawn under their
fields — each field's validator falls back to the server's message, which
is dropped when that field is edited and on the next submit. The page
toasts only what no field shows (`AuthForm.showsField`). **Inside a bottom sheet** the toast would sit
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
