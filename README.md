# is_shapes

What an intersyntactic shape file uses to mark the fields a node is about, and
to name a node, point at it exactly or by what it is about, say who wrote it,
and take it back.

A shape is a Dart type, and binding an offering to an acceptor is the analyzer
checking that one type can be assigned to the other
([#1069](https://github.com/enspyrco/intersyntactic/issues/1069)). Dart
matches classes by name, so two modules that each declared a `TurnId` would
have two types, neither of which can be passed for the other. These are
declared once, here, for every module that needs them.

```dart
import 'package:is_shapes/is_shapes.dart';

/// A note is about when it was written; its text is its value, and may be
/// edited; its author may take it back.
final class Note implements Withdrawable {
  const Note({required this.sentAt, required this.text});
  @identity
  final DateTime sentAt;
  final String text;
}

final takeBack = Withdrawal<Note>(target: sent, by: author);
```

## Anchor, version, exact id

A node can be named three ways, each answering one question:

| Question | Name | Hashed from |
|---|---|---|
| What is it about? | its **anchor**, `SemanticAnchor` | shape + identity fields |
| What does it say? | its **version** (no type yet, [#12](https://github.com/intersyntactic/shapes/issues/12)) | shape + all fields |
| Which one, exactly? | its **exact id**, `TurnId` | parent + bytes |

A node is never changed. A new node at an anchor that already has one is a
new exact id, whatever made it: a message edited, a forecast reissued, a
report run again. It's a new version only if it says something different.
Every annotation rule compares two of these. An approval holds for a later
node at its anchor with the same version, the way a GitHub review comment
stays put when a push doesn't touch its line. A correction is held when the
node now at its anchor is another version than the one seen. Who saw what
is the exact id alone.

The "identity version" an anchor is hashed with (RULINGS) is something
else: a number on the shape, changed when the shape changes which fields are
identity.

## What is here

- `@identity`: marks a field as what the node is about. Every other field is
  its value, what it says, which a later node at the same anchor may say
  differently. A shape with no field marked has
  every field as identity, so revision is opt-in
  ([#1068](https://github.com/enspyrco/intersyntactic/issues/1068)). The
  analyzer reads it from source by its type, `Identity`, without running
  anything.
- `Value`: the other half of a shape. A shape that can be corrected gathers
  its value into one class extending `Value`, under whatever name fits it
  (Hart's `RungVerdict extends Value`), and `NodeCorrection<V extends Value>` in
  `is_annotation_shapes` proposes a new one. It is `abstract base`: another
  library can extend it but not implement it, and a record or an extension
  type can't be one. Declare values `final`.
- `TurnId`: one exact node: the sha256 of its parent's id and its own bytes,
  like a git commit.
- `SemanticAnchor`: what a node is about, hashed from its shape and identity
  fields only, so later nodes about the same thing share it.
- `Target`: the two together, so a reference finds a later node at the same
  anchor, and a reader can tell when two nodes have come to share one.
- `ActorId`: who wrote a node, a person or an agent, prefixed by the source
  that minted it: `slack:T0001/U024BE7LH`, or `agent:<id>`, an opaque id the
  agent's install mints on first boot. An agent's name can change; its id
  never does.
- `MissionId`: a mission, one span of work under one set of rules, admitted
  from outside or started in the app, which ends. Named by the hash of the
  record entry that started it, so whoever starts a mission names it.
- `EntryId`: any recorded journal entry (a turn, an event, an airlock
  decision, a reply chunk), the same digest as is_journal's `EntryHash`.
  A `TurnId` gives its own as `turn.entry`; there's no way back, since
  whether an entry is a turn is the record's to say.
- `RendererId`: the code that draws a post, a package published on pub.dev,
  named by the sha256 of that version's archive: the hash `pubspec.lock`
  records and pub.dev reports as `archive_sha256`, which anyone can check
  with `curl … | shasum -a 256`. A renderer imports only the SDK by default,
  since the archive doesn't cover the packages it imports
  ([#1147](https://github.com/enspyrco/intersyntactic/issues/1147)).
- `DecidedBy`: who made a decision a record holds, `rules` (without asking
  the person) or `person`. Records write these names, so they never change.
- `TrajectoryId`: a trajectory, one line of turns in a mission, the
  person's and the agent's alike, named the same way by the entry that
  started it. It names the line, not who is on it. A trajectory is only ever
  started: one launched from a point on another names its parent in its own
  first entry.
- `Withdrawable`: a shape whose nodes can be taken back says so by
  implementing it. A withdrawal is final: changing your mind back is a new
  node, with a new id, which no earlier withdrawal targets.
- `Withdrawal<T extends Withdrawable>`: takes back a `T`, the exact node its
  author wrote. Readers
  apply one rule everywhere: an `X` counts while no later `Withdrawal<X>` from
  its author targets it. `T` routes the withdrawal to the acceptors waiting
  on it; no field holds a `T`, so the reader that fetches the target checks
  it is one.

Every id is a class with a library-private constructor, made by `of`, which
hashes, or by `parse`, which returns null for a malformed one
([enspyrco/intersyntactic#1082](https://github.com/enspyrco/intersyntactic/pull/1082)).
Code that holds one never asks whether it is well formed. They are classes, not
extension types, because a `String` can be cast to an extension type and skip
the check. `TurnId` and `SemanticAnchor` are `Sha256Name`s from
[`is_content_id`](https://github.com/intersyntactic/content_id), made with its
`sha256`, so every name in intersyntactic is made by one sha256 that can be
checked in one place. Two kinds of name with the same bytes are never equal.

The annotation shapes, a comment, a correction and an approval, are built on
these in [`is_annotation_shapes`](https://github.com/intersyntactic/annotation_shapes).
An annotation is a node an actor writes beside another node: it points at that
node and never changes it, as in the
[W3C Web Annotation model](https://www.w3.org/TR/annotation-model/).

## Still open

- **One person, several ids.** Each source mints its own actor ids
  (`slack:T…/U…`, `agent:<id>`), and the prefix keeps them apart, so ids
  from two modules never collide. Nothing yet says when two of them are one
  person, in two modules or in two Slack workspaces. That will be a table
  beside the ids, which changes no id already written.
- **How a node becomes bytes.** `TurnId.of` and `SemanticAnchor.of` hash the
  bytes they are given. Which bytes those are (a node as the trajectory
  stores it; a shape and its identity fields, encoded) is the trajectory's
  and the shape language's to say, so there is no `toJson` here yet.

## The pure list

A shape file may import only what import admission's pure list allows
([#1046](https://github.com/enspyrco/intersyntactic/issues/1046)). This
package imports only `is_content_id`, which imports only `dart:typed_data`;
both have to be added to that list.
`test/pure_list_test.dart` holds it to the list, and it reads every branch of
a conditional import, not only the first.

## Depending on it

```yaml
dependencies:
  is_shapes: ^0.2.0
```

It is published after `is_content_id`, and before `is_annotation_shapes`, since
each depends on the one before.
