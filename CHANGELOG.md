# Changelog

## 0.5.1

- `RendererId` is deprecated. Renderers are cut (Nick, 18 Nov): a send
  carries its exact bytes, a projection of recorded turns, and the airlock
  approves those bytes and checks that they come from a recorded turn, so
  no code is named. It is deprecated rather than removed, so no package has
  to move to a new minor version for it. It goes in the next release that
  has to break anyway.
- Docs name is_lint_rules' checks and is_annotation_shapes 0.3.0's types
  (https://github.com/intersyntactic/shapes/pull/21,
  https://github.com/intersyntactic/shapes/pull/22).

## 0.5.0

- **Breaking:** `JourneyId` is `MissionId`, and `JourneyPathId` is
  `TrajectoryId` (Nick, 17 Nov). A mission is one span of work under one
  set of rules, admitted from outside or started in the app, which ends. A
  trajectory is one line of turns in a mission, the person's and the
  agent's alike: it names the line, not who is on it. Nothing else about
  either id changes: each is still the sha256 of the record entry that
  started it, so ids already computed keep their hex.
- **Breaking:** `RendererId.of(FileSetId)`, deprecated in 0.4.5, is gone.
  Read a renderer's id with `RendererId.parse`.

## 0.4.5

- A `RendererId` is the sha256 of the renderer's published pub.dev archive,
  as `pubspec.lock` records it and pub.dev reports it as `archive_sha256`,
  not the `FileSetId` of its `lib/`. pub.dev keeps every version, so the id
  names code anyone can fetch, and anyone can check it with `shasum`. A
  renderer imports only the SDK by default, since the archive doesn't
  cover the packages it imports.
- `RendererId.of(FileSetId)` is deprecated, and removed in 0.5.0. Read an
  id with `RendererId.parse`.
- Docs: a node can be named three ways, by its anchor (what it is about),
  its version (what it says) and its exact id (which one, exactly). "Pass",
  which the docs used for a later node at the same anchor and never
  defined, is gone: an edit, a reissue and a re-run all make one the same
  way. The version has no type yet
  (https://github.com/intersyntactic/shapes/issues/12).

## 0.4.4

- `EntryId`: any recorded journal entry, so a post can reference events,
  airlock entries and reply chunks as well as turns. A `TurnId` gives its
  own as `TurnId.entry`. It's a separate kind rather than a supertype of
  `TurnId`, so one entry has one `EntryId` however it was reached.
- `RendererId`: a renderer, named by the `FileSetId` of its package's
  `lib/*.dart` (https://github.com/enspyrco/intersyntactic/issues/1147).

## 0.4.3

- `DecidedBy { rules, person }`: who made a decision a record entry holds,
  shared by the airlock and the docking port. It replaces
  `is_airlock_api`'s, with the same two names in the same order.

## 0.4.2

- `JourneyPathId`: a journey path, named by the hash of the record entry
  that started it, like `JourneyId`. It replaces `is_airlock_api`'s, whose
  `parse` took any non-blank string; this one takes only a sha256 in
  lower-case hex.

## 0.4.1

- `JourneyId`: a journey, named by the hash of the record entry that started
  it, the way a `TurnId` names a node. It is a `Sha256Name`, made by `of` or
  read back by `parse`, so it cannot hold the retired server's
  ten-character journey ids.

## 0.4.0

- **Breaking:** `Withdraw<T extends Withdrawable>` is renamed `Withdrawal<T
  extends Withdrawable>`. A node records something that happened, so it is a
  noun, like `Comment` and `Correction` — `Withdraw<Approve>` read as two
  commands stuck together. `Withdrawable` is unchanged.

## 0.3.2

- Require `is_content_id ^0.2.0`, so shapes no longer collides with other
  packages that need it.

## 0.3.1

- Docs: a journey's "line" is a journey path, so the docs say where a node's
  bytes are stored in those words, and a `TurnId` names a node's whole
  history rather than its "path".

## 0.3.0

- **Breaking:** `PartyId` is renamed `ActorId`, and "party" is "actor"
  throughout: an actor is anyone who writes a node or is named in one.
  Nothing else about the id changes: `ActorId.parse` reads the same
  `<source>:<rest>` grammar.
- Docs: an agent's actor id is `agent:<id>`, an opaque id its install mints
  on first boot, not the agent's name, which can change.

## 0.2.0

- **Breaking:** a `PartyId` is prefixed by the source that minted it, so
  `PartyId.parse` reads `<source>:<rest>` and returns null for a bare id:
  `slack:T0001/U024BE7LH`, not `U024BE7LH`. The source is a lower-case
  letter, then lower-case letters, digits or hyphens; the rest is printable
  ASCII with no spaces, further colons included. Ids from two modules can no
  longer collide (https://github.com/intersyntactic/shapes/issues/4).
- The docs name `is_annotation_shapes`, which `is_review_shapes` was renamed
  to, and call `@identity` a metadata annotation, leaving "annotation" to a
  node written beside another.

## 0.1.0

- First release: `@identity` and `Value`, the two halves of a shape, with
  `TurnId`, `SemanticAnchor`, `Target`, `PartyId`, `Withdrawable` and
  `Withdraw<T extends Withdrawable>`, moved out of `is_review_shapes` so that a
  module that declares shapes needs no review shapes to do it. The two
  hashes are `Sha256Name`s from `is_content_id`.
