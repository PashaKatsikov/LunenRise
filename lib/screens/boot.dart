import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/art.dart';
import '../game/game.dart';
import '../game/paths.dart';
import '../ui/c.dart';

class BootScreen extends StatefulWidget {
  final LumenGame game;
  const BootScreen({super.key, required this.game});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  double _p = 0;
  String _phase = 'Warming the lamps…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    setState(() => _phase = 'Binding the tower…');
    await widget.game.boot();
    setState(() => _phase = 'Hanging the bells…');
    await Art.load((p) {
      if (mounted) setState(() => _p = p);
    });
    widget.game.load = 1;
    setState(() {
      _p = 1;
      _phase = 'Ready';
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (mounted) {
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (!mounted) return;
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          break;
        }
      }
    }
    if (mounted) widget.game.finishBoot();
  }

  @override
  Widget build(BuildContext context) {
    final land = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: C.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              land ? Paths.loadH : Paths.loadV,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.82),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LOADING',
                    style: T.title.copyWith(
                      fontSize: 16,
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: _p.clamp(0.02, 1),
                        backgroundColor: const Color(0xAA0A1028),
                        color: C.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _phase,
                    style: T.mute.copyWith(
                      shadows: const [Shadow(blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
