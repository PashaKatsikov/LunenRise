import 'package:flutter/material.dart';

import '../brand.dart';
import '../drawer/shelf.dart';
import '../pane/folio.dart';
import '../trail/chime.dart';
import 'hush.dart';

class AskSheet extends StatefulWidget {
  const AskSheet({
    super.key,
    required this.shelf,
    required this.chime,
    required this.destinationUrl,
  });

  final Shelf shelf;
  final Chime chime;
  final String destinationUrl;

  @override
  State<AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<AskSheet> {
  Future<void> _accept() async {
    await widget.chime.askPermission();
    await widget.shelf.markAskConsumed();
    if (mounted) _forward();
  }

  Future<void> _skip() async {
    await widget.shelf.writeAskSnoozeUntil(_snoozeTarget());
    if (mounted) _forward();
  }

  int _snoozeTarget() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + Brand.askSnoozeSeconds;

  void _forward() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FolioView(
          url: widget.destinationUrl,
          shelf: widget.shelf,
          chime: widget.chime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF14082E),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF3A1D6E),
              Color(0xFF14082E),
              Color(0xFF081018),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: landscape ? 40 : 28,
            vertical: 24,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 52,
                  color: Color(0xFFF6C445),
                ),
                SizedBox(height: landscape ? 16 : 24),
                Text(
                  'ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF7F3FF),
                    fontSize: landscape ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Stay tuned for special offers and rewards',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC9B7E8),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: landscape ? 24 : 36),
                landscape ? _wide(size) : _tall(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tall(Size size) {
    final double width = (size.width * 0.66).clamp(220.0, 380.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LoomButton(label: 'Allow', width: width, onTap: _accept),
        const SizedBox(height: 14),
        LoomButton(label: 'Not now', width: width, quiet: true, onTap: _skip),
      ],
    );
  }

  Widget _wide(Size size) {
    final double width = (size.width * 0.28).clamp(180.0, 320.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        LoomButton(label: 'Allow', width: width, compact: true, onTap: _accept),
        const SizedBox(width: 18),
        LoomButton(
          label: 'Not now',
          width: width,
          compact: true,
          quiet: true,
          onTap: _skip,
        ),
      ],
    );
  }
}
