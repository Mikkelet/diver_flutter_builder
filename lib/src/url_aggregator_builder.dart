import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that scans every Dart library in the consuming package for classes
/// carrying a `@TypedGoRoute(...)` annotation and writes a JSON description of
/// each route to `lib/app_urls.json`, sorted alphabetically by path.
///
/// Routes whose class has a `$extra` constructor parameter are excluded from
/// `app_urls.json`: they require a runtime object and cannot be reached by URL
/// alone, so they are not deeplink-safe. Each excluded route is instead written
/// to `diver/app_urls_errors.json` together with a description of why it cannot
/// be used for a deeplink.
class UrlAggregatorBuilder implements Builder {
  UrlAggregatorBuilder({this.keepGenerated = false});

  /// When false (the default), the generated `diver/app_urls.json` is deleted
  /// from the source tree after the build. Set to true via the
  /// `keep_generated` option in `build.yaml` to retain the file (e.g. for
  /// inspection or for the `upload_urls` executable to consume).
  final bool keepGenerated;

  static const _outputAsset = 'diver/app_urls.json';
  static const _outputExtension = 'diver/app_urls.json';
  static const _errorAsset = 'diver/app_urls_errors.json';
  static const _errorExtension = 'diver/app_urls_errors.json';
  static const _typedGoRouteName = 'TypedGoRoute';
  static const _diverRouteName = 'DiverRoute';
  static const _extraParamName = r'$extra';

  static final _pathParamPattern = RegExp(r':([a-zA-Z_]\w*)');
  static final _camelBoundary1 = RegExp(r'([a-z0-9])([A-Z])');
  static final _camelBoundary2 = RegExp(r'([A-Z]+)([A-Z][a-z])');
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$package$': [_outputExtension, _errorExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final routes = <_Route>[];
    final excluded = <_ExcludedRoute>[];
    final seenPaths = <String>{};

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (!await buildStep.resolver.isLibrary(input)) continue;
      final library = await buildStep.resolver.libraryFor(input);
      final reader = LibraryReader(library);

