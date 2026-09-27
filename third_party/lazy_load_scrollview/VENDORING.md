# Why `lazy_load_scrollview` is vendored

`lazy_load_scrollview` is the infinite-scroll trigger the product grid uses. It cannot be
taken from pub.dev: **every published version**, up to and including the latest (1.3.0,
March 2021), declares

```yaml
environment:
  sdk: '>=2.12.0 <3.0.0'
```

and this app requires `^3.11.1`. Pub refuses to resolve it, and `dependency_overrides` does
not relax an SDK bound — it only picks a different version of a package, and there is no
version to pick. The package has had no release since 2021.

So it lives here instead, as a `path` dependency:

```yaml
lazy_load_scrollview:
  path: third_party/lazy_load_scrollview
```

Nothing about the call site changes — the import is still
`package:lazy_load_scrollview/lazy_load_scrollview.dart`.

## What was changed

**One line.** `environment.sdk` in `pubspec.yaml` is `>=3.0.0 <4.0.0` instead of
`>=2.12.0 <3.0.0`. Everything under `lib/` is byte-for-byte the published 1.3.0 — the code is
already null-safe and uses no removed API, so the old bound was the only obstacle.

Dropped from the published archive because they are not needed to consume the package:
`example/`, `.gitignore`, and the IntelliJ `.iml` file. `LICENSE`, `README.md` and
`CHANGELOG.md` are kept as published.

## Licence

BSD 2-Clause, Copyright (c) 2018 Quirijn Groot Bluemink. See `LICENSE`, which is retained
verbatim as that licence requires.

## One behaviour worth knowing at the call site

The widget latches itself after firing: `_loadMore()` sets its status to `LOADING` and will
not fire again until `didUpdateWidget` sees `isLoading == false`. **Pass `isLoading`** — with
the default of `false` it re-arms on every rebuild and will happily fire again while a page
is still in flight:

```dart
LazyLoadScrollView(
  isLoading: state.status == ProductsStatus.loadingMore,
  onEndOfPage: () => context.read<ProductsCubit>().loadMore(),
  child: ...,
)
```

The cubit guards the same case independently, because a widget is the wrong place to hold
that invariant on its own.
