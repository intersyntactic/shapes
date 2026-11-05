# is_shapes

What an intersyntactic shape file uses to mark the fields a node is about, and
to name a node, point at it in any pass, say who wrote it, and take it back.

A shape is a Dart type, and binding an offering to an acceptor is the analyzer
checking that one type can be assigned to the other
([#1069](https://github.com/enspyrco/intersyntactic/issues/1069)). Dart
matches classes by name, so two modules that each declared a `TurnId` would
have two types, neither of which can be passed for the other. These are
declared once, here, for every module that needs them.

```dart
import 'package:is_shapes/is_shapes.dart';

/// A message is about when it was sent; its text may be edited.
final class Message {
  const Message({required this.sentAt, required this.text});
  @identity
  final DateTime sentAt;
  final String text;
}

final takeBack = Withdraw<Message>(target: sent, by: author);
```

## What is here

- `@identity`: marks a field as what the node is about. Every other field is a
  verdict, which a later pass may change. A shape with no field marked has
  every field as identity, so revision is opt-in
  ([#1068](https://github.com/enspyrco/intersyntactic/issues/1068)). The
  analyzer reads it from source by its type, `Identity`, without running
  anything.
- `TurnId`: one exact node. Its id hashes its parent's, like a git commit.
- `SemanticAnchor`: the same node in any pass, hashed from its shape and
  identity fields only.
- `Target`: the two together, so a reference survives a new pass and a reader
  can tell when two nodes have come to share an anchor.
- `PartyId`: who wrote a node, a person or an agent.
- `Withdraw<T>`: takes back a `T`, the exact node its author wrote. Readers
  apply one rule everywhere: an `X` counts while no later `Withdraw<X>` from
  its author targets it. `T` routes the withdrawal to the acceptors waiting
  on it; no field holds a `T`, so the reader that fetches the target checks
  it is one.

Every id is a class with a library-private constructor, made only by `parse`,
which returns null for a malformed one
([enspyrco/intersyntactic#1082](https://github.com/enspyrco/intersyntactic/pull/1082)).
Code that holds one never asks whether it is well formed. They are classes, not
extension types, because a `String` can be cast to an extension type and skip
the check.

The review shapes, a comment, a correction and an approval, are built on these
in [`is_review_shapes`](https://github.com/intersyntactic/review_shapes), for
the modules where a person judges something.

## Still open

- **What a party is.** `PartyId` is printable ASCII with no spaces until the
  roster settles it. That is narrow on purpose: allowing more later breaks no
  id already written, and allowing less would. It holds an id, never a display
  name. Every id the Slack module writes fits it (Slack's own `U…`, `T…:U…`,
  `B…`, and agent ids like `slack:c0`).
- **How a node becomes bytes.** There is no `toJson` yet. The line mints a
  `TurnId` by hashing a node, and a `SemanticAnchor` by hashing its shape and
  identity fields, so the encoding belongs with that hash, not here.
- **Withdrawing a withdrawal.** `Withdraw<Withdraw<X>>` type-checks. Neither
  Hart nor Slack needs it, since changing your mind back is a new node with a
  new id, so readers should ignore one. That waits on a ruling in
  [#1073](https://github.com/enspyrco/intersyntactic/issues/1073).

## The pure list

A shape file may import only what import admission's pure list allows
([#1046](https://github.com/enspyrco/intersyntactic/issues/1046)), so this
package imports nothing at all, and it has to be added to that list.
`test/pure_list_test.dart` holds it to the list, and it reads every branch of
a conditional import, not only the first.

## Depending on it

It isn't published yet. Until it is:

```yaml
dependencies:
  is_shapes:
    git: git@github.com:intersyntactic/shapes.git
```