      for (final classElement in reader.classes) {
        final path = _readTypedGoRoutePath(classElement);
        if (path == null) continue;
        if (!path.startsWith('/')) {
          log.fine(
            '${classElement.name} skipped: relative route ("$path").',
          );
          continue;
        }
        final extraType = _extraParameterType(classElement);
        if (extraType != null) {
          final routeName = classElement.name ?? '<unknown>';
          excluded.add(_ExcludedRoute(
            route: routeName,
            path: path,
            extra: extraType,
            reason: _deeplinkErrorReason(extraType),
          ));
          log.warning(
            '$routeName excluded from deeplinks: has a \$extra constructor '
            'parameter ($extraType). See $_errorAsset.',
          );
          continue;
        }
        if (!seenPaths.add(path)) continue;
        final segments =
            path.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.isEmpty) {
          log.fine(
            '${classElement.name} skipped: empty host ("$path").',
          );
          continue;
        }
        final host = segments.first;
        final remainder = segments.skip(1).join('/');
        final diverRoute = _readDiverRoute(classElement);
        final fallbackName = remainder.isEmpty ? host : '$host/$remainder';
        final name = (diverRoute?.name.isNotEmpty ?? false)
            ? diverRoute!.name
            : fallbackName;
        routes.add(_Route(
          host: host,
          path: remainder,
          query: _queryParams(classElement, path),
          name: name,
          description: diverRoute?.description ?? '',
        ));
      }
    }

    routes.sort((a, b) {
      final byHost = a.host.compareTo(b.host);
      return byHost != 0 ? byHost : a.path.compareTo(b.path);
    });
    final body = _jsonEncoder.convert({
      'routes': routes.map((r) => r.toJson()).toList(),
    });

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _outputAsset),
      '$body\n',
    );

    // Routes that depend on `$extra` are not deeplink-safe. Surface them in a
    // dedicated error file so they are not lost. The file is written only when
    // there is something to report; build_runner removes a previously generated
    // one automatically once every route is deeplink-safe again.
    if (excluded.isNotEmpty) {
      excluded.sort((a, b) => a.route.compareTo(b.route));
      final errorBody = _jsonEncoder.convert({
        'errors': excluded.map((e) => e.toJson()).toList(),
      });
      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, _errorAsset),
        '$errorBody\n',
      );
    }

    if (!keepGenerated) {
      final file = File(_outputAsset);
      if (await file.exists()) {
        await file.delete();
        log.info('Deleted $_outputAsset (keep_generated=false).');
      }
    }
  }

  String _deeplinkErrorReason(String extraType) =>
      'Route declares a \$extra constructor parameter ($extraType). \$extra '
      'requires a runtime Dart object that cannot be encoded in a URL, so this '
      'route cannot be reached by a deeplink.';

  String? _readTypedGoRoutePath(Element element) {
    for (final annotation in element.metadata.annotations) {
      final annotationElement = annotation.element;
      final enclosingName =
          annotationElement?.enclosingElement?.name ?? annotationElement?.name;
      if (enclosingName != _typedGoRouteName) continue;

      final value = annotation.computeConstantValue();
      final path = value?.getField('path')?.toStringValue();
      if (path != null) return path;
    }
    return null;
  }

  ({String name, String description})? _readDiverRoute(Element element) {
    for (final annotation in element.metadata.annotations) {
      final annotationElement = annotation.element;
      final enclosingName =
          annotationElement?.enclosingElement?.name ?? annotationElement?.name;
      if (enclosingName != _diverRouteName) continue;

      final value = annotation.computeConstantValue();
      final name = value?.getField('name')?.toStringValue();
      final description = value?.getField('description')?.toStringValue();
      if (name == null || description == null) continue;
      return (name: name, description: description);
    }
    return null;
  }

  /// Returns the display type of the `$extra` constructor parameter (e.g.
  /// `Item` or `DeeplinkTemplate?`) if the class declares one, or `null` when
  /// no constructor takes a `$extra` parameter.
  String? _extraParameterType(ClassElement element) {
    for (final constructor in element.constructors) {
      for (final parameter in constructor.formalParameters) {
        if (parameter.name == _extraParamName) {
          return parameter.type.getDisplayString();
        }
      }
    }
    return null;
  }

  List<_Param> _queryParams(ClassElement element, String path) {
    final constructor = element.unnamedConstructor ?? element.constructors.firstOrNull;
    if (constructor == null) return const [];

    final pathParamNames = _pathParamPattern
        .allMatches(path)
        .map((m) => m.group(1)!)
        .toSet();

    final params = <_Param>[];
    for (final parameter in constructor.formalParameters) {
      final name = parameter.name;
      if (name == null || name.isEmpty) continue;
      if (name == _extraParamName) continue;
      if (pathParamNames.contains(name)) continue;
      params.add(_Param(name: _toKebabCase(name), type: _jsonType(parameter.type)));
    }
    return params;
  }

  String _toKebabCase(String input) {
    return input
        .replaceAllMapped(_camelBoundary2, (m) => '${m[1]}-${m[2]}')
        .replaceAllMapped(_camelBoundary1, (m) => '${m[1]}-${m[2]}')
        .toLowerCase();
  }

  String _jsonType(DartType type) {
    if (type.isDartCoreString) return 'string';
    if (type.isDartCoreBool) return 'boolean';
    if (type.isDartCoreInt) return 'string';
    if (type.isDartCoreDouble) return 'string';
    if (type.isDartCoreNum) return 'string';
    if (type.isDartCoreList) return 'list';
    if (type.element is EnumElement) return 'string';
    return type.getDisplayString().toLowerCase();
  }
}

class _Route {
  _Route({
    required this.host,
    required this.path,
    required this.query,
    this.name = '',
    this.description = '',
  });

  final String host;
  final String path;
  final List<_Param> query;
  final String name;
  final String description;

  Map<String, Object?> toJson() => {
        'name': name,
        'description': description,
        'host': host,
        'path': path,
        'query': query.map((p) => p.toJson()).toList(),
      };
}

class _Param {
  _Param({required this.name, required this.type});

  final String name;
  final String type;

  Map<String, Object?> toJson() => {
        'name': name,
        'type': type,
      };
}

/// A route that was kept out of `app_urls.json` because it is not
/// deeplink-safe, recorded in `app_urls_errors.json` with [reason].
class _ExcludedRoute {
  _ExcludedRoute({
    required this.route,
    required this.path,
    required this.extra,
    required this.reason,
  });

  /// Name of the annotated route class, e.g. `DetailRoute`.
  final String route;

  /// The `@TypedGoRoute` path declared on the class, e.g. `/detail`.
  final String path;

  /// Display type of the `$extra` constructor parameter, e.g. `Item`.
  final String extra;

  /// Human-readable explanation of why the route is not deeplink-safe.
  final String reason;

  Map<String, Object?> toJson() => {
        'route': route,
        'path': path,
        'extra': extra,
        'reason': reason,
      };
}
