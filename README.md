# diver_flutter_annotations

A `build_runner` builder that aggregates [`go_router`](https://pub.dev/packages/go_router) route paths into a single text file at build time.

The builder scans every Dart library in the consuming package for classes annotated with `@TypedGoRoute(...)`, collects their `path` values, and writes them — sorted, one per line — to `lib/app_urls.txt`.

Routes whose class declares a `$extra` constructor parameter are skipped: they require a runtime object and cannot be reached by URL alone, so they are not deeplink-safe.

## Installation

Add the package as a dev dependency in the consuming app:

```yaml
dev_dependencies:
  diver_flutter_annotations:
    path: ../diver_flutter_builder
  build_runner: ^2.4.0
```

## Usage

Run the builder:

```sh
dart run build_runner build
```

This produces `lib/app_urls.txt` containing every deeplink-safe route path discovered in the package.

### Example

Given:

```dart
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData { ... }

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData { ... }

@TypedGoRoute<DetailRoute>(path: '/detail')
class DetailRoute extends GoRouteData {
  DetailRoute({required this.$extra});
  final Item $extra;
}
```

The generated `lib/app_urls.txt` will be:

```
/home
/settings
```

`DetailRoute` is excluded because it depends on `$extra`.

## Configuration

The builder is wired up via `build.yaml` and auto-applies to dependents. No additional configuration is required in the consuming package.
