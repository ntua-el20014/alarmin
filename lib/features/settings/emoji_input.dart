import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Matches characters that are drawn as emoji: pictographs (💊, 🌫, ❤),
/// flag letters, and keycaps such as 1️⃣.
final _emojiPattern = RegExp(
  // The lint checks the pattern without `unicode: true`, where \p{...} is
  // invalid; with the flag it is valid (covered by emoji_input_test.dart).
  // ignore: valid_regexps
  r'\p{Extended_Pictographic}|[\u{1F1E6}-\u{1F1FF}]|\u{20E3}',
  unicode: true,
);

/// Whether [value] is exactly one emoji. Multi-codepoint emoji (skin tones,
/// families, flags, 🌫️ with its variation selector) count as one.
bool isSingleEmoji(String value) {
  final characters = value.characters;
  return characters.length == 1 && _emojiPattern.hasMatch(characters.first);
}

/// Keeps a text field to a single emoji: typing a new emoji replaces the old
/// one, and anything that is not an emoji is ignored.
class SingleEmojiFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final emoji = newValue.text.characters.where(isSingleEmoji);
    if (emoji.isEmpty) return oldValue;
    final last = emoji.last;
    return TextEditingValue(
      text: last,
      selection: TextSelection.collapsed(offset: last.length),
    );
  }
}

/// Emoji offered as one-tap choices for a category.
const suggestedCategoryEmoji = <String>[
  '💊', '🌫️', '💼', '🏠', '❤️', '🏃', '📚', '🍽️', //
  '💧', '🛏️', '🐶', '✈️', '🎂', '🧘', '🚗', '🛒',
];
