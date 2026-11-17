/// What a shape file uses to mark the fields a node is about, and to name a
/// node, point at it exactly or by what it is about, say who wrote it, and
/// take it back.
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
///   exactly and by what it is about.
/// - [EntryId]: any recorded journal entry, which a [TurnId] gives its own.
/// - [RendererId]: the code that draws a post from recorded entries.
/// - [ActorId]: who wrote a node.
/// - [DecidedBy]: whether a decision was the rules' or the person's.
/// - [MissionId] and [TrajectoryId]: the mission a node is in, and the
///   trajectory, its line of turns, within it.
/// - [Withdrawal]: takes back a node its author wrote, of a shape that is
///   [Withdrawable].
///
/// The annotation shapes, a comment, a correction and an approval, are built
/// on these in `is_annotation_shapes`. An annotation is a node an actor writes
/// beside another node: it points at that node and never changes it.
///
/// A node can be named three ways, each answering one question:
///
/// - What is it about? Its anchor, a [SemanticAnchor]: its shape and its
///   identity fields.
/// - What does it say? Its version: its shape and all its fields.
/// - Which one, exactly? Its exact id, a [TurnId]: its parent and its bytes,
///   so it names the node's whole history.
///
/// A node is never changed. A new node at an anchor that already has one is
/// a new exact id, whatever made it: a message edited, a forecast reissued,
/// a report run again. It is a new version only if it says something
/// different. Every rule an annotation follows compares two of these: in
/// `is_annotation_shapes`, an approval holds for a later node at its anchor
/// with the same version, a correction is held when the node now at its
/// anchor is another version than the one seen, and who saw what is the
/// exact id alone.
///
/// A version has no type here yet. A reader compares what two nodes say
/// itself, until a fixed byte layout for a shape's fields lets one hash name
/// it (https://github.com/intersyntactic/shapes/issues/12). The "identity
/// version" an anchor is hashed with is something else: a number on the
/// shape, changed when the shape changes which fields are identity.
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

final _actorId = RegExp(r'^[a-z][a-z0-9-]*:[\x21-\x7e]+$');

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
/// opt-in: a field is value, which a later node at the same anchor may say
/// differently, only when its shape says so (https://github.com/enspyrco/intersyntactic/issues/1068).
///
/// Nothing runs it. The analyzer reads it from a shape file's source, by its
/// type, [Identity] (https://github.com/enspyrco/intersyntactic/issues/1069).
/// Only a field's metadata annotations are read.
const identity = Identity._();

/// The type of [identity]. Its constructor is private, so [identity] is the
/// only one, and a reader looking for the metadata annotation looks for this
/// type.
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
/// (`NodeCorrection<V extends Value>`, in `is_annotation_shapes`). Classes match by
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
/// it, and [Withdrawal] takes only these:
///
/// ```dart
/// final class NodeApproval implements Withdrawable { ... }
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
/// `Withdrawal<X>` from its author targets it. A withdrawal by anyone else
/// counts for nothing, so a reader checks that [by] wrote [target].
///
/// [T] says what is taken back, so an acceptor waiting on withdrawn approvals
/// accepts `Withdrawal<NodeApproval>` and is never handed a withdrawn Slack
/// reaction. No field holds a [T], so nothing here checks that [target] is
/// one; the reader that fetches [target] does.
///
/// [target] is the exact node, not an anchor: what is taken back is the one
/// node its author wrote, not a later node at its anchor.
final class Withdrawal<T extends Withdrawable> {
  const Withdrawal({required this.target, required this.by});

  /// The node taken back.
  final TurnId target;

  /// Who took it back. It counts only if this is who wrote [target].
  final ActorId by;
}

/// A node, both exactly and by what it is about: the node that was seen,
/// and its anchor.
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

  /// What it is about, which a later node may share.
  final SemanticAnchor anchor;

  @override
  bool operator ==(Object other) =>
      other is Target && other.exact == exact && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(exact, anchor);
}

/// One exact node: the sha256 of its parent's id and its own bytes, like a
/// git commit, so it names the node's whole history. Two nodes with the same
/// fields in different places have different ids.
///
/// A turn recorded in a journal is named by the hash of the entry that
/// recorded it, which names the entry before it and the turn's bytes, so
/// [entry] is the same name as an [EntryId].
///
/// It is a different kind of name from a [SemanticAnchor] or an `ObjectId`,
/// so the same bytes as one of those are never equal to it.
final class TurnId extends Sha256Name {
  TurnId._(super.digest);

  /// The journal entry that recorded this turn, as an id any entry has: what
  /// a reference to recorded entries of every kind holds.
  EntryId get entry => EntryId._(bytes);

  /// The id of the node whose bytes, as the trajectory stores them, are
  /// [node]. Which bytes those are is the trajectory's to say: it is what
  /// mints a node's id.
  factory TurnId.of(Uint8List node) => TurnId._(sha256(node));

  /// [s] as a turn id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static TurnId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => TurnId._(d),
    null => null,
  };
}

/// A recorded journal entry, of any kind: a turn, an event, an airlock
/// decision, a chunk of a reply. It is the sha256 of the entry, the same
/// digest as `is_journal`'s `EntryHash`, so a reader asks the journal for
/// the entry by it and checks that what comes back hashes to it.
///
/// A [TurnId] is one of these that is known to be a turn, and gives its own
/// by [TurnId.entry]. There is no way back: whether an entry is a turn is
/// for the record to say. So an entry has one [EntryId] however it was
/// reached, and a set of them holds each entry once, where an `EntryId` that
/// a [TurnId] extended would be unequal to that same [TurnId].
final class EntryId extends Sha256Name {
  EntryId._(super.digest);

