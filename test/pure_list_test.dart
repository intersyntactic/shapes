import 'dart:io';

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

/// Every URI a source's directives name, in every branch: a conditional
/// import names one URI per branch, and the analyzer's element model holds
/// only the branch it picked, so reading the first misses the rest. Comments
/// go and strings stay whole in one left-to-right pass, so the `//` in
/// `'file:///x.dart'` stays in its URI and an apostrophe in a comment opens
/// no string. Directives precede declarations, so a string this short pattern
/// misreads further down (an escaped quote, a triple quote) can't hide one.
Iterable<String> directiveUris(String source) sync* {
  final code = source.replaceAllMapped(
    RegExp(r'''('[^'\n]*'|"[^"\n]*")|/\*[\s\S]*?\*/|//[^\n]*'''),
    (m) => m[1] ?? '',
  );
  final directive = RegExp(
    r'(?<=^|;)\s*(?:import|export|part)\b[^;]*;',
    multiLine: true,
  );
  final quoted = RegExp(r'''['"]([^'"]*)['"]''');
  for (final d in directive.allMatches(code)) {
    for (final q in quoted.allMatches(d[0]!)) {
      yield q[1]!;
    }
  }
}

bool _isPure(String target) {
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
