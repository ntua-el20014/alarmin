import 'dart:io';

/// A sound an alarm or the timer can play.
///
/// Three kinds exist, all stored as a plain string on the alarm/settings:
/// - built-in tones, stored by short id (`classic`);
/// - any other file under `assets/audio/` in the app bundle, stored by its
///   asset path (drop a file there and rebuild; see [isBundledAsset]);
/// - a file the user picked, copied into app storage, stored by its
///   absolute path (see [isCustomFile]).
class Ringtone {
  const Ringtone(this.id, this.label, this.assetPath);

  /// What gets stored on the alarm.
  final String id;
  final String label;

  /// The path handed to the native player: an `assets/...` path or an
  /// absolute file path.
  final String assetPath;

  static const classic =
      Ringtone('classic', 'Classic beep', 'assets/audio/classic.wav');
  static const gentle =
      Ringtone('gentle', 'Gentle chime', 'assets/audio/gentle.wav');
  static const digital =
      Ringtone('digital', 'Digital', 'assets/audio/digital.wav');

  static const all = <Ringtone>[classic, gentle, digital];
  static const fallback = classic;
  static const fallbackId = 'classic';

  /// Stored on an alarm that plays the default sound from Settings, looked
  /// up when the alarm is scheduled.
  static const followDefault = 'default';

  static const audioFolder = 'assets/audio/';
  static const audioExtensions = {'.mp3', '.wav', '.ogg', '.m4a', '.aac'};

  bool get isCustomFile => assetPath.startsWith('/');

  static bool isBundledAsset(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith(audioFolder) &&
        audioExtensions.any((extension) => lower.endsWith(extension));
  }

  /// A ringtone for an asset path or file path, labelled by its file name.
  factory Ringtone.fromPath(String path) {
    for (final ringtone in all) {
      if (ringtone.assetPath == path) return ringtone;
    }
    return Ringtone(path, labelFor(path), path);
  }

  /// `morning_birds.mp3` becomes `Morning birds`.
  static String labelFor(String path) {
    var name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (name.isEmpty) return 'Sound';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Resolves a stored ringtone value to something playable.
  ///
  /// Unknown values, including legacy ones such as `default` or the
  /// never-bundled `assets/audio/default.mp3`, and picked files that no
  /// longer exist, fall back to [fallback] so an alarm always makes sound.
  static Ringtone resolve(String? value) {
    if (value == null) return fallback;
    for (final ringtone in all) {
      if (ringtone.id == value || ringtone.assetPath == value) return ringtone;
    }
    if (isBundledAsset(value) && value != 'assets/audio/default.mp3') {
      return Ringtone.fromPath(value);
    }
    if (value.startsWith('/') && File(value).existsSync()) {
      return Ringtone.fromPath(value);
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is Ringtone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
