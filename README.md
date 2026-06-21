# diver_flutter_builder

A `build_runner` builder that aggregates [`go_router`](https://pub.dev/packages/go_router) routes into `diver/app_urls.json` at build time.

The builder scans every Dart library in the consuming package for classes annotated with `@TypedGoRoute(...)`, collects their path and query parameters, and writes them — sorted by host then path — to `diver/app_urls.json`. Optional `@DiverRoute(...)` annotations (from [`diver_flutter_annotation`](../diver_flutter_annotation)) contribute a human-readable `name` and `description` for each route.

Routes whose class declares a `$extra` constructor parameter are kept out of `app_urls.json`: they require a runtime object and cannot be reached by URL alone, so they are not deeplink-safe. Each excluded route is instead recorded in `diver/app_urls_errors.json` with a description of why it cannot be used for a deeplink, and reported as a build warning. The error file is only written when there is at least one excluded route, and `build_runner` removes it automatically once every route is deeplink-safe again.

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

This produces `diver/app_urls.json` containing every deeplink-safe route discovered in the package.

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

The generated `diver/app_urls.json` will be:

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

`DetailRoute` is excluded from `app_urls.json` because it depends on `$extra`. Routes without a `@DiverRoute` annotation get empty `name` and `description` defaults.

Because `DetailRoute` was excluded, the builder also writes `diver/app_urls_errors.json`:

```json
{
  "errors": [
    {
      "route": "DetailRoute",
      "path": "/detail",
      "extra": "Item",
      "reason": "Route declares a $extra constructor parameter (Item). $extra requires a runtime Dart object that cannot be encoded in a URL, so this route cannot be reached by a deeplink."
    }
  ]
}
```

## Configuration

The builder is wired up via `build.yaml` and auto-applies to dependents. No additional configuration is required in the consuming package.

### Options

| Option | Default | Description |
| --- | --- | --- |
| `keep_generated` | `false` | When `true`, the generated `diver/app_urls.json` is left in the source tree after the build. When `false` (the default), the file is deleted on each build so it never gets committed. Enable this when you need to inspect the output or run `upload_urls` against it. |

Override per-target via `build.yaml` in the consuming package:

```yaml
targets:
  $default:
    builders:
      diver_flutter_builder|url_aggregator:
        options:
          keep_generated: true
```

## Uploading routes

The package ships an `upload_urls` executable that POSTs the generated `diver/app_urls.json` to the Diver API.

```sh
dart run diver_flutter_builder:upload_urls
```

Pass a custom path as the first argument to read from somewhere other than `diver/app_urls.json`:

```sh
dart run diver_flutter_builder:upload_urls path/to/diver/app_urls.json
```

Prerequisites:

- `diver/app_urls.json` must exist — run `dart run build_runner build` first.
- `ORG_ID` and `APP_ID` must be set, either as environment variables or in a `diver/diver_config.properties` file in the working directory. The file uses a simple `KEY=value` format, one per line:

  ```properties
  ORG_ID=your-org-id
  APP_ID=your-app-id
  ```
