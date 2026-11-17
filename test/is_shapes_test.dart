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

ActorId _peter() => ActorId.parse('slack:T0001/U024BE7LH')!;

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

  group('MissionId', () {
    test('parse reads a sha256 in lower-case hex, and nothing else', () {
      expect(MissionId.parse(_hex)?.hex, _hex);
      for (final s in ['', _hex.toUpperCase(), '${_hex}0', 'a1b2c3d4e5']) {
        expect(MissionId.parse(s), isNull, reason: s);
      }
    });

    test('of hashes the entry that started it', () {
      expect(MissionId.of(Uint8List(0)), MissionId.parse(_hex));
      expect(
        MissionId.of(Uint8List(0)).hashCode,
        MissionId.parse(_hex).hashCode,
      );
    });

    test('never equal to another kind of name with the same bytes', () {
      expect(MissionId.parse(_hex), isNot(TurnId.parse(_hex)));
      expect(MissionId.of(Uint8List(0)), isNot(ObjectId.of(Uint8List(0))));
    });
  });

  group('EntryId', () {
    test('parse reads a sha256 in lower-case hex, and nothing else', () {
      expect(EntryId.parse(_hex)?.hex, _hex);
      for (final s in ['', _hex.toUpperCase(), '${_hex}0']) {
        expect(EntryId.parse(s), isNull, reason: s);
      }
      expect(EntryId.of(Uint8List(0)), EntryId.parse(_hex));
    });

    test('a turn gives the entry that recorded it, one id per entry', () {
      final turn = TurnId.parse(_hex)!;
      expect(turn.entry, EntryId.parse(_hex));
      expect(turn.entry, isNot(turn));
      expect({turn.entry, EntryId.parse(_hex)}, hasLength(1));
    });
  });

  group('RendererId', () {
    test('reads an archive sha256, as a kind of its own', () {
      // is_shapes 0.4.4's archive_sha256 on pub.dev, as pubspec.lock has it.
      const archive =
          '6177616c5b7c14354e9410551a1acb2d31177ffb014e1289b6ae48571f0dd82b';
      expect(RendererId.parse(archive)?.hex, archive);
      expect(RendererId.parse(archive), isNot(ObjectId.parse(archive)));
      expect(RendererId.parse('teams-reply'), isNull);
      expect(RendererId.parse('is_teams_reply-0.1.0'), isNull);
    });
  });

  group('TrajectoryId', () {
    test('parse reads a sha256 in lower-case hex, and nothing else', () {
      expect(TrajectoryId.parse(_hex)?.hex, _hex);
      // The airlock's old TrajectoryId took any non-blank string.
      for (final s in ['', ' ', 'root', 'child', _hex.toUpperCase()]) {
        expect(TrajectoryId.parse(s), isNull, reason: s);
      }
    });

    test('of hashes the entry that started it', () {
      expect(TrajectoryId.of(Uint8List(0)), TrajectoryId.parse(_hex));
    });

    test('never equal to the mission the same entry started', () {
      expect(TrajectoryId.of(Uint8List(0)), isNot(MissionId.of(Uint8List(0))));
    });
  });

  test('DecidedBy is rules then person, by those names', () {
    // Records write these names; changing one rewrites every entry's meaning.
    expect(DecidedBy.values.map((v) => v.name), ['rules', 'person']);
  });

  group('ActorId', () {
    test('parse reads a source, a colon, and the rest', () {
      for (final s in [
        'slack:T0001/U024BE7LH',
        'a:b:c',
        'agent:example',
        'a0-b:!~',
      ]) {
        expect(ActorId.parse(s)?.value, s);
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
        expect(ActorId.parse(s), isNull, reason: s);
      }
    });

    test('equal to an actor id with the same text', () {
      expect(
        ActorId.parse('slack:T0001/U024BE7LH'),
        ActorId.parse('slack:T0001/U024BE7LH'),
      );
      expect(
        ActorId.parse('slack:T0001/U024BE7LH'),
        isNot(ActorId.parse('slack:T0001/U024BE7LI')),
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
    final withdrawal = Withdrawal<_Reaction>(
      target: TurnId.parse(_hex)!,
      by: _peter(),
    );
    expect(withdrawal, isA<Withdrawal<_Reaction>>());
    expect(withdrawal, isNot(isA<Withdrawal<_Message>>()));
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
