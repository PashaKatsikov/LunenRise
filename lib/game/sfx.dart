import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class Sfx {
  Sfx();

  final List<AudioPlayer> _pool = List.generate(5, (_) => AudioPlayer());
  int _n = 0;
  double volume = 1;
  bool haptics = true;

  Future<void> play(String file, {bool bump = false}) async {
    if (volume <= 0.01) {
      if (bump) _haptic();
      return;
    }
    final p = _pool[_n++ % _pool.length];
    try {
      await p.stop();
      await p.setVolume(volume.clamp(0, 1));
      await p.play(AssetSource(file));
    } catch (_) {}
    if (bump) _haptic();
  }

  void _haptic() {
    if (!haptics) return;
    HapticFeedback.lightImpact();
  }

  Future<void> prime() async {
    for (final AudioPlayer p in _pool) {
      try {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(volume.clamp(0, 1));
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
  }
}
