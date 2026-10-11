import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ringtone.dart';

/// Lists the sounds alarms and the timer can use, and imports new ones.
class SoundLibrary {
  /// Built-in tones first, then every other audio file bundled under
  /// `assets/audio/` (alphabetical), then files imported from the device.
  Future<List<Ringtone>> available() async {
    return [...await bundled(), ...await imported()];
  }

  Future<List<Ringtone>> bundled() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final extra = manifest
        .listAssets()
        .where(Ringtone.isBundledAsset)
        .where((path) => Ringtone.all.every((tone) => tone.assetPath != path))
        .toList()
      ..sort();
    return [...Ringtone.all, ...extra.map(Ringtone.fromPath)];
  }

  Future<List<Ringtone>> imported() async {
    final directory = await _soundsDirectory();
    if (!await directory.exists()) return const [];
    final files = await directory
        .list()
        .where((entity) => entity is File)
        .map((entity) => entity.path)
        .toList();
    files.sort();
    return files.map(Ringtone.fromPath).toList();
  }

  /// Lets the user pick an audio file and copies it into app storage, so it
  /// keeps working if the original is moved and needs no storage
  /// permission. Returns null if the user cancelled.
  Future<Ringtone?> importFromDevice() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null) return null;
    final directory = await _soundsDirectory();
    await directory.create(recursive: true);
    final target = await _uniqueFile(directory, _safeName(picked.name));
    final sink = target.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
    } finally {
      await sink.close();
    }
    return Ringtone.fromPath(target.path);
  }

  Future<Directory> _soundsDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}sounds');
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w.\- ]'), '_').trim();
    return cleaned.isEmpty ? 'sound' : cleaned;
  }

  static Future<File> _uniqueFile(Directory directory, String name) async {
    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final extension = dot > 0 ? name.substring(dot) : '';
    var candidate = File('${directory.path}${Platform.pathSeparator}$name');
    for (var copy = 2; await candidate.exists(); copy++) {
      candidate = File(
        '${directory.path}${Platform.pathSeparator}$stem ($copy)$extension',
      );
    }
    return candidate;
  }
}
