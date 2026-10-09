/// Built-in ringtones bundled under `assets/audio/`.
///
/// Alarms and settings store the ringtone [id], never the asset path, so the
/// bundled files can change without rewriting saved alarms.
class Ringtone {
  const Ringtone(this.id, this.label, this.assetPath);

  final String id;
  final String label;
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

  /// Resolves a stored ringtone value to a bundled ringtone.
  ///
  /// Unknown values, including legacy ones such as `default` or the
  /// never-bundled `assets/audio/default.mp3`, fall back to [fallback] so an
  /// alarm always has playable audio.
  static Ringtone resolve(String? value) {
    for (final ringtone in all) {
      if (ringtone.id == value || ringtone.assetPath == value) return ringtone;
    }
    return fallback;
  }
}
