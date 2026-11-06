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
/// - [Value]: the other half, what a node currently says, when a shape gathers
///   it into one type that can be revised whole.
/// - [TurnId], [SemanticAnchor], and the [Target] made of the two: a node,
///   exactly and in any pass.
/// - [PartyId]: who wrote a node.
/// - [Withdraw]: takes back a node its author wrote, of a shape that is
///   [Withdrawable].
///
/// The review shapes, a comment, a correction and an approval, are built on
/// these in `is_review_shapes`, for the modules where a person judges
/// something.
///
/// An id is a class with a library-private constructor, made by `of`, which
/// hashes, or by `parse`, which returns null for a malformed one. So code
/// holding one never asks whether it is well formed. Classes, not extension
/// types, since a `String` can be cast to an extension type and skip every
/// check. The two hashes are `Sha256Name`s from `is_content_id`, made with its
/// `sha256`, so every name in intersyntactic is made by one sha256 that can be
/// checked in one place.
///
/// It imports only `is_content_id`, so a shape file may import it under import
/// admission's pure list once both are on it
/// (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

import 'dart:typed_data';

import 'package:is_content_id/is_content_id.dart';

final _partyId = RegExp(r'^[a-z][a-z0-9-]*:[\x21-\x7e]+$');

/// Marks a field of a shape as identity: what the node is about. Every other
/// field is its value: what it currently says.
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
/// opt-in: a field is value, which a later pass may change, only when its
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

/// What a node currently says, gathered into one type: the fields that are
/// not [identity], in a shape whose value can be revised whole.
///
/// A shape that can be corrected declares its own value as a class extending
/// this one, under whatever name fits it, and holds it in one field:
///
/// ```dart
/// final class RungVerdict extends Value {
///   const RungVerdict(this.level, this.rationale);
///   final RungLevel level;
///   final String rationale;
/// }
///
/// final class Rung {
///   const Rung({required this.failureMode, required this.verdict});
///   @identity
///   final String failureMode;
///   final RungVerdict verdict;
/// }
/// ```
///
/// A correction is generic over the value it proposes, bounded by this class
/// (`Correction<V extends Value>`, in `is_review_shapes`). Classes match by
/// name, so the analyzer refuses a correction that proposes one shape's value
/// to another, even when their fields are the same. A record or an extension
/// type can't extend a class, so neither can be a value; and a class survives
/// at run time, so a delivered value can be checked with `is`. Declare a
/// value `final`: one with subclasses would let a correction proposing a
/// subclass bind where its parent is accepted.
///
/// It is `base`, so another library can extend it but never implement it. It
/// is not `sealed`, since only its own library could extend a sealed class,
/// and every module declares its own values.
abstract base class Value {
  const Value();
}

/// A shape whose nodes can be taken back. A shape says so by implementing
/// it, and [Withdraw] takes only these:
///
/// ```dart
/// final class Approve implements Withdrawable { ... }
/// ```
///
/// A withdrawal is final. Changing your mind back is a new node, with a new
/// id, which no earlier withdrawal targets, so a reader asks one question of
/// any node: is there a later withdrawal of it from its author?
abstract interface class Withdrawable {}

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
final class Withdraw<T extends Withdrawable> {
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

/// One exact node: the sha256 of its parent's id and its own bytes, like a
/// git commit, so it names the node's whole path. Two nodes with the same
/// fields in different places have different ids.
///
/// It is a different kind of name from a [SemanticAnchor] or an `ObjectId`,
/// so the same bytes as one of those are never equal to it.
final class TurnId extends Sha256Name {
  TurnId._(super.digest);

  /// The id of the node whose bytes, as the line stores them, are [node].
  /// Which bytes those are is the line's to say: it is what mints a node's id.
  factory TurnId.of(Uint8List node) => TurnId._(sha256(node));

  /// [s] as a turn id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static TurnId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => TurnId._(d),
    null => null,
  };
}

/// The same node in any pass: hashed from its shape and its identity fields,
/// never its parent or its value. So a reference made on one pass still finds
/// its node in the next, where the value has changed and the identity has not.
final class SemanticAnchor extends Sha256Name {
  SemanticAnchor._(super.digest);

  /// The anchor of a node whose shape and identity fields, encoded, are
  /// [identity]. How they are encoded is the shape language's to say
  /// (https://github.com/enspyrco/intersyntactic/issues/1068).
  factory SemanticAnchor.of(Uint8List identity) =>
      SemanticAnchor._(sha256(identity));

  /// [s] as an anchor, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static SemanticAnchor? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => SemanticAnchor._(d),
    null => null,
  };
}

/// Who wrote a node: a person, or an agent, by an id that stays the same for
/// as long as they do, prefixed by the source that minted it, such as a Slack
/// user (`slack:T0001/U024BE7LH`) or an agent's name (`agent:hart-79`).
///
/// A party id is a source, a colon, and the rest. The source is a lower-case
/// letter, then lower-case letters, digits or hyphens. The rest is printable
/// ASCII with no spaces, and is the source's business, further colons
/// included. Like a URI's scheme, the prefix says who owns the rest, so two
/// modules never write the same id for two parties. Saying that two ids are
/// one person is a table beside them, which changes no id already written.
///
/// That is narrow on purpose: allowing more later breaks no id already
/// written, and allowing less would.
final class PartyId {
  const PartyId._(this.value);

  /// The id, as text.
  final String value;

  /// [s] as a party id, read back from text; null unless it is a source, a
  /// colon, and the rest.
  static PartyId? parse(String s) => _partyId.hasMatch(s) ? PartyId._(s) : null;

  @override
  bool operator ==(Object other) => other is PartyId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
