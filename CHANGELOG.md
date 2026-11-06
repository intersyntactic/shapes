# Changelog

## 0.2.0

- **Breaking:** a `PartyId` is prefixed by the source that minted it, so
  `PartyId.parse` reads `<source>:<rest>` and returns null for a bare id:
  `slack:T0001/U024BE7LH`, not `U024BE7LH`. The source is a lower-case
  letter, then lower-case letters, digits or hyphens; the rest is printable
  ASCII with no spaces, further colons included. Ids from two modules can no
  longer collide (https://github.com/intersyntactic/shapes/issues/4).

## 0.1.0

- First release: `@identity` and `Value`, the two halves of a shape, with
  `TurnId`, `SemanticAnchor`, `Target`, `PartyId`, `Withdrawable` and
  `Withdraw<T extends Withdrawable>`, moved out of `is_review_shapes` so that a
  module that declares shapes needs no review shapes to do it. The two
  hashes are `Sha256Name`s from `is_content_id`.
