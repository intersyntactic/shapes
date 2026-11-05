/// What a shape file uses to mark the fields a node is about, and to name a
/// node, point at it in any pass, say who wrote it, and take it back.
///
/// A shape is a Dart type, and binding is the analyzer checking that an
/// offering's type can be assigned to an acceptor's
/// (https://github.com/enspyrco/intersyntactic/issues/1069). Dart matches
/// classes by name, so two modules that each declared a `TurnId` would have
/// two types, neither of which can be passed for the other. These are
/// declared once, here, for every module that needs them.
///
/// - [identity]: marks the fields a node is about.
/// - [TurnId], [SemanticAnchor], and the [Target] made of the two: a node,
///   exactly and in any pass.
/// - [PartyId]: who wrote a node.
/// - [Withdraw]: takes back a node its author wrote.
///
/// The review shapes, a comment, a correction and an approval, are built on
/// these in `is_review_shapes`, for the modules where a person judges
/// something.
///
/// An id is a class with a library-private constructor, made only by `parse`,
/// which returns null for a malformed one. So code holding one never asks
/// whether it is well formed. Classes, not extension types, since a `String`
/// can be cast to an extension type and skip every check.
///
/// It imports nothing, so a shape file may import it under import admission's
/// pure list (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

final _sha256Hex = RegExp(r'^[0-9a-f]{64}$');
final _printableAscii = RegExp(r'^[\x21-\x7e]+$');

/// Marks a field of a shape as identity: what the node is about. Every other
/// field is a verdict: what the node concludes.
///
/// ```dart
/// final class SlackMessage {
///   const SlackMessage({required this.ts, required this.text});
///   @identity
///   final SlackTs ts;
///   final String text;
/// }
/// ```
///
/// A shape with no field marked has every field as identity. So revision is
/// opt-in: a field is a verdict, which a later pass may change, only when its
/// shape says so (https://github.com/enspyrco/intersyntactic/issues/1068).
///
/// Nothing runs it. The analyzer reads it from a shape file's source, by its
/// type, [Identity] (https://github.com/enspyrco/intersyntactic/issues/1069).
/// Only a field's annotations are read.
const identity = Identity._();

/// The type of [identity]. Its constructor is private, so [identity] is the
/// only one, and a reader looking for the annotation looks for this type.
final class Identity {
  const Identity._();
}

/// Takes back a [T]: the node at [target], which [by] wrote.
///
/// A node is never changed once written, so taking one back is a new node.
/// Readers apply one rule to every shape: an `X` counts while no later
/// `Withdraw<X>` from its author targets it. A withdrawal by anyone else
/// counts for nothing, so a reader checks that [by] wrote [target].
///
/// [T] says what is taken back, so an acceptor waiting on withdrawn approvals
/// accepts `Withdraw<Approve>` and is never handed a withdrawn Slack reaction.
/// No field holds a [T], so nothing here checks that [target] is one; the
/// reader that fetches [target] does.
///
/// [target] is the exact node, not an anchor: what is taken back is the one
/// node its author wrote, not whatever is at its anchor in a later pass.
final class Withdraw<T extends Object> {
  const Withdraw({required this.target, required this.by});

  /// The node taken back.
  final TurnId target;

  /// Who took it back. It counts only if this is who wrote [target].
  final PartyId by;
}

/// A node, both exactly and in any pass: the node that was seen, and its
/// anchor.
///
/// A reader following it can fetch both: the node at [exact], and the node
/// now at [anchor]. If they differ in what the reader depends on, two
/// different nodes may have come to share an anchor, and the reader decides
/// what that means. An acceptor applying a correction holds it for a fresh
/// approval (https://github.com/enspyrco/intersyntactic/issues/1068).
final class Target {
  const Target({required this.exact, required this.anchor});

  /// The node that was seen.
  final TurnId exact;

  /// The same node, in any pass.
  final SemanticAnchor anchor;

  @override
  bool operator ==(Object other) =>
      other is Target && other.exact == exact && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(exact, anchor);
}

/// A sha256 used as a name, written as lower-case hex. Each kind of name
/// extends it, and two kinds with the same hex are never equal, so one can't
/// be passed or compared as the other.
sealed class _Sha256Hex {
  const _Sha256Hex(this.hex);

  /// The sha256 in lower-case hex: 64 characters.
  final String hex;

  /// Equal only to the same kind of name with the same hex.
  @override
  bool operator ==(Object other) =>
      other is _Sha256Hex &&
      other.runtimeType == runtimeType &&
      other.hex == hex;

  @override
  int get hashCode => Object.hash(runtimeType, hex);

  @override
  String toString() => hex;
}

/// One exact node.
///
/// A node's id is a hash of its parent's id and its own bytes, like a git
/// commit, so it names the node's whole path. Two nodes with the same fields
/// in different places have different ids.
///
/// Only [parse] makes one here. What mints a node's id is the line, which
/// hashes the node; this package never sees a node's bytes.
final class TurnId extends _Sha256Hex {
  const TurnId._(super.hex);

  /// [s] as a turn id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static TurnId? parse(String s) => _sha256Hex.hasMatch(s) ? TurnId._(s) : null;
}

/// The same node in any pass: hashed from its shape and its identity fields,
/// never its parent or its verdicts. So a reference made on one pass still
/// finds its node in the next, where the verdict has changed and the identity
/// has not.
///
/// How the hash is taken is the shape language's to say
/// (https://github.com/enspyrco/intersyntactic/issues/1068). This type only
/// holds it.
final class SemanticAnchor extends _Sha256Hex {
  const SemanticAnchor._(super.hex);

  /// [s] as an anchor, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static SemanticAnchor? parse(String s) =>
      _sha256Hex.hasMatch(s) ? SemanticAnchor._(s) : null;
}

/// Who wrote a node: a person, or an agent.
///
/// What a party is, and whether the roster names it, is still open
/// (https://github.com/enspyrco/intersyntactic/issues/1073). Until that is
/// settled, a party id is printable ASCII with no spaces, such as a Slack user
/// id or a roster key. That is narrow on purpose: allowing more later breaks
/// no id already written, and allowing less would.
///
/// It holds an id, never a display name: a name may have spaces in it, and
/// may change.
final class PartyId {
  const PartyId._(this.value);

  /// The id, as text.
  final String value;

  /// [s] as a party id, read back from text; null unless it is one or more
  /// printable ASCII characters, none of them a space.
  static PartyId? parse(String s) =>
      _printableAscii.hasMatch(s) ? PartyId._(s) : null;

  @override
  bool operator ==(Object other) => other is PartyId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
