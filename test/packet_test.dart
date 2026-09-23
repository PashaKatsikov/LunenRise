import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumenrise/post/packet.dart';

void main() {
  test('envelope uses the lumen field names', () {
    final Map<String, dynamic> sealed = Packet.seal(
      <String, dynamic>{'bundle_id': 'com.lumenrise.lumenrisegame', 'os': 'Android'},
      'sample-secret',
    );
    expect(sealed['leaf'], 4);
    expect(sealed['salt'], isA<String>());
    expect(sealed['body'], isA<String>());
    expect(sealed['mac'], isA<String>());
    expect((sealed['mac'] as String).length, 24);
    expect(base64Decode(sealed['salt'] as String).length, 12);
    expect(sealed.containsKey('a'), isFalse);
    expect(sealed.containsKey('m'), isFalse);
  });
}
