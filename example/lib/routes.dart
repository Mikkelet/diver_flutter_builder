import 'package:diver_flutter_annotation/diver_flutter_annotation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'message_page.dart';
import 'models.dart';

part 'routes.g.dart';

/// Every route below is a standard go_router `GoRouteData` class. When you run
/// `dart run build_runner build`, two builders process this file:
///
/// * `go_router_builder` generates `routes.g.dart` (the routing wiring), and
/// * `diver_flutter_builder` writes `diver/app_urls.json` (and, for the route
///   that is not deeplink-safe, `diver/app_urls_errors.json`).
///
/// The comments on each route call out what shows up in the generated JSON.

/// Plain route, no parameters.
///   -> { host: "home", path: "", query: [] }
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MessagePage('Home');
}

/// Query parameters of every flavour, plus `@DiverRoute` metadata that becomes
/// the `name`/`description` in the output.
///   -> query: [
///        { name: "term",     required: true  },  // non-null, no default
///        { name: "page",     required: false },  // has a default
///        { name: "category", required: false },  // nullable
///      ]
@DiverRoute(
  name: 'Product search',
  description: 'Full-text product search with optional paging and filtering.',
)
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute({required this.term, this.page = 1, this.category});

  final String term;
  final int page;
  final String? category;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessagePage('Search "$term" (page $page)');
}

/// Path parameter (`:id`) plus a nullable query parameter. The path parameter
/// is part of the URL itself and is never emitted as a query param.
///   -> { host: "users", path: ":id", query: [ { name: "tab", required: false } ] }
@TypedGoRoute<UserRoute>(path: '/users/:id')
class UserRoute extends GoRouteData with $UserRoute {
  const UserRoute({required this.id, this.tab});

  final String id;
  final String? tab;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessagePage('User $id');
}

/// Optional `$extra` (nullable, no default). The route can still be opened from
/// a URL — `$extra` simply arrives as `null` — so it stays deeplink-safe and is
/// included in `app_urls.json`. (`$extra` itself is never a query param.)
///   -> { host: "profile", path: "", query: [] }
@TypedGoRoute<ProfileRoute>(path: '/profile')
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute({this.$extra});

  final User? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessagePage($extra?.name ?? 'Profile (opened without a payload)');
}

/// Required `$extra` (non-nullable, no default). A URL cannot carry the runtime
/// `Cart`, and the route cannot be constructed without it, so it is NOT
/// deeplink-safe: it is left out of `app_urls.json` and recorded in
/// `diver/app_urls_errors.json` with the reason.
@TypedGoRoute<CheckoutRoute>(path: '/checkout')
class CheckoutRoute extends GoRouteData with $CheckoutRoute {
  const CheckoutRoute({required this.$extra});

  final Cart $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MessagePage('Checkout (${$extra.itemCount} items)');
}