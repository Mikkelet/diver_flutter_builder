# diver_flutter_builder

A `build_runner` builder that aggregates [`go_router`](https://pub.dev/packages/go_router) routes into `lib/app_urls.json` at build time.

The builder scans every Dart library in the consuming package for classes annotated with `@TypedGoRoute(...)`, collects their path and query parameters, and writes them — sorted by host then path — to `lib/app_urls.json`. Optional `@DiverRoute(...)` annotations (from [`diver_flutter_annotation`](../diver_flutter_annotation)) contribute a human-readable `name` and `description` for each route.

Routes whose class declares a `$extra` constructor parameter are skipped: they require a runtime object and cannot be reached by URL alone, so they are not deeplink-safe.

## Installation

Add the builder as a dev dependency and the annotation as a regular dependency in the consuming app:

```yaml
dependencies:
  diver_flutter_annotation:
    path: ../diver_flutter_annotation

dev_dependencies:
  diver_flutter_builder:
    path: ../diver_flutter_builder
  build_runner: ^2.4.0
```

## Usage

Run the builder:

```sh
dart run build_runner build
```

This produces `lib/app_urls.json` containing every deeplink-safe route discovered in the package.

### Example

Given:

```dart
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData { ... }

@DiverRoute(name: 'Settings', description: 'App settings screen')
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData {
  SettingsRoute({this.tab});
  final String? tab;
}

@TypedGoRoute<DetailRoute>(path: '/detail')
class DetailRoute extends GoRouteData {
  DetailRoute({required this.$extra});
  final Item $extra;
}
```

The generated `lib/app_urls.json` will be:

```json
{
  "routes": [
    {
      "name": "",
      "description": "",
      "host": "home",
      "path": "",
      "query": []
    },
    {
      "name": "Settings",
      "description": "App settings screen",
      "host": "settings",
      "path": "",
      "query": [
        {"name": "tab", "type": "string"}
      ]
    }
  ]
}
```

`DetailRoute` is excluded because it depends on `$extra`. Routes without a `@DiverRoute` annotation get empty `name` and `description` defaults.

## Configuration

The builder is wired up via `build.yaml` and auto-applies to dependents. No additional configuration is required in the consuming package.

## Uploading routes

The package ships an `upload_urls` executable that POSTs the generated `lib/app_urls.json` to the Diver API.

```sh
dart run diver_flutter_builder:upload_urls
```

Pass a custom path as the first argument to read from somewhere other than `lib/app_urls.json`:

```sh
dart run diver_flutter_builder:upload_urls path/to/app_urls.json
```

Prerequisites:

- `lib/app_urls.json` must exist — run `dart run build_runner build` first.
- `ORG_ID` and `APP_ID` must be set, either as environment variables or in a `diver_config.properties` file in the working directory. The file uses a simple `KEY=value` format, one per line:

  ```properties
  ORG_ID=your-org-id
  APP_ID=your-app-id
  ```
