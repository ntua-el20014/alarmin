import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/alarm_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/mission.dart';
import '../missions/mission_picker.dart';
import '../settings/emoji_input.dart';
import '../sounds/sound_picker.dart';

/// Shows the add/edit category dialog and saves the result. Returns the
/// saved category, or null if the dialog was cancelled. Used by Settings and
/// by the alarm editor.
Future<CategoryModel?> showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  CategoryModel? category,
}) async {
  final result = await showDialog<_CategoryDraft>(
    context: context,
    builder: (context) => CategoryDialog(category: category),
  );
  if (result == null) return null;
  final now = DateTime.now();
  final saved = CategoryModel(
    id: category?.id ?? 'category-${now.microsecondsSinceEpoch}',
    name: result.name,
    emoji: result.emoji,
    defaultRingtone: result.ringtone,
    defaultVibration: result.vibration,
    defaultWakeStyle: result.wakeStyle,
    defaultMission: result.mission.isNone ? null : result.mission,
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

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.emoji,
    required this.ringtone,
    required this.vibration,
    required this.wakeStyle,
    required this.mission,
  });

  final String name;
  final String emoji;
  final String? ringtone;
  final VibrationSetting? vibration;
  final WakeStyle? wakeStyle;
  final Mission mission;
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
  late String? _ringtone = widget.category?.defaultRingtone;
  late VibrationSetting? _vibration = widget.category?.defaultVibration;
  late WakeStyle? _wakeStyle = widget.category?.defaultWakeStyle;
  late Mission _mission =
      widget.category?.defaultMission ?? const Mission.none();

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
    Navigator.pop(
      context,
      _CategoryDraft(
        name: name,
        emoji: emoji,
        ringtone: _ringtone,
        vibration: _vibration,
        wakeStyle: _wakeStyle,
        mission: _mission,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.category == null,
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
            const SizedBox(height: 20),
            Text('Defaults for new alarms', style: theme.textTheme.titleSmall),
            Text(
              'New alarms in this category start with these. "App default" '
              'uses Settings.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SoundPicker(
              label: 'Sound',
              noneLabel: 'App default',
              value: _ringtone,
              onChanged: (value) => setState(() => _ringtone = value),
            ),
            DropdownButtonFormField<VibrationSetting?>(
              initialValue: _vibration,
              decoration: const InputDecoration(labelText: 'Vibrate'),
              items: const [
                DropdownMenuItem(value: null, child: Text('App default')),
                DropdownMenuItem(
                  value: VibrationSetting.standard,
                  child: Text('On'),
                ),
                DropdownMenuItem(
                  value: VibrationSetting.off,
                  child: Text('Off'),
                ),
              ],
              onChanged: (value) => setState(() => _vibration = value),
            ),
            DropdownButtonFormField<WakeStyle?>(
              initialValue: _wakeStyle,
              decoration: const InputDecoration(labelText: 'Wake style'),
              items: const [
                DropdownMenuItem(value: null, child: Text('App default')),
                DropdownMenuItem(
                  value: WakeStyle.normal,
                  child: Text('Normal'),
                ),
                DropdownMenuItem(
                  value: WakeStyle.gentle,
                  child: Text('Gentle (fade in)'),
                ),
              ],
              onChanged: (value) => setState(() => _wakeStyle = value),
            ),
            const SizedBox(height: 12),
            Text('Mission to dismiss', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            MissionPicker(
              value: _mission,
              onChanged: (mission) => setState(() => _mission = mission),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
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
