import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../brand.dart';

const List<String> _probeHosts = <String>[
  'www.cloudflare.com',
  'dns.quad9.net',
];

const Set<ConnectivityResult> _live = <ConnectivityResult>{
  ConnectivityResult.wifi,
  ConnectivityResult.mobile,
  ConnectivityResult.ethernet,
  ConnectivityResult.vpn,
  ConnectivityResult.bluetooth,
  ConnectivityResult.other,
};

class Probe {
  Probe({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  int _rotor = 0;

  Future<bool> hasAdapter() async {
    try {
      final List<ConnectivityResult> states =
          await _connectivity.checkConnectivity();
      return states.any(_live.contains);
    } catch (_) {
      return false;
    }
  }

  Future<bool> canReach() async {
    if (!await hasAdapter()) return false;
    final Duration timeout = Duration(seconds: Brand.probeTimeoutSeconds);
    for (var i = 0; i < _probeHosts.length; i++) {
      final String host = _probeHosts[(_rotor + i) % _probeHosts.length];
      try {
        final List<InternetAddress> answer =
            await InternetAddress.lookup(host).timeout(timeout);
        if (answer.any((InternetAddress a) => a.rawAddress.isNotEmpty)) {
          _rotor = (_rotor + 1) % _probeHosts.length;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}
