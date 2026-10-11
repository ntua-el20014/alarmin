import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/ringtone.dart';

/// A dropdown of every available sound, plus "Choose audio file…" to import
/// one from the device.
///
/// [value] is a stored ringtone value. When [noneLabel] is given, a null
/// option with that label is offered (for "same as the default sound").
class SoundPicker extends ConsumerStatefulWidget {
  const SoundPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Sound',
    this.noneLabel,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? noneLabel;

  @override
  ConsumerState<SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends ConsumerState<SoundPicker> {
  static const _chooseFile = '__choose_file__';

  /// Bumped to re-create the field after a cancelled pick, so it shows the
  /// previous selection again instead of "Choose audio file…".
  int _version = 0;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final sounds = ref.watch(availableSoundsProvider).value ?? Ringtone.all;
    final selected = widget.value == null && widget.noneLabel != null
        ? null
        : Ringtone.resolve(widget.value);
    final options = [
      ...sounds,
      // The selected sound may not be listed yet: the list loads
      // asynchronously and is refreshed after an import.
      if (selected != null && !sounds.contains(selected)) selected,
    ];

    return DropdownButtonFormField<String?>(
      key: ValueKey('sound-${selected?.id}-$_version'),
      initialValue: selected?.id,
      isExpanded: true,
      decoration: InputDecoration(labelText: widget.label),
      items: [
        if (widget.noneLabel != null)
          DropdownMenuItem<String?>(
              value: null, child: Text(widget.noneLabel!)),
        for (final sound in options)
          DropdownMenuItem<String?>(
            value: sound.id,
            child: Row(
              children: [
                Icon(
                  sound.isCustomFile ? Icons.audio_file : Icons.music_note,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(sound.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        DropdownMenuItem<String?>(
          value: _chooseFile,
          enabled: !_importing,
          child: const Row(
            children: [
              Icon(Icons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choose audio file…'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == _chooseFile) {
          _import();
        } else {
          widget.onChanged(value);
        }
      },
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final imported = await ref.read(soundLibraryProvider).importFromDevice();
      ref.invalidate(availableSoundsProvider);
      if (imported != null) widget.onChanged(imported.id);
    } catch (error) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not import the sound: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
          _version++;
        });
      }
    }
  }
}
