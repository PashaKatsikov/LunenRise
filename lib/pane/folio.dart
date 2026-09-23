import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../brand.dart';
import '../drawer/shelf.dart';
import '../loom/hush.dart';
import '../pane/handset.dart';
import '../pane/lip.dart';
import '../pane/scripts.dart';
import '../post/probe.dart';
import '../trail/chime.dart';

class FolioView extends StatefulWidget {
  const FolioView({
    super.key,
    required this.url,
    required this.shelf,
    required this.chime,
  });

  final String url;
  final Shelf shelf;
  final Chime chime;

  @override
  State<FolioView> createState() => _FolioViewState();
}

class _FolioViewState extends State<FolioView> with WidgetsBindingObserver {
  late final WebViewController _web;
  final Lip _lip = Lip();
  bool _spinner = true;
  bool _offlineShown = false;
  String? _lastMainFrame;
  int _retryCounter = 0;
  Timer? _dropDebounce;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Size? _lastPhysical;

  static const MethodChannel _uploadChannel = MethodChannel('lr.pick/files');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _enterImmersive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCutout();
      WidgetsBinding.instance.addPostFrameCallback((_) => _readCutout());
    });
    _buildController();

    widget.chime.onIncomingUrl = (String url) {
      if (mounted) _web.loadRequest(Uri.parse(url));
    };

    _connSub = Probe().changes.listen((List<ConnectivityResult> r) {
      final bool allNone = r.isNotEmpty &&
          r.every((ConnectivityResult e) => e == ConnectivityResult.none);
      if (!allNone) {
        _dropDebounce?.cancel();
        return;
      }
      _dropDebounce?.cancel();
      _dropDebounce = Timer(
        Duration(milliseconds: Brand.linkDropDebounceMs),
        _showOffline,
      );
    });
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _enterImmersive();
  }

  @override
  void didChangeMetrics() {
    _readCutout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readCutout();
    });

    final FlutterView? view = _view();
    if (view == null) return;
    _lip.measure(view);

    final Size current = view.physicalSize;
    final Size? previous = _lastPhysical;
    _lastPhysical = current;
    if (previous == null) return;
    if ((previous.width > previous.height) ==
        (current.width > current.height)) {
      return;
    }
    _enterImmersive();
  }

  FlutterView? _view() {
    if (mounted) {
      final FlutterView? local = View.maybeOf(context);
      if (local != null) return local;
    }
    final Iterable<FlutterView> views =
        WidgetsBinding.instance.platformDispatcher.views;
    return views.isEmpty ? null : views.first;
  }

  Future<void> _readCutout() async {
    final FlutterView? view = _view();
    if (view == null) return;
    await _lip.readCutout(view.devicePixelRatio);
    if (!mounted) return;
    _lip.measure(view);
  }

  void _buildController() {
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(Handset.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _spinner = true);
        },
        onPageFinished: (_) async {
          if (mounted) setState(() => _spinner = false);
          _retryCounter = 0;
          await PageInk.installAll(_web);
          if (_lip.share > 0) await _lip.cast();
        },
        onWebResourceError: _onError,
        onNavigationRequest: _onNavigate,
      ));

    _lip.bind(_web);
    _configureAndroid();
    _web.loadRequest(Uri.parse(widget.url));
  }

  void _onError(WebResourceError err) {
    if (err.isForMainFrame != true) return;

    final String desc = err.description.toLowerCase();
    final bool isLoop = desc.contains('too_many_redirects') ||
        desc.contains('too many redirects') ||
        err.errorCode == -1007 ||
        err.errorCode == -9;

    if (isLoop &&
        _lastMainFrame != null &&
        _retryCounter < Brand.redirectLoopRetries) {
      _retryCounter++;
      _web.loadRequest(Uri.parse(_lastMainFrame!));
      return;
    }

    if (mounted) setState(() => _spinner = true);

    final bool isConnectivity = desc.contains('name_not_resolved') ||
        desc.contains('err_name_not_resolved') ||
        desc.contains('internet_disconnected') ||
        desc.contains('network_changed') ||
        err.errorCode == -105 ||
        err.errorCode == -106 ||
        err.errorCode == -21;

    if (isConnectivity) {
      _showOffline();
    } else {
      _guardOffline();
    }
  }

  NavigationDecision _onNavigate(NavigationRequest req) {
    final Uri? uri = Uri.tryParse(req.url);
    if (uri == null) return NavigationDecision.prevent;
    const Set<String> inApp = <String>{
      'http',
      'https',
      'about',
      'data',
      'blob',
    };
    if (inApp.contains(uri.scheme)) {
      if (req.isMainFrame) _lastMainFrame = req.url;
      return NavigationDecision.navigate;
    }
    _openExternally(uri);
    return NavigationDecision.prevent;
  }

  void _configureAndroid() {
    if (_web.platform is! AndroidWebViewController) return;
    final AndroidWebViewController controller =
        _web.platform as AndroidWebViewController;

    controller.setMediaPlaybackRequiresUserGesture(false);
    controller.setOnPlatformPermissionRequest(
      (PlatformWebViewPermissionRequest r) => r.grant(),
    );
    controller.setOnShowFileSelector(_pickFiles);

    final AndroidWebViewCookieManager cookies = AndroidWebViewCookieManager(
      AndroidWebViewCookieManagerCreationParams
          .fromPlatformWebViewCookieManagerCreationParams(
        const PlatformWebViewCookieManagerCreationParams(),
      ),
    );
    cookies.setAcceptThirdPartyCookies(controller, true);
  }

  Future<List<String>> _pickFiles(FileSelectorParams params) async {
    try {
      final List<Object?>? picked =
          await _uploadChannel.invokeMethod<List<Object?>>(
        'grab',
        <String, Object>{
          'multi': params.mode == FileSelectorMode.openMultiple,
          'mimes': params.acceptTypes
              .where((String t) => t.trim().isNotEmpty)
              .toList(),
        },
      );
      if (picked == null) return const <String>[];
      return picked.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _openExternally(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _guardOffline() async {
    if (_offlineShown) return;
    final bool online = await Probe().canReach();
    if (online) return;
    _showOffline();
  }

  void _showOffline() {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    final String current = _lastMainFrame ?? widget.url;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HushView(
          onRetryBuild: (_) => FolioView(
            url: current,
            shelf: widget.shelf,
            chime: widget.chime,
          ),
        ),
      ),
    );
  }

  Future<void> _stepBack() async {
    if (await _web.canGoBack()) await _web.goBack();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropDebounce?.cancel();
    _connSub?.cancel();
    _lip.dispose();
    widget.chime.onIncomingUrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool landscape = mq.orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) await _stepBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: ValueListenableBuilder<EdgeInsets>(
          valueListenable: _lip.cutout,
          builder: (BuildContext context, EdgeInsets cutout, Widget? _) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Padding(
                  padding: cutout,
                  child: MediaQuery(
                    data: mq.removeViewInsets(removeBottom: true).copyWith(
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: WebViewWidget(controller: _web),
                  ),
                ),
                if (_spinner && !landscape)
                  const ColoredBox(
                    color: Color(0xCC14082E),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFF6C445)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
