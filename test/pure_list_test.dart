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

/// Every URI a source's directives name, in every branch, as written, read
/// from its parse tree: a conditional import keeps one [Configuration] per
/// branch there, where the analyzer's element model holds only the branch it
/// picked. The parser already knows comments, strings and metadata, so nothing
/// here reads them again. The switch covers the sealed [Directive]
/// exhaustively, so a new kind of directive stops this compiling.
Iterable<StringLiteral> directiveUris(String source) sync* {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final directive in unit.directives) {
    yield* switch (directive) {
      NamespaceDirective(:final uri, :final configurations) => [
        uri,
        for (final branch in configurations) branch.uri,
      ],
      PartDirective(:final uri) => [uri],
      LibraryDirective() || PartOfDirective() => const <StringLiteral>[],
    };
  }
}

bool _isPure(StringLiteral literal) {
  final target = literal.stringValue;
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
          for (final uri in directiveUris(file.readAsStringSync()))
            if (!_isPure(uri)) '${file.path}: ${uri.toSource()}',
    ];
    expect(violations, isEmpty, reason: 'a shape file may import only these');
  });
}
