// A module's own shape, the way its shape file declares it, with its
// identity marked. Then a node of it taken back.
import 'package:is_shapes/is_shapes.dart';

/// A note: what it is about is when it was written; its text may be edited
/// without it becoming a different note, and its author may take it back.
final class Note implements Withdrawable {
  const Note({required this.sentAt, required this.text});
  @identity
  final DateTime sentAt;
  final String text;
}

void main() {
  // Ids are read back from text where a node arrives; null if malformed.
  final sent = TurnId.parse(
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  );
  final author = PartyId.parse('slack:U024BE7LH');
  if (sent == null || author == null) return;

  final withdrawal = Withdraw<Note>(target: sent, by: author);
  print('${withdrawal.by} took back ${withdrawal.target}');
}
