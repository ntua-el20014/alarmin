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
  /// permission. Picking a file that was already imported reuses that copy.
  /// Returns null if the user cancelled.
  Future<Ringtone?> importFromDevice() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null) return null;
    try {
      final directory = await _soundsDirectory();
      await directory.create(recursive: true);
      final existing = await _findSameFile(directory, picked);
      if (existing != null) return Ringtone.fromPath(existing.path);
      final target = await _uniqueFile(directory, _safeName(picked.name));
      await _store(picked, target);
      return Ringtone.fromPath(target.path);
    } finally {
      // On Android the picker leaves its own copy of the file in the cache.
      await _clearPickerCache();
    }
  }

  /// Deletes imported sounds whose path is not in [inUse], and anything the
  /// file picker left in the cache.
  Future<void> removeUnused(Set<String> inUse) async {
    await _clearPickerCache();
    for (final sound in await imported()) {
      if (inUse.contains(sound.assetPath)) continue;
      try {
        await File(sound.assetPath).delete();
      } on FileSystemException {
        // Still there next time; nothing else depends on it.
      }
    }
  }

  /// Moves the picker's temporary copy into place when there is one (no
  /// extra disk space), otherwise streams the file across.
  static Future<void> _store(PlatformFile picked, File target) async {
    final temporary = picked.path;
    if (temporary != null && _isPickerCache(temporary)) {
      try {
        await File(temporary).rename(target.path);
        return;
      } on FileSystemException {
        // Different file system: copy instead.
      }
    }
    final sink = target.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
    } finally {
      await sink.close();
    }
  }

  static bool _isPickerCache(String path) =>
      path.replaceAll(r'', '/').contains('/cache/file_picker/');

  static Future<void> _clearPickerCache() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (_) {
      // Not supported on every platform.
    }
  }

  /// An already imported file with the same bytes as [picked], if any.
  /// Only files of the same length are read, so this is usually free.
  static Future<File?> _findSameFile(
    Directory directory,
    PlatformFile picked,
  ) async {
    final length = picked.lengthSync() ?? await picked.length();
    if (length == null) return null;
    Uint8List? pickedBytes;
    await for (final entity in directory.list()) {
      if (entity is! File || await entity.length() != length) continue;
      pickedBytes ??= await picked.readAsBytes();
      if (_sameBytes(await entity.readAsBytes(), pickedBytes)) return entity;
    }
    return null;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
