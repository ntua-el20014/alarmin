import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/category_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);

    return ListView(
      children: [
        settings.when(
          data: (value) => _SettingsSection(settings: value),
          loading: () => const ListTile(
            title: Text('Loading settings...'),
            leading: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Categories',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        categories.when(
          data: (items) => _CategorySection(categories: items),
          loading: () => const ListTile(title: Text('Loading categories...')),
          error: (error, stackTrace) => ListTile(title: Text('Error: $error')),
        ),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          title: const Text('Time Picker'),
          subtitle: Text(_timePickerLabel(settings.timePickerStyle)),
          trailing: DropdownButton<TimePickerStyle>(
            value: settings.timePickerStyle,
            items: const [
              DropdownMenuItem(
                value: TimePickerStyle.materialClock,
                child: Text('Clock'),
              ),
              DropdownMenuItem(
                value: TimePickerStyle.cupertinoWheel,
                child: Text('Wheel'),
              ),
            ],
            onChanged: (style) {
              if (style != null) {
                _save(ref, settings.copyWith(timePickerStyle: style));
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Grouped alarms'),
          subtitle: const Text('Group alarms by category by default'),
          value: settings.isGroupedView,
          onChanged: (value) =>
              _save(ref, settings.copyWith(isGroupedView: value)),
        ),
      ],
    );
  }

  Future<void> _save(WidgetRef ref, AppSettings value) {
    return ref.read(settingsRepositoryProvider).save(value);
  }

  String _timePickerLabel(TimePickerStyle style) {
    return style == TimePickerStyle.materialClock
        ? 'Material clock'
        : 'Cupertino wheel';
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final category in categories)
          ListTile(
            leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(category.name),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Edit category',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCategory(context, ref, category),
                ),
                IconButton(
                  tooltip: 'Delete category',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteCategory(context, ref, category),
                ),
              ],
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add category'),
          onTap: () => _editCategory(context, ref),
        ),
      ],
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref, [
    CategoryModel? category,
  ]) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final emojiController = TextEditingController(text: category?.emoji ?? '');
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add category' : 'Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'Emoji')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, (nameController.text, emojiController.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emojiController.dispose();
    if (result == null || result.$1.trim().isEmpty || result.$2.trim().isEmpty)
      return;
    final now = DateTime.now();
    await ref.read(categoryRepositoryProvider).save(
          CategoryModel(
            id: category?.id ?? 'category-${now.microsecondsSinceEpoch}',
            name: result.$1.trim(),
            emoji: result.$2.trim(),
            createdAt: category?.createdAt ?? now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content:
            const Text('Alarms in this category will become uncategorized.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    }
  }
}
