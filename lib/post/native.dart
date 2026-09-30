import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

// dart:ffi bridge to liblumen_core.so. The relay endpoint, veil secret and the
// schema-4 envelope codec live in the native library, not in the Dart image.
// The blocking HTTPS call runs in a short-lived isolate so the UI never stalls.

typedef _RouteNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _RouteDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

typedef _VaultNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _VaultDart = Pointer<Utf8> Function(Pointer<Utf8>);

String _routeSync(String body, String ua) {
  final DynamicLibrary lib = DynamicLibrary.open('liblumen_core.so');
  final _RouteDart route = lib.lookupFunction<_RouteNative, _RouteDart>('lr_route');
  final _FreeDart free = lib.lookupFunction<_FreeNative, _FreeDart>('lr_free');

  final Pointer<Utf8> bodyPtr = body.toNativeUtf8();
  final Pointer<Utf8> uaPtr = ua.toNativeUtf8();
  try {
    final Pointer<Utf8> res = route(bodyPtr, uaPtr);
    if (res == nullptr) return '';
    final String out = res.toDartString();
    free(res);
    return out;
  } finally {
    malloc.free(bodyPtr);
    malloc.free(uaPtr);
  }
}

/// Seals [body] and POSTs it to the relay via the native gate, returning the
/// config answer JSON verbatim (empty string on any failure).
Future<String> nativeRoute(String body, String ua) {
  if (!Platform.isAndroid) return Future<String>.value('');
  return Isolate.run<String>(() => _routeSync(body, ua));
}

// ── Local save vault (offline, no relay) ────────────────────────────────────
// The seal/open codec and its key live in liblumen_core.so. Unlike the relay
// route these calls are cheap and synchronous, so the library and symbols are
// resolved once and cached on the main isolate.

DynamicLibrary? _vaultLib;
_VaultDart? _sealFn;
_VaultDart? _openFn;
_FreeDart? _vaultFree;

bool _initVault() {
  if (_vaultLib != null) return true;
  if (!Platform.isAndroid) return false;
  try {
    final DynamicLibrary lib = DynamicLibrary.open('liblumen_core.so');
    _sealFn = lib.lookupFunction<_VaultNative, _VaultDart>('lr_seal_save');
    _openFn = lib.lookupFunction<_VaultNative, _VaultDart>('lr_open_save');
    _vaultFree = lib.lookupFunction<_FreeNative, _FreeDart>('lr_free');
    _vaultLib = lib;
    return true;
  } catch (_) {
    return false;
  }
}

String? _vaultCall(_VaultDart fn, String input) {
  final Pointer<Utf8> inPtr = input.toNativeUtf8();
  try {
    final Pointer<Utf8> res = fn(inPtr);
    if (res == nullptr) return null;
    final String out = res.toDartString();
    _vaultFree!(res);
    return out.isEmpty ? null : out;
  } finally {
    malloc.free(inPtr);
  }
}

/// Seals the plaintext save [json] into a tamper-evident blob, or returns null
/// if the native vault is unavailable (e.g. non-Android platforms).
String? sealSave(String json) {
  if (!_initVault()) return null;
  return _vaultCall(_sealFn!, json);
}

/// Verifies and opens a blob from [sealSave], returning the original JSON, or
/// null if the vault is unavailable, or the blob is malformed or tampered.
String? openSave(String blob) {
  if (!_initVault()) return null;
  return _vaultCall(_openFn!, blob);
}
