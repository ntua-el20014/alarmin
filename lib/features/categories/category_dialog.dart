import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/category_model.dart';
import '../settings/emoji_input.dart';

/// Shows the add/edit category dialog and saves the result. Returns the
/// saved category, or null if the dialog was cancelled. Used by Settings and
/// by the alarm editor.
Future<CategoryModel?> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  CategoryModel? category,
}) async {
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => CategoryDialog(category: category),
  );
  if (result == null) return null;
  final now = DateTime.now();
  final saved = CategoryModel(
    id: category?.id ?? 'category-${now.microsecondsSinceEpoch}',
    name: result.$1,
    emoji: result.$2,
    createdAt: category?.createdAt ?? now,
    updatedAt: now,
  );
  await ref.read(categoryRepositoryProvider).save(saved);
  // Scheduled notifications show the category emoji in their title.
  if (category != null && category.emoji != saved.emoji) {
    await ref.read(alarmServiceProvider).recover();
  }
  return saved;
}

/// Owns its text controllers so they are disposed only after the dialog's
/// closing animation, not while its fields are still on screen.
class CategoryDialog extends StatefulWidget {
  const CategoryDialog({super.key, this.category});

  final CategoryModel? category;

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.category?.name ?? '');
  late final TextEditingController _emoji =
      TextEditingController(text: widget.category?.emoji ?? '🏷️');

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

  String? _error;

  void _submit() {
    final name = _name.text.trim();
    final emoji = _emoji.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (!isSingleEmoji(emoji)) {
      setState(() => _error = 'Pick one emoji.');
      return;
    }
    Navigator.pop(context, (name, emoji));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emoji,
              inputFormatters: [SingleEmojiFormatter()],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32),
              decoration: const InputDecoration(
                labelText: 'Emoji',
                helperText: 'One emoji, from your emoji keyboard or below',
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final emoji in suggestedCategoryEmoji)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _emoji.text = emoji;
                      _error = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
