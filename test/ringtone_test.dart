import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:alarmin/data/models/ringtone.dart';

void main() {
  test('built-in ids and legacy values resolve to bundled tones', () {
    expect(Ringtone.resolve('gentle'), Ringtone.gentle);
    expect(Ringtone.resolve('assets/audio/digital.wav'), Ringtone.digital);
    expect(Ringtone.resolve('default'), Ringtone.fallback);
    expect(Ringtone.resolve('assets/audio/default.mp3'), Ringtone.fallback);
    expect(Ringtone.resolve(null), Ringtone.fallback);
  });

  test('extra files under assets/audio are playable and labelled', () {
    final ringtone = Ringtone.resolve('assets/audio/morning_birds.mp3');

    expect(ringtone.assetPath, 'assets/audio/morning_birds.mp3');
    expect(ringtone.label, 'Morning birds');
    expect(ringtone.isCustomFile, isFalse);
    expect(Ringtone.isBundledAsset('assets/audio/README.md'), isFalse);
  });

  test('imported files resolve while they exist, then fall back', () async {
    final directory = await Directory.systemTemp.createTemp('alarmin_sound');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/my-song.mp3')..writeAsBytesSync([0]);
    final path = file.absolute.path.replaceAll(r'\', '/');
    // Only absolute POSIX-style paths count as files; skip on Windows hosts.
    if (!path.startsWith('/')) return;

    expect(Ringtone.resolve(path).isCustomFile, isTrue);
    expect(Ringtone.resolve(path).label, 'My song');

    file.deleteSync();
    expect(Ringtone.resolve(path), Ringtone.fallback);
  });
}
