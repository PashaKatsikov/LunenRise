import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'scripts.dart';

/// Keyboard and cutout readings for the sheet.
///
/// The window stays still when the IME opens, so the keyboard only appears
/// as a view inset. That inset becomes a 0..1 share of the visible span and
/// is handed to the page. The hardware cutout is read on `lr.rim/edge`
/// because the page is given a zeroed MediaQuery.
class Lip {
  static const MethodChannel _channel = MethodChannel('lr.rim/edge');

  final ValueNotifier<EdgeInsets> cutout =
      ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  WebViewController? _web;
  bool _gone = false;
  double _insetLogical = 0;
  double _spanPx = -1;
  double _share = 0;

  double get share => _share;

  void bind(WebViewController controller) {
    _web = controller;
  }

  void measure(FlutterView view) {
    if (_gone) return;
    final double ratio = view.devicePixelRatio;
    if (ratio <= 0) return;

    final EdgeInsets rim = cutout.value;
    final double span =
        view.physicalSize.height - (rim.top + rim.bottom) * ratio;
    if (span <= 0) return;

    final double inset = view.viewInsets.bottom / ratio;
    final bool insetMoved = (inset - _insetLogical).abs() >= 1;
    final bool spanMoved = (span - _spanPx).abs() >= 1;
    if (!insetMoved && !spanMoved) return;

    _insetLogical = inset;
    _spanPx = span;

    final double next = (inset * ratio / span).clamp(0.0, 1.0);
    if ((next - _share).abs() < 0.0001) return;
    _share = next;
    unawaited(cast());
  }

  Future<void> cast() async {
    final WebViewController? web = _web;
    if (web == null || _gone) return;
    await PageInk.castShare(web, _share);
  }

  Future<void> readCutout(double ratio) async {
    if (_gone || ratio <= 0) return;
    try {
      final Object? raw = await _channel.invokeMethod<Object>('read');
      if (_gone || raw is! Map) return;

      double edge(Object? value) {
        final double px = (value as num?)?.toDouble() ?? 0;
        return px <= 0 ? 0 : px / ratio;
      }

      final EdgeInsets next = EdgeInsets.fromLTRB(
        edge(raw['west']),
        edge(raw['north']),
        edge(raw['east']),
        edge(raw['south']),
      );
      if (next != cutout.value) cutout.value = next;
    } catch (_) {}
  }

  void dispose() {
    _gone = true;
    _web = null;
    cutout.dispose();
  }
}
