import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Derives a color scheme from an emoji, so the ring screen of a 💊 alarm is
/// reddish and a 🌫️ alarm is grey, without the user picking colors.
class EmojiPalette {
  EmojiPalette._();

  static const _renderSize = 64;
  static final _cache = <String, Color?>{};

  /// The emoji's dominant color, or null if it cannot be rendered.
  static Future<Color?> seedColor(String emoji) async {
    if (_cache.containsKey(emoji)) return _cache[emoji];
    Color? color;
    try {
      color = dominantColor(await _render(emoji));
    } catch (_) {
      color = null;
    }
    return _cache[emoji] = color;
  }

  /// A scheme that stays close to [seed], including grey seeds; the default
  /// tonal-spot variant would tint a grey seed with a random hue.
  static ColorScheme schemeFor(Color seed, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
  }

  static Future<Uint8List> _render(String emoji) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: _renderSize * 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        (_renderSize - painter.width) / 2,
        (_renderSize - painter.height) / 2,
      ),
    );
    painter.dispose();
    final image =
        await recorder.endRecording().toImage(_renderSize, _renderSize);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Picks the dominant color of RGBA pixels.
  ///
  /// Opaque pixels are grouped by hue, weighted by how saturated and bright
  /// they are, and the heaviest hue wins. Outlines and highlights barely
  /// count, so a pill's red beats its black outline. If almost nothing is
  /// colorful (fog, a cloud), the average grey is returned instead. Returns
  /// null when no pixel is opaque.
  static Color? dominantColor(Uint8List rgba) {
    const bins = 24;
    final weights = List<double>.filled(bins, 0);
    final sums = List.generate(bins, (_) => [0.0, 0.0, 0.0]);
    var opaque = 0;
    var neutralCount = 0;
    var neutralR = 0.0, neutralG = 0.0, neutralB = 0.0;

    for (var i = 0; i + 3 < rgba.length; i += 4) {
      if (rgba[i + 3] < 128) continue;
      opaque++;
      final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
      final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
      final weight = hsv.saturation * hsv.value;
      if (hsv.saturation < 0.2 || hsv.value < 0.2) {
        neutralCount++;
        neutralR += r;
        neutralG += g;
        neutralB += b;
        continue;
      }
      final bin = (hsv.hue / 360 * bins).floor() % bins;
      weights[bin] += weight;
      sums[bin][0] += r * weight;
      sums[bin][1] += g * weight;
      sums[bin][2] += b * weight;
    }
    if (opaque == 0) return null;

    var best = 0;
    for (var bin = 1; bin < bins; bin++) {
      if (weights[bin] > weights[best]) best = bin;
    }
    final colorful = weights.fold<double>(0, (sum, w) => sum + w);
    if (colorful < opaque * 0.08) {
      if (neutralCount == 0) return const Color(0xFF9E9E9E);
      return Color.fromARGB(
        255,
        (neutralR / neutralCount).round().clamp(0, 255),
        (neutralG / neutralCount).round().clamp(0, 255),
        (neutralB / neutralCount).round().clamp(0, 255),
      );
    }
    final weight = weights[best];
    return Color.fromARGB(
      255,
      (sums[best][0] / weight).round().clamp(0, 255),
      (sums[best][1] / weight).round().clamp(0, 255),
      (sums[best][2] / weight).round().clamp(0, 255),
    );
  }
}
