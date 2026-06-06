import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that scans every Dart library in the consuming package for classes
/// carrying a `@TypedGoRoute(...)` annotation and writes a JSON description of
/// each route to `lib/app_urls.json`, sorted alphabetically by path.
///
/// Routes whose class has a `$extra` constructor parameter are excluded:
/// they require a runtime object and cannot be reached by URL alone, so they
/// are not deeplink-safe.
class UrlAggregatorBuilder implements Builder {
  static const _outputAsset = 'lib/app_urls.json';
  static const _outputExtension = 'app_urls.json';
  static const _typedGoRouteName = 'TypedGoRoute';
  static const _extraParamName = r'$extra';

  static final _pathParamPattern = RegExp(r':([a-zA-Z_]\w*)');
  static final _camelBoundary1 = RegExp(r'([a-z0-9])([A-Z])');
  static final _camelBoundary2 = RegExp(r'([A-Z]+)([A-Z][a-z])');
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': [_outputExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final routes = <_Route>[];
    final seenPaths = <String>{};

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (!await buildStep.resolver.isLibrary(input)) continue;
      final library = await buildStep.resolver.libraryFor(input);
      final reader = LibraryReader(library);

      for (final classElement in reader.classes) {
        final path = _readTypedGoRoutePath(classElement);
        if (path == null) continue;
        if (_hasExtraParameter(classElement)) {
          log.fine(
            '${classElement.name} skipped: has \$extra constructor parameter.',
          );
          continue;
        }
        if (!seenPaths.add(path)) continue;
        final segments =
            path.split('/').where((s) => s.isNotEmpty).toList();
        final host = segments.isEmpty ? '' : segments.first;
        final remainder = segments.skip(1).join('/');
        routes.add(_Route(
          host: host,
          path: remainder,
          query: _queryParams(classElement, path),
        ));
      }
    }

    routes.sort((a, b) {
      final byHost = a.host.compareTo(b.host);
      return byHost != 0 ? byHost : a.path.compareTo(b.path);
    });
    final body = _jsonEncoder.convert(routes.map((r) => r.toJson()).toList());

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _outputAsset),
      '$body\n',
    );
  }

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

  bool _hasExtraParameter(ClassElement element) {
    for (final constructor in element.constructors) {
      for (final parameter in constructor.formalParameters) {
        if (parameter.name == _extraParamName) return true;
      }
    }
    return false;
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
    return type.getDisplayString().toLowerCase();
  }
}

class _Route {
  _Route({required this.host, required this.path, required this.query});

  final String host;
  final String path;
  final List<_Param> query;

  Map<String, Object?> toJson() => {
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
