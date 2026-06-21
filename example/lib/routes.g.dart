// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRoute,
  $searchRoute,
  $userRoute,
  $profileRoute,
  $checkoutRoute,
];

RouteBase get $homeRoute =>
    GoRouteData.$route(path: '/home', factory: $HomeRoute._fromState);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $searchRoute =>
    GoRouteData.$route(path: '/search', factory: $SearchRoute._fromState);

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) => SearchRoute(
    term: state.uri.queryParameters['term']!,
    page: _$convertMapValue('page', state.uri.queryParameters, int.parse) ?? 1,
    category: state.uri.queryParameters['category'],
  );

  SearchRoute get _self => this as SearchRoute;

  @override
  String get location => GoRouteData.$location(
    '/search',
    queryParams: {
      'term': _self.term,
      if (_self.page != 1) 'page': _self.page.toString(),
      if (_self.category != null) 'category': _self.category,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $userRoute =>
    GoRouteData.$route(path: '/users/:id', factory: $UserRoute._fromState);

mixin $UserRoute on GoRouteData {
  static UserRoute _fromState(GoRouterState state) => UserRoute(
    id: state.pathParameters['id']!,
    tab: state.uri.queryParameters['tab'],
  );

  UserRoute get _self => this as UserRoute;

  @override
  String get location => GoRouteData.$location(
    '/users/${Uri.encodeComponent(_self.id)}',
    queryParams: {if (_self.tab != null) 'tab': _self.tab},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $profileRoute =>
    GoRouteData.$route(path: '/profile', factory: $ProfileRoute._fromState);

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) =>
      ProfileRoute($extra: state.extra as User?);

  ProfileRoute get _self => this as ProfileRoute;

  @override
  String get location => GoRouteData.$location('/profile');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $checkoutRoute =>
    GoRouteData.$route(path: '/checkout', factory: $CheckoutRoute._fromState);

mixin $CheckoutRoute on GoRouteData {
  static CheckoutRoute _fromState(GoRouterState state) =>
      CheckoutRoute($extra: state.extra as Cart);

  CheckoutRoute get _self => this as CheckoutRoute;

  @override
  String get location => GoRouteData.$location('/checkout');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}
