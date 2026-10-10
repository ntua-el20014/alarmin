import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/features/settings/emoji_input.dart';

void main() {
  test('accepts exactly one emoji, including multi-codepoint ones', () {
    for (final emoji in [
      '💊',
      '🌫️',
      '❤️',
      '👍🏽',
      '👨‍👩‍👧',
      '🇬🇷',
      '1️⃣'
    ]) {
      expect(isSingleEmoji(emoji), isTrue, reason: emoji);
    }
  });

  test('rejects text, digits, and more than one emoji', () {
    for (final value in ['', 'a', 'Pill', '1', '💊💊', '💊a', ':)']) {
      expect(isSingleEmoji(value), isFalse, reason: value);
    }
  });

  test('the formatter keeps only the newest emoji and ignores text', () {
    final formatter = SingleEmojiFormatter();
    TextEditingValue edit(String old, String next) =>
        formatter.formatEditUpdate(
            TextEditingValue(text: old), TextEditingValue(text: next));

    expect(edit('💊', '💊🌫️').text, '🌫️');
    expect(edit('💊', '💊abc').text, '💊');
    expect(edit('', 'hello').text, '');
    expect(edit('💊', '').text, '');
  });

  test('every suggested emoji is accepted', () {
    for (final emoji in suggestedCategoryEmoji) {
      expect(isSingleEmoji(emoji), isTrue, reason: emoji);
    }
  });
}
