import 'dart:typed_data';

import 'package:is_content_id/is_content_id.dart';
import 'package:is_shapes/is_shapes.dart';
import 'package:test/test.dart';

const _hex = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// Two shapes as a module declares them, both of which can be taken back.
final class _Reaction implements Withdrawable {}

final class _Message implements Withdrawable {}

/// A value as a module declares one.
final class _Level extends Value {
  const _Level(this.level);
  final int level;
}

PartyId _peter() => PartyId.parse('slack:U024BE7LH')!;

void main() {
  group('TurnId and SemanticAnchor', () {
    test('parse reads a sha256 in lower-case hex', () {
      expect(TurnId.parse(_hex)?.hex, _hex);
      expect(SemanticAnchor.parse(_hex)?.hex, _hex);
      expect(TurnId.parse(_hex).toString(), _hex);
    });

    test('parse refuses anything else', () {
      for (final s in [
        '',
        _hex.substring(1),
        '${_hex}0',
        _hex.toUpperCase(),
        'g${_hex.substring(1)}',
        ' $_hex',
        '$_hex\n',
      ]) {
        expect(TurnId.parse(s), isNull, reason: s);
        expect(SemanticAnchor.parse(s), isNull, reason: s);
      }
    });

    test('equal to the same kind with the same hex', () {
      expect(TurnId.parse(_hex), TurnId.parse(_hex));
      expect(TurnId.parse(_hex).hashCode, TurnId.parse(_hex).hashCode);
    });

    test('of hashes with is_content_id\'s sha256', () {
      // _hex is the sha256 of no bytes.
      expect(TurnId.of(Uint8List(0)).hex, _hex);
      expect(SemanticAnchor.of(Uint8List(0)).hex, _hex);
      expect(TurnId.of(Uint8List(0)), TurnId.parse(_hex));
    });

    test('a turn id is never equal to another kind with the same bytes', () {
      expect(TurnId.parse(_hex), isNot(SemanticAnchor.parse(_hex)));
      expect(TurnId.of(Uint8List(0)), isNot(ObjectId.of(Uint8List(0))));
    });

    test('a string cannot be cast to one', () {
      // What an extension type over String would allow.
      Object raw = _hex;
      expect(() => raw as TurnId, throwsA(isA<TypeError>()));
    });
  });

  group('PartyId', () {
    test('parse reads a source, a colon, and the rest', () {
      for (final s in [
        'slack:U024BE7LH',
        'slack:T0001:U024BE7LH',
        'agent:hart-79',
        'a0-b:!~',
      ]) {
        expect(PartyId.parse(s)?.value, s);
      }
    });

    test('parse refuses anything else', () {
      for (final s in [
        '',
        'U024BE7LH',
        ':U024BE7LH',
        'slack:',
        'T0001:U024BE7LH',
        '0a:b',
        '-a:b',
        'a_b:c',
        'slack:two words',
        'slack:line\n',
        'slack:tab\t',
        'slack:ñame',
      ]) {
        expect(PartyId.parse(s), isNull, reason: s);
      }
    });

    test('equal to a party id with the same text', () {
      expect(
        PartyId.parse('slack:U024BE7LH'),
        PartyId.parse('slack:U024BE7LH'),
      );
      expect(
        PartyId.parse('slack:U024BE7LH'),
        isNot(PartyId.parse('slack:U024BE7LI')),
      );
    });
  });

  test('a target is equal to one with the same two ids', () {
    Target target() =>
        Target(exact: TurnId.parse(_hex)!, anchor: SemanticAnchor.parse(_hex)!);
    expect(target(), target());
    expect(target().hashCode, target().hashCode);
  });

  test('a withdrawal says what it takes back, at run time too', () {
    final withdrawal = Withdraw<_Reaction>(
      target: TurnId.parse(_hex)!,
      by: _peter(),
    );
    expect(withdrawal, isA<Withdraw<_Reaction>>());
    expect(withdrawal, isNot(isA<Withdraw<_Message>>()));
    expect(withdrawal.target, TurnId.parse(_hex));
    expect(withdrawal.by, _peter());
  });

  test('a module declares its own value by extending Value', () {
    const Value value = _Level(2);
    expect(value, isA<_Level>().having((v) => v.level, 'level', 2));
  });

  test('identity is the one Identity', () {
    expect(identity, isA<Identity>());
  });
}
