# Changelog

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
