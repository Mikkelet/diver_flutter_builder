import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultFilePath = 'diver/app_urls.json';
const _configPath = 'diver/diver_config.properties';
const _orgIdVar = "ORG_ID";
const _appIdVar = "APP_ID";

Future<void> main(List<String> args) async {
  final filePath = args.isNotEmpty ? args.first : _defaultFilePath;

  final env = {..._loadDotEnv(), ...Platform.environment};
  final url = "https://api.diver.mthy.dev/import";

  final file = File(filePath);
  if (!file.existsSync()) {
    stderr
      ..writeln('Error: $filePath not found.')
      ..writeln()
      ..writeln('Make sure you have:')
      ..writeln('  1. Run `dart run build_runner build` to generate the file.')
      ..writeln('  2. Set `keep_generated: true` in your build.yaml — the')
      ..writeln('     builder deletes diver/app_urls.json by default. Example:')
      ..writeln()
      ..writeln('       targets:')
      ..writeln('         \$default:')
      ..writeln('           builders:')
      ..writeln('             diver_flutter_builder|url_aggregator:')
      ..writeln('               options:')
      ..writeln('                 keep_generated: true');
    exit(1);
  }

  final routes = await file.readAsString();
  final decoded = json.decode(routes) as Map;
  final orgId = env[_orgIdVar];
  final appId = env[_appIdVar];

  final body = {...decoded, "org_id": orgId, "app_id": appId};

  final headers = <String, String>{
    'Content-Type': 'application/json',
    // if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',.
  };

  stdout.writeln('Uploading $filePath -> $url');
  final response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: json.encode(body),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    stdout.writeln('Upload succeeded (${response.statusCode}).');
  } else {
    stderr.writeln('Upload failed (${response.statusCode}): ${response.body}');
    exit(1);
  }
}

Map<String, String> _loadDotEnv() {
  final file = File(_configPath);
  if (!file.existsSync()) return const {};

  final result = <String, String>{};
  for (var line in file.readAsLinesSync()) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final eq = line.indexOf('=');
    if (eq < 0) continue;

    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}
