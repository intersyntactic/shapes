# Changelog

## 0.2.1

- Docs: an agent's party id is `agent:<id>`, an opaque id its install mints
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
