import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

/// Import admission's pure list
/// (https://github.com/enspyrco/intersyntactic/issues/1046): what a shape
/// file may import, so all this package may import too.
const _pureSdk = {
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:math',
  'dart:typed_data',
};
const _purePackages = {
  'checked_json',
  'is_tools_api',
  'is_content_id',
  'is_shapes',
};

/// Every URI a source's directives name, in every branch, read from its parse
/// tree: a conditional import keeps one [Configuration] per branch there,
/// where the analyzer's element model holds only the branch it picked. The
/// parser already knows comments, strings and metadata, so nothing here reads
/// them again. A URI that isn't a plain string is null.
Iterable<String?> directiveUris(String source) sync* {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final directive in unit.directives.whereType<UriBasedDirective>()) {
    yield directive.uri.stringValue;
    if (directive is NamespaceDirective) {
      for (final branch in directive.configurations) {
        yield branch.uri.stringValue;
      }
    }
  }
}

bool _isPure(String? target) {
  if (target == null) return false;
  final uri = Uri.parse(target);
  return switch (uri.scheme) {
    'dart' => _pureSdk.contains(target),
    'package' => _purePackages.contains(uri.pathSegments.first),
    '' => !uri.pathSegments.contains('..'),
    _ => false,
  };
}

void main() {
  test('lib imports only what is on the pure list', () {
    final violations = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final target in directiveUris(file.readAsStringSync()))
            if (!_isPure(target)) '${file.path}: $target',
    ];
    expect(violations, isEmpty, reason: 'a shape file may import only these');
  });
}
