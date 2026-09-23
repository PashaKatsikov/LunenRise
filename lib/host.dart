import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand.dart';
import 'drawer/shelf.dart';
import 'fork/decider.dart';
import 'game/game.dart';
import 'loom/ramp.dart';
import 'trail/chime.dart';

class RiseHost extends StatefulWidget {
  const RiseHost({
    super.key,
    required this.decider,
    required this.shelf,
    required this.chime,
    required this.game,
  });

  final Decider decider;
  final Shelf shelf;
  final Chime chime;
  final LumenGame game;

  @override
  State<RiseHost> createState() => _RiseHostState();
}

class _RiseHostState extends State<RiseHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.displayName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14082E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF6C445),
          surface: Color(0xFF14082E),
        ),
      ),
      home: Ramp(
        decider: widget.decider,
        shelf: widget.shelf,
        chime: widget.chime,
        game: widget.game,
      ),
    );
  }
}
