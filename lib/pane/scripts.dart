import 'package:webview_flutter/webview_flutter.dart';

import '../drawer/slips.dart';

// Scripts pushed into the page after each load settles. The lift script is
// what keeps a focused field above the keyboard: the window itself does not
// move, so the page shifts the field once Dart reports the occupied share.
class PageInk {
  PageInk._();

  static Future<void> installAll(WebViewController controller) async {
    for (final String body in _bodies()) {
      if (body.isEmpty) continue;
      try {
        await controller.runJavaScript(body);
      } catch (_) {}
    }
  }

  static Future<void> castShare(
    WebViewController controller,
    double share,
  ) async {
    try {
      await controller.runJavaScript(
        'window.__lrLift&&window.__lrLift(${share.toStringAsFixed(5)});',
      );
    } catch (_) {}
  }

  static List<String> _bodies() => <String>[
        pullRimScript(),
        pullLiftScript(),
        pullClipScript(),
      ];
}
