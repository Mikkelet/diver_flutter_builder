# diver_flutter_builder example

A minimal Flutter app that wires up [`go_router`](https://pub.dev/packages/go_router)
typed routes and runs [`diver_flutter_builder`](../) over them.

It exists to show, end to end, what the builder produces for the different kinds
of route it can encounter. All five routes live in [`lib/routes.dart`](lib/routes.dart);
the comment on each one explains what it contributes to the output.

## Run the builder

```sh
flutter pub get
dart run build_runner build
```

This generates:

- `lib/routes.g.dart` — the go_router wiring (from `go_router_builder`).
- `diver/app_urls.json` — the deeplink-safe routes (from `diver_flutter_builder`).
- `diver/app_urls_errors.json` — routes that are **not** deeplink-safe.

> The example's [`build.yaml`](build.yaml) sets `keep_generated: true` so
> `diver/app_urls.json` is left on disk for inspection. Without it the builder
> deletes that file at the end of every build.

You can also run the app itself with `flutter run`.

## What the routes demonstrate

| Route | Declaration | Result |
| --- | --- | --- |
| `HomeRoute` | `/home`, no params | Plain entry in `app_urls.json` |
| `SearchRoute` | `/search` + `@DiverRoute` | `name`/`description` from the annotation; query params with `required` flags |
| `UserRoute` | `/users/:id` | Path param `:id` (kept out of `query`) + a nullable query param |
| `ProfileRoute` | `/profile`, `User? $extra` | **Optional** `$extra` → still deeplink-safe, included |
| `CheckoutRoute` | `/checkout`, `required Cart $extra` | **Required** `$extra` → not deeplink-safe → `app_urls_errors.json` |

## Generated `diver/app_urls.json`

```json
{
  "routes": [
    { "name": "home", "description": "", "host": "home", "path": "", "query": [] },
    { "name": "profile", "description": "", "host": "profile", "path": "", "query": [] },
    {
      "name": "Product search",
      "description": "Full-text product search with optional paging and filtering.",
      "host": "search",
      "path": "",
      "query": [
        { "name": "term", "type": "string", "required": true },
        { "name": "page", "type": "string", "required": false },
        { "name": "category", "type": "string", "required": false }
      ]
    },
    {
      "name": "users/:id",
      "description": "",
      "host": "users",
      "path": ":id",
      "query": [
        { "name": "tab", "type": "string", "required": false }
      ]
    }
  ]
}
```

## Generated `diver/app_urls_errors.json`

```json
{
  "errors": [
    {
      "route": "CheckoutRoute",
      "path": "/checkout",
      "extra": "Cart",
      "reason": "Route requires a non-nullable $extra constructor parameter (Cart) with no default value. $extra carries a runtime Dart object that cannot be encoded in a URL, and the route cannot be constructed without it, so it cannot be reached by a deeplink. Make $extra nullable or give it a default value to allow URL navigation without the payload."
    }
  ]
}
```
