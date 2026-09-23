import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drawer/shelf.dart';
import 'fork/decider.dart';
import 'game/game.dart';
import 'host.dart';
import 'pane/handset.dart';
import 'post/probe.dart';
import 'post/reply.dart';
import 'trail/campaign.dart';
import 'trail/chime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF14082E),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Handset.prime();

  final Shelf shelf = Shelf();
  await shelf.prime();

  final Probe probe = Probe();
  final Campaign campaign = Campaign();
  final ReplyDesk reply = ReplyDesk(shelf);
  final Chime chime = Chime(shelf);
  final Decider decider = Decider(
    shelf: shelf,
    probe: probe,
    campaign: campaign,
    reply: reply,
    chime: chime,
  );

  runApp(RiseHost(
    decider: decider,
    shelf: shelf,
    chime: chime,
    game: LumenGame(),
  ));
}
