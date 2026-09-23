import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

// Opaque POST body for /edge/sync. Schema 4, keys leaf / salt / body / mac.
//
//   raw    = utf8(compact json)
//   nonce  = 12 random bytes
//   stream = HMAC_SHA256(secret, "lr-ks-v1" + nonce + counter_le32), counter 0,1,2…
//   enc    = raw XOR stream
//   salt   = standard base64(nonce) with padding
//   body   = standard base64(enc) with padding
//   mac    = hex( HMAC_SHA256(secret, "lr-mac-v1" + nonce + enc)[:12] )

abstract final class Packet {
  static const int schemaRev = 4;
  static const int _nonceLen = 12;
  static const int _tagLen = 12;

  static final Random _rng = Random.secure();

  static Map<String, dynamic> seal(Map<String, dynamic> body, String secret) {
    final Uint8List secretBytes = Uint8List.fromList(utf8.encode(secret));
    final Uint8List raw = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    final Uint8List nonce = _nonce(_nonceLen);
    final Uint8List stream = _keystream(secretBytes, nonce, raw.length);

    final Uint8List enc = Uint8List(raw.length);
    for (int i = 0; i < raw.length; i++) {
      enc[i] = raw[i] ^ stream[i];
    }

    return <String, dynamic>{
      'leaf': schemaRev,
      'salt': base64Encode(nonce),
      'body': base64Encode(enc),
      'mac': _tag(secretBytes, nonce, enc),
    };
  }

  static Uint8List _keystream(Uint8List secret, Uint8List nonce, int length) {
    final BytesBuilder out = BytesBuilder(copy: false);
    var counter = 0;
    while (out.length < length) {
      final Uint8List msg = Uint8List(8 + nonce.length + 4);
      msg.setRange(0, 8, utf8.encode('lr-ks-v1'));
      msg.setRange(8, 8 + nonce.length, nonce);
      final ByteData ctr = ByteData(4)..setUint32(0, counter, Endian.little);
      msg.setRange(8 + nonce.length, msg.length, ctr.buffer.asUint8List());
      out.add(_hmac(secret, msg));
      counter++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  static String _tag(Uint8List secret, Uint8List nonce, Uint8List enc) {
    final List<int> prefix = utf8.encode('lr-mac-v1');
    final Uint8List msg = Uint8List(prefix.length + nonce.length + enc.length);
    msg.setRange(0, prefix.length, prefix);
    msg.setRange(prefix.length, prefix.length + nonce.length, nonce);
    msg.setRange(prefix.length + nonce.length, msg.length, enc);
    final Uint8List digest = _hmac(secret, msg);
    return _hex(Uint8List.sublistView(digest, 0, _tagLen));
  }

  static Uint8List _hmac(Uint8List key, Uint8List message) {
    final HMac mac = HMac(SHA256Digest(), 64)
      ..init(KeyParameter(key));
    return mac.process(message);
  }

  static Uint8List _nonce(int n) {
    final Uint8List b = Uint8List(n);
    for (var i = 0; i < n; i++) {
      b[i] = _rng.nextInt(256);
    }
    return b;
  }

  static String _hex(Uint8List bytes) {
    final StringBuffer sb = StringBuffer();
    for (final int b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