  /// The id of the entry whose bytes, as the journal stores them, are
  /// [entry].
  factory EntryId.of(Uint8List entry) => EntryId._(sha256(entry));

  /// [s] as an entry id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static EntryId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => EntryId._(d),
    null => null,
  };
}

/// A renderer: a package published on pub.dev whose `lib/` draws a post's
/// words from recorded entries, named by the sha256 of that version's
/// archive. That is the hash an app's `pubspec.lock` records for it and
/// pub.dev reports as its `archive_sha256`, so the person checks it without
/// running anything:
///
///     curl -sL https://pub.dev/api/archives/<name>-<version>.tar.gz |
///       shasum -a 256
///
/// pub.dev never changes or deletes a version, so the id names code anyone
/// can fetch for as long as the record is read, and nothing else has to
/// keep it (https://github.com/enspyrco/intersyntactic/issues/1147).
///
/// The archive holds the renderer's own code and its `pubspec.yaml`, not
/// the packages it imports. So a renderer imports only the SDK part of
/// import admission's pure list by default. One that imports a package pins
/// it exactly in its `pubspec.yaml`, which the archive covers, but not what
/// that package itself depends on, which can still move. So the id alone
/// does not pin the code a renderer runs with, its dependencies or the Dart
/// SDK: the executable's own hash, recorded beside it, names what actually
/// ran.
///
/// It cannot hold its own id, since no file can hold its own hash: whatever
/// builds it reads the id from `pubspec.lock`.
final class RendererId extends Sha256Name {
  RendererId._(super.digest);

  /// [s] as a renderer id, read back from text, such as a `pubspec.lock`'s
  /// `sha256` for the renderer or pub.dev's `archive_sha256`; null unless it
  /// is a sha256 in lower-case hex.
  static RendererId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => RendererId._(d),
    null => null,
  };
}

/// What a node is about: hashed from its shape and its identity fields,
/// never its parent or its value. So a reference to one node still finds a
/// later one at its anchor, which says something new about the same thing.
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

/// A mission: one span of work under one set of rules, admitted from outside
/// or started in the app, which ends. A Teams channel is a mission, started
/// by its first thread.
///
/// Named by the hash of the record entry that started it. Whoever starts a
/// mission names it, by writing that entry, so a mission has one name and
/// nothing has to be asked to hand one out. It is the same hash as the
/// entry's own, as a different kind of name, so it is never equal to the
/// entry's hash, or to the [TrajectoryId] of a trajectory the same entry
/// started.
final class MissionId extends Sha256Name {
  MissionId._(super.digest);

  /// The id of the mission started by the entry whose bytes, as the record
  /// stores them, are [entry].
  factory MissionId.of(Uint8List entry) => MissionId._(sha256(entry));

  /// [s] as a mission id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static MissionId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => MissionId._(d),
    null => null,
  };
}

/// A trajectory: one line of turns in a mission, the person's and the
/// agent's alike, such as one thread of a Teams channel. It names the line,
/// not who is on it: who wrote a turn is its [ActorId].
///
/// Named, like its [MissionId], by the hash of the record entry that started
/// it. Its entries carry it, so they can be told from every other
/// trajectory's, after a restart too.
///
/// A trajectory is only ever started: an entry can't hold its own hash, so a
/// trajectory named in an entry its parent writes would need its name before
/// that entry exists. One launched from a point on another says so in its
/// own first entry, naming its parent, the way a git commit names its parent
/// and never its children.
final class TrajectoryId extends Sha256Name {
  TrajectoryId._(super.digest);

  /// The id of the trajectory started by the entry whose bytes, as the
  /// record stores them, are [entry].
  factory TrajectoryId.of(Uint8List entry) => TrajectoryId._(sha256(entry));

  /// [s] as a trajectory id, read back from text; null unless it is a sha256
  /// in lower-case hex.
  static TrajectoryId? parse(String s) => switch (Sha256Name.digestOfHex(s)) {
    final d? => TrajectoryId._(d),
    null => null,
  };
}

/// Who wrote a node: a person, or an agent, by an id that stays the same for
/// as long as they do, prefixed by the source that minted it, such as a Slack
/// user (`slack:T0001/U024BE7LH`) or an agent (`agent:<id>`, an opaque id its
/// install mints on first boot). An agent's name is not part of its id: the
/// name can change, and the id never does.
///
/// An actor id is a source, a colon, and the rest. The source is a lower-case
/// letter, then lower-case letters, digits or hyphens. The rest is printable
/// ASCII with no spaces, and is the source's business, further colons
/// included. Like a URI's scheme, the prefix says who owns the rest, so two
/// modules never write the same id for two actors. Saying that two ids are
/// one person is a table beside them, which changes no id already written.
///
/// That is narrow on purpose: allowing more later breaks no id already
/// written, and allowing less would.
final class ActorId {
  const ActorId._(this.value);

  /// The id, as text.
  final String value;

  /// [s] as an actor id, read back from text; null unless it is a source, a
  /// colon, and the rest.
  static ActorId? parse(String s) => _actorId.hasMatch(s) ? ActorId._(s) : null;

  @override
  bool operator ==(Object other) => other is ActorId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Who made a decision a record entry holds: the [rules], or the [person].
/// So the record tells "the rules let it through" from "the person said
/// yes", wherever something is decided: the airlock deciding a run, the
/// docking port deciding an arrival.
///
/// A record writes a value by its [Enum.name], so the names are permanent:
/// rename one and every entry already written says something else.
enum DecidedBy {
  /// Decided without asking the person, by the rules it falls under: a
  /// trajectory's rules for a run, a mission's and its turns' for an
  /// arrival.
  rules,

  /// The person decided, when asked or on their own, as by stopping a
  /// trajectory.
  person,
}
