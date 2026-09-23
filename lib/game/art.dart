import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'atlas.dart';
import 'paths.dart';

class Art {
  Art._();

  static final Map<String, ui.Image> _img = {};

  static ui.Image sheet(String key) {
    final hit = _img[key];
    if (hit != null) return hit;
    return _img[Atlas.sheets[key]!]!;
  }

  static ui.Image file(String path) => _img[path]!;

  static void drop() {
    final Set<ui.Image> seen = <ui.Image>{};
    for (final ui.Image img in _img.values) {
      if (seen.add(img)) img.dispose();
    }
    _img.clear();
  }

  static Future<void> load(void Function(double p) onProg) async {
    final paths = <String>[
      ...Atlas.sheets.values,
      Paths.logo,
      Paths.bgLow,
      Paths.bgMid,
      Paths.bgHigh,
    ];
    for (var i = 0; i < paths.length; i++) {
      _img[paths[i]] = await _decode(paths[i]);
      onProg((i + 1) / paths.length);
      await Future<void>.delayed(Duration.zero);
    }
    for (final e in Atlas.sheets.entries) {
      _img[e.key] = _img[e.value]!;
    }
  }

  static Future<ui.Image> _decode(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
