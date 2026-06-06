import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that scans every Dart library in the consuming package for classes
/// carrying a `@TypedGoRoute(...)` annotation and writes their `path` values
/// to `lib/app_urls.txt`, one per line, sorted alphabetically.
///
/// Routes whose class has a `$extra` constructor parameter are excluded:
/// they require a runtime object and cannot be reached by URL alone, so they
/// are not deeplink-safe.
class UrlAggregatorBuilder implements Builder {
  static const _outputAsset = 'lib/app_urls.txt';
  static const _outputExtension = 'app_urls.txt';
  static const _typedGoRouteName = 'TypedGoRoute';
  static const _extraParamName = r'$extra';

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': [_outputExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final paths = <String>{};

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
        paths.add(path);
      }
    }

    final sorted = paths.toList()..sort();
    final body = sorted.isEmpty ? '' : '${sorted.join('\n')}\n';

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _outputAsset),
      body,
    );
  }

  String? _readTypedGoRoutePath(Element element) {
    for (final annotation in element.metadata) {
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
      for (final parameter in constructor.parameters) {
        if (parameter.name == _extraParamName) return true;
      }
    }
    return false;
  }
}
