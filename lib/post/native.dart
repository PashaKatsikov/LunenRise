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
