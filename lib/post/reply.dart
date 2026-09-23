import 'dart:convert';

import '../brand.dart';
import '../drawer/shelf.dart';
import '../fork/mark.dart';
import 'courier.dart';
import 'packet.dart';

class ReplyDesk {
  ReplyDesk(this._shelf);

  final Shelf _shelf;

  Future<Verdict> ask(Map<String, dynamic> body) async {
    final String endpoint = Brand.syncUrl;
    final String secret = Brand.relaySecret;
    if (endpoint.isEmpty || secret.isEmpty) {
      return Verdict.no('endpoint_missing');
    }

    try {
      final Map<String, dynamic> envelope = Packet.seal(body, secret);
      final dynamic response = await courier.postJson(
        Uri.parse(endpoint),
        jsonEncode(envelope),
      );

      if (response.statusCode != 200) {
        return Verdict.no('http_${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.data as String);
      if (decoded is! Map) return Verdict.no('malformed');
      final Verdict verdict =
          Verdict.fromJson(Map<String, dynamic>.from(decoded));
      if (verdict.hasDest) {
        await _shelf.cacheDest(verdict.dest!, verdict.until);
      }
      return verdict;
    } catch (e) {
      return Verdict.no('network:$e');
    }
  }
}
