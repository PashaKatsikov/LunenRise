import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../game/game.dart';
import '../ui/c.dart';

class WebScreen extends StatefulWidget {
  final LumenGame game;
  const WebScreen({super.key, required this.game});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _c;
  double _p = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final g = widget.game;
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(g.webWhiten ? Colors.white : const Color(0xFF0B1233))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (v) {
            if (mounted) setState(() => _p = v / 100);
          },
          onPageFinished: (url) async {
            if (g.webWhiten) {
              try {
                await _c.runJavaScript('''
              (function(){
                var old = document.getElementById('lr-white');
                if (old) old.remove();
                var s = document.createElement('style');
                s.id = 'lr-white';
                s.textContent = 'html,body,#__next,main,.container,.content,.wrapper,#app,#root{background:#ffffff !important;color:#111111 !important;} a{color:#0B57D0 !important;}';
                document.documentElement.style.backgroundColor = '#ffffff';
                if (document.body) {
                  document.body.style.backgroundColor = '#ffffff';
                  document.body.style.color = '#111111';
                }
                if (document.head) document.head.appendChild(s);
              })();
            ''');
              } catch (_) {}
            }
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _ready = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(g.webUrl));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Scaffold(
      backgroundColor: g.webWhiten ? Colors.white : C.navy,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: g.back,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: g.webWhiten ? const Color(0xFFE8EEF8) : C.chip,
                        border: Border.all(color: C.line),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: g.webWhiten ? C.navy : C.text,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    g.webTitle,
                    style: T.title.copyWith(
                      fontSize: 16,
                      color: g.webWhiten ? C.navy : C.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_ready)
            LinearProgressIndicator(
              value: _p == 0 ? null : _p,
              minHeight: 3,
              color: C.gold,
              backgroundColor: const Color(0x22000000),
            ),
          Expanded(child: WebViewWidget(controller: _c)),
        ],
      ),
    );
  }
}
