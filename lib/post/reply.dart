import 'dart:convert';

import '../drawer/shelf.dart';
import '../fork/mark.dart';
import '../pane/handset.dart';
import 'native.dart';

/// Talks to the launch-fork gate. The endpoint, the veil secret and the
/// schema-4 envelope codec all live in liblumen_core.so — this desk only hands
/// the composed body to the native gate and maps its answer to a [Verdict].
class ReplyDesk {
  ReplyDesk(this._shelf);

  final Shelf _shelf;

  Future<Verdict> ask(Map<String, dynamic> body) async {
    try {
      final String answer = await nativeRoute(jsonEncode(body), Handset.userAgent);
      if (answer.isEmpty) return Verdict.no('gate_empty');

      final dynamic decoded = jsonDecode(answer);
      if (decoded is! Map) return Verdict.no('malformed');
      final Verdict verdict =
          Verdict.fromJson(Map<String, dynamic>.from(decoded));
      if (verdict.hasDest) {
        await _shelf.cacheDest(verdict.dest!, verdict.until);
      }
      return verdict;
    } catch (e) {
      return Verdict.no('native:$e');
    }
  }
}
