import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../door/play_door.dart';
import '../drawer/shelf.dart';
import '../fork/decider.dart';
import '../fork/mark.dart';
import '../game/art.dart';
import '../game/game.dart';
import '../game/paths.dart';
import '../loom/ask_sheet.dart';
import '../loom/hush.dart';
import '../pane/folio.dart';
import '../post/probe.dart';
import '../trail/chime.dart';

class Ramp extends StatefulWidget {
  const Ramp({
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
  State<Ramp> createState() => _RampState();
}

class _RampState extends State<Ramp> {
  static const int _sweepMillis = 1800;
  static const Duration _beat = Duration(milliseconds: 16);
  static const double _creepPerBeat = 0.005;
  static const Duration _fullHold = Duration(milliseconds: 150);

  static const double _decisionTo = 0.60;
  static const double _decisionCap = 0.57;
  static const double _prepTo = 0.68;
  static const double _assetsTo = 0.95;

  double _floor = 0;
  double _cap = 0;
  double _shown = 0;
  Timer? _ticker;
  bool _loading = false;
  String? _err;

  double _atlasShare = 0;
  bool _assetPhase = false;

  void _reach(double floor, {required double cap}) {
    if (floor > _floor) _floor = floor;
    if (cap > _cap) _cap = cap;
  }

  void _onAtlas(double share) {
    _atlasShare = share;
    if (_assetPhase) _aimAtlas();
  }

  void _aimAtlas() => _reach(
        _prepTo + _atlasShare * (_assetsTo - _prepTo),
        cap: _assetsTo,
      );

  void _startBar() {
    final double step = _beat.inMilliseconds / _sweepMillis;
    _ticker = Timer.periodic(_beat, (_) {
      if (!mounted) return;
      double next;
      if (_shown < _floor) {
        next = _shown + step;
        if (next > _floor) next = _floor;
      } else if (_shown < _cap) {
        double creep = (_cap - _shown) * _creepPerBeat;
        if (creep > step) creep = step;
        next = _shown + creep;
      } else {
        return;
      }
      setState(() => _shown = next);
    });
  }

  Future<void> _finishBar() async {
    _reach(1, cap: 1);
    int guard = _sweepMillis ~/ _beat.inMilliseconds + 60;
    while (mounted && _shown < 1 - 0.001 && guard > 0) {
      guard--;
      await Future<void>.delayed(_beat);
    }
    if (!mounted) return;
    _ticker?.cancel();
    setState(() => _shown = 1);
    await Future<void>.delayed(_fullHold);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.shelf.path != PathMark.table) {
        if (!await Probe().hasAdapter()) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => HushView(onRetryBuild: _retryBoot),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() => _loading = true);
      _reach(0.04, cap: _decisionCap);
      _startBar();

      Future<void>? preload;
      if (widget.shelf.path == PathMark.table) {
        preload = Art.load(_onAtlas);
      }

      final Arrival arrival = await widget.decider.decide(
        onProgress: (double v) => _reach(v * _decisionTo, cap: _decisionCap),
      );
      if (!mounted) return;
      _reach(_decisionTo, cap: _decisionTo);

      if (arrival is! TableArrival && preload != null) {
        unawaited(preload.then((_) => Art.drop(), onError: (_, _) {}));
      }

      if (arrival is HushArrival) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => HushView(onRetryBuild: _retryBoot),
          ),
        );
        return;
      }

      if (arrival is SheetArrival) {
        final String url = arrival.url;
        await _finishBar();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => _sheet(url)),
        );
        return;
      }

      _reach(_decisionTo, cap: _prepTo);
      await widget.game.boot();
      if (!mounted) return;
      widget.game.sfx.volume = widget.game.sound;
      widget.game.sfx.haptics = widget.game.haptics;
      await widget.game.sfx.prime();
      if (!mounted) return;
      _reach(_prepTo, cap: _assetsTo);

      _assetPhase = true;
      _aimAtlas();
      await (preload ?? Art.load(_onAtlas));
      if (!mounted) return;
      _reach(_assetsTo, cap: _assetsTo);

      await _finishBar();
      if (!mounted) return;

      widget.game.finishBoot();
      if (!mounted) return;
      await openTower(context, widget.game);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  Widget _sheet(String url) {
    if (widget.shelf.shouldAsk) {
      return AskSheet(
        shelf: widget.shelf,
        chime: widget.chime,
        destinationUrl: url,
      );
    }
    return FolioView(url: url, shelf: widget.shelf, chime: widget.chime);
  }

  Widget _retryBoot(BuildContext _) => Ramp(
        decider: widget.decider,
        shelf: widget.shelf,
        chime: widget.chime,
        game: widget.game,
      );

  @override
  Widget build(BuildContext context) {
    final bool tall = MediaQuery.orientationOf(context) == Orientation.portrait;
    final String asset = tall ? Paths.loadV : Paths.loadH;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          if (_err != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 28),
                child: Text(
                  _err!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF8A9A),
                    decoration: TextDecoration.none,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else if (_loading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 0, 44, 30),
                child: _Readout(value: _shown.clamp(0, 1)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final int pct = (value * 100).round().clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
            height: 1,
            decoration: TextDecoration.none,
            shadows: <Shadow>[
              Shadow(color: Color(0xE6000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 16,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xCC14082E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF6C445), width: 1.2),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: box.maxWidth * value.clamp(0.03, 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1C2), Color(0xFFF6C445), Color(0xFFE08A12)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
