import 'package:flutter/widgets.dart';

import 'app.dart';
import 'game/game.dart';

Future<void> main() async {
  await bootChrome();
  runApp(LumenApp(game: LumenGame()));
}
