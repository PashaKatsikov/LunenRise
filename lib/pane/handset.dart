import 'dart:io';

import 'package:flutter/services.dart';

import '../drawer/slips.dart';

class BoardFields {
  const BoardFields({
    required this.release,
    required this.brand,
    required this.model,
    required this.display,
  });

  final String release;
  final String brand;
  final String model;
  final String display;
}

class BoardRead {
  BoardRead._();

  static const MethodChannel _channel = MethodChannel('lr.hw/board');

  static Future<BoardFields?> read() async {
    if (!Platform.isAndroid) return null;
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>('scan');
      if (raw == null) return null;
      return BoardFields(
        release: (raw['rel'] as String?) ?? '',
        brand: (raw['make'] as String?) ?? '',
        model: (raw['sku'] as String?) ?? '',
        display: (raw['tag'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

// One user-agent string shared by Courier and the sheet WebView.
class Handset {
  Handset._();

  static String _ua = '';

  static String get userAgent {
    if (_ua.isEmpty) return _fallback();
    return _ua;
  }

  static Future<void> prime() async {
    try {
      if (!Platform.isAndroid) return;
      final BoardFields? info = await BoardRead.read();
      if (info == null) return;
      _ua = _assemble(
        release: info.release,
        brand: _title(info.brand),
        model: info.model,
        buildTag: info.display.isNotEmpty ? info.display : 'AP3A.241105.008',
      );
    } catch (_) {
      _ua = _fallback();
    }
  }

  static String _assemble({
    required String release,
    required String brand,
    required String model,
    required String buildTag,
  }) {
    final String chrome = _or(pullBrowserRev(), '132.0.6834.79');
    final String webkit = _or(pullEngineRev(), '537.36');
    final String product = _or(pullUaToken(), _seedToken);
    final String platform = _or(pullUaPlatform(), _seedPlatform);
    final String buildLabel = _or(pullUaBuild(), _seedBuild);
    final String close = _or(pullUaClose(), _seedClose);
    final String engine = _or(pullUaEngine(), _seedEngine);
    final String engineTail = _or(pullUaEngineTail(), _seedEngineTail);
    final String browser = _or(pullUaBrowser(), _seedBrowser);
    final String trailer = _or(pullUaTrailer(), _seedTrailer);

    return '$product $platform $release; $brand $model'
        '$buildLabel$buildTag$close'
        '$engine$webkit$engineTail'
        '$browser$chrome'
        '$trailer$webkit';
  }

  static String _fallback() => _assemble(
        release: '15',
        brand: 'Google',
        model: 'Pixel 8',
        buildTag: 'AP3A.241105.008',
      );

  static String _or(String encoded, String fallback) =>
      encoded.isNotEmpty ? encoded : fallback;

  static String _title(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }

  static String _join(List<int> a, List<int> b) =>
      String.fromCharCodes(a) + String.fromCharCodes(b);

  static String get _seedToken => _join(
        const <int>[77, 111, 122],
        const <int>[105, 108, 108, 97, 47, 53, 46, 48],
      );

  static String get _seedPlatform => _join(
        const <int>[40, 76, 105, 110, 117, 120],
        const <int>[59, 32, 65, 110, 100, 114, 111, 105, 100],
      );

  static String get _seedBuild =>
      String.fromCharCodes(const <int>[32, 66, 117, 105, 108, 100, 47]);

  static String get _seedClose => String.fromCharCode(41);

  static String get _seedEngine => _join(
        const <int>[32, 65, 112, 112, 108, 101, 87],
        const <int>[101, 98, 75, 105, 116, 47],
      );

  static String get _seedEngineTail => _join(
        const <int>[32, 40, 75, 72, 84, 77, 76],
        const <int>[44, 32, 108, 105, 107, 101, 32, 71, 101, 99, 107, 111, 41],
      );

  static String get _seedBrowser =>
      String.fromCharCodes(const <int>[32, 67, 104, 114, 111, 109, 101, 47]);

  static String get _seedTrailer => _join(
        const <int>[32, 77, 111, 98, 105, 108, 101],
        const <int>[32, 83, 97, 102, 97, 114, 105, 47],
      );
}
