# Changelog

## 0.1.0

- First release: `@identity` and `Value`, the two halves of a shape, with
  `TurnId`, `SemanticAnchor`, `Target`, `PartyId`, `Withdrawable` and
  `Withdraw<T extends Withdrawable>`, moved out of `is_review_shapes` so that a
  module that declares shapes needs no review shapes to do it. The two
  hashes are `Sha256Name`s from `is_content_id`.
