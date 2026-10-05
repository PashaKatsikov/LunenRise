import 'dart:async';
import 'dart:io';

import '../brand.dart';
import '../drawer/shelf.dart';
import '../fork/mark.dart';
import '../post/probe.dart';
import '../post/reply.dart';
import '../trail/campaign.dart';
import '../trail/chime.dart';

class Decider {
  Decider({
    required this.shelf,
    required this.probe,
    required this.campaign,
    required this.reply,
    required this.chime,
  });

  final Shelf shelf;
  final Probe probe;
  final Campaign campaign;
  final ReplyDesk reply;
  final Chime chime;

  Future<Arrival>? _flight;

  Future<Arrival> decide({void Function(double)? onProgress}) {
    return _flight ??= _run(onProgress ?? (_) {}).whenComplete(() {
      _flight = null;
    });
  }

  Future<Arrival> _run(void Function(double) onProgress) async {
    if (!Brand.secretsReady) {
      onProgress(0.12);
      return const TableArrival();
    }

    chime.onTokenChanged = _resendOnToken;

    try {
      await chime.boot();
    } catch (_) {}

    final String? cold = await _takeCold();
    if (cold != null && cold.isNotEmpty) {
      await shelf.savePath(PathMark.sheet);
      unawaited(_background());
      onProgress(1);
      return SheetArrival(cold, fromCold: true);
    }

    onProgress(0.18);
    return switch (shelf.path) {
      PathMark.open => _first(onProgress),
      PathMark.sheet => _backToSheet(onProgress),
      PathMark.table => _backToTable(onProgress),
    };
  }

  Future<String?> _takeCold() async {
    final String? parked = await shelf.takeParkedUrl();
    if (parked == null) return null;
    final String trimmed = parked.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<Arrival> _first(void Function(double) onProgress) async {
    if (!await probe.hasAdapter()) {
      return const HushArrival(backToTable: false);
    }
    onProgress(0.34);
    if (!await probe.canReach()) {
      return const HushArrival(backToTable: false);
    }
    onProgress(0.55);
    await campaign.start();
    await campaign.awaitSignals(installSeconds: Brand.firstInstallAwaitSeconds);
    onProgress(0.8);
    final Verdict answer = await _ask();
    onProgress(1);
    if (answer.hasDest) {
      await shelf.savePath(PathMark.sheet);
      return SheetArrival(answer.dest!);
    }
    await shelf.savePath(PathMark.table);
    return const TableArrival();
  }

  Future<Arrival> _backToSheet(void Function(double) onProgress) async {
    if (!await probe.hasAdapter()) {
      return const HushArrival(backToTable: false);
    }
    final String? pending = await shelf.takeParkedUrl();
    if (pending != null && pending.isNotEmpty) {
      onProgress(1);
      return SheetArrival(pending);
    }
    final String? cached = await shelf.cachedDest();
    if (cached != null && !shelf.cachedDestExpired) {
      onProgress(1);
      return SheetArrival(cached);
    }

    await campaign.start();
    if (!await probe.canReach()) {
      if (cached != null) return SheetArrival(cached);
      return const HushArrival(backToTable: false);
    }
    onProgress(0.62);
    await campaign.awaitSignals(
      installSeconds: Brand.returningInstallAwaitSeconds,
    );
    final Verdict answer = await _ask();
    onProgress(1);
    if (answer.hasDest) return SheetArrival(answer.dest!);
    if (cached != null) return SheetArrival(cached);
    return const HushArrival(backToTable: false);
  }

  Future<Arrival> _backToTable(void Function(double) onProgress) async {
    if (!await probe.hasAdapter()) {
      onProgress(1);
      return const TableArrival();
    }
    await campaign.start();
    if (!await probe.canReach()) {
      onProgress(1);
      return const TableArrival();
    }
    onProgress(0.5);
    await campaign.awaitSignals(
      installSeconds: Brand.returningInstallAwaitSeconds,
    );
    final Verdict answer = await _ask();
    onProgress(1);
    if (!answer.hasDest) return const TableArrival();
    await shelf.savePath(PathMark.sheet);
    return SheetArrival(answer.dest!);
  }

  Future<Verdict> _ask({String? token}) async {
    // Never post before AppsFlyer's conversion callback has fired: an early
    // body has no af_status (config → 404 → native) and carries an af_id the
    // AppsFlyer backend hasn't registered yet. Both cause the install's status
    // to flip within a single session, so hold the request until attribution
    // is real.
    if (!campaign.hasInstall) {
      return Verdict.no('attribution-pending');
    }
    final String? pushToken = token ?? await chime.awaitToken();
    final Map<String, dynamic> body = await campaign.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: pushToken,
    );
    return reply.ask(body);
  }

  Future<void> _background() async {
    try {
      await campaign.start();
      await campaign.awaitSignals(
        installSeconds: Brand.returningInstallAwaitSeconds,
      );
      await _ask();
    } catch (_) {}
  }

  Future<void> _resendOnToken(String token) async {
    try {
      // A refreshed FCM token can arrive within a second or two — before the
      // main launch flow has run campaign.start()/awaitSignals(). Wait for
      // attribution here too, so the resend never posts ahead of the
      // conversion callback (empty af_status + unregistered af_id).
      await campaign.start();
      await campaign.awaitSignals(
        installSeconds: Brand.returningInstallAwaitSeconds,
      );
      await _ask(token: token);
    } catch (_) {}
  }
}
