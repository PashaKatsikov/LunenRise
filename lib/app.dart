import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game/game.dart';
import 'screens/boot.dart';
import 'screens/menu.dart';
import 'screens/settings.dart';
import 'screens/tower.dart';
import 'screens/web.dart';
import 'ui/c.dart';

class LumenApp extends StatelessWidget {
  final LumenGame game;
  const LumenApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumen Rise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.navy,
        colorScheme: const ColorScheme.dark(primary: C.gold, surface: C.navy),
        sliderTheme: const SliderThemeData(activeTrackColor: C.gold),
      ),
      home: GameHost(game: game),
    );
  }
}

class GameHost extends StatefulWidget {
  final LumenGame game;
  const GameHost({super.key, required this.game});

  @override
  State<GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<GameHost>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  LumenGame get g => widget.game;
  Ticker? _tick;
  Duration _last = Duration.zero;
  bool _fg = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    g.addListener(_on);
    _tick = createTicker(_sim)..start();
  }

  @override
  void dispose() {
    _tick?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    g.removeListener(_on);
    super.dispose();
  }

  void _sim(Duration t) {
    if (!_fg || g.view == UiView.boot || g.view == UiView.web) {
      _last = t;
      return;
    }
    var dt = (_last == Duration.zero)
        ? 0.016
        : (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (dt > 0.05) dt = 0.05;
    g.step(dt);
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _fg = false;
      g.persist();
    } else if (state == AppLifecycleState.resumed) {
      _fg = true;
      _last = Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (did) return;
        if (g.view == UiView.menu && g.sheet == SheetKind.none) {
          SystemNavigator.pop();
          return;
        }
        g.back();
      },
      child: _page(),
    );
  }

  Widget _page() {
    switch (g.view) {
      case UiView.boot:
        return BootScreen(game: g);
      case UiView.menu:
        return MenuScreen(game: g);
      case UiView.tower:
        return TowerScreen(game: g);
      case UiView.settings:
        return SettingsScreen(game: g);
      case UiView.web:
        return WebScreen(game: g);
    }
  }
}

Future<void> bootChrome() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
}
