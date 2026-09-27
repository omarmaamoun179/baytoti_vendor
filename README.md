# Baytouti Vendor (بيتوتي للأسر)

The producing family's app for Baytouti, a marketplace for home-cooked food:
a family signs up, waits for approval, then runs its store — orders,
products, offers and the store profile. Flutter, Arabic-first (RTL) with
English.

## Backend

The app talks to the Betouti Laravel API:

- Base URL: `https://betouti.alqudiry-solutions.com/api/v1/`
- OpenAPI: `https://betouti.alqudiry-solutions.com/docs/api.json`

Every feature also has fixtures, for demos and the screen tour.

## Running

Needs Flutter 3.47.3 (Dart 3.13.3).

```bash
flutter pub get
flutter run                                   # the live API
flutter run --dart-define=USE_MOCK_DATA=true  # fixtures; any number, code 1234
flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1/
flutter analyze
flutter test
```

`CLAUDE.md` holds the architecture, the conventions, and what each feature
reads from the API — including the response shapes that are still guesses.
