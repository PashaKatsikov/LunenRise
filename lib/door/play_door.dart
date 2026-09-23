import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../game/game.dart';

/// The only door from the launch fork into the native tower.
Future<void> openTower(BuildContext context, LumenGame game) async {
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  if (!context.mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => GameHost(game: game),
      transitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (_, Animation<double> anim, _, Widget child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}
