import 'package:flutter/services.dart';

// Encrypted key/value bridge. The Android side is EncryptedSharedPreferences
// on channel lr.vault/box.

class LockBox {
  const LockBox();

  static const MethodChannel _channel = MethodChannel('lr.vault/box');

  Future<String?> read(String slot) async {
    try {
      return await _channel.invokeMethod<String>('get', <String, dynamic>{
        'slot': slot,
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String slot, String text) async {
    try {
      await _channel.invokeMethod<void>('put', <String, dynamic>{
        'slot': slot,
        'text': text,
      });
    } catch (_) {}
  }

  Future<void> remove(String slot) async {
    try {
      await _channel.invokeMethod<void>('cut', <String, dynamic>{
        'slot': slot,
      });
    } catch (_) {}
  }
}
