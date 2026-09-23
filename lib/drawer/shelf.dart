import 'package:shared_preferences/shared_preferences.dart';

import '../brand.dart';
import '../fork/mark.dart';
import 'lock.dart';

const String _prefix = 'lrn_';

class Shelf {
  Shelf({LockBox? lock}) : _lock = lock ?? const LockBox();

  static const String _path = '${_prefix}path';
  static const String _href = '${_prefix}href';
  static const String _hrefEnd = '${_prefix}href_end';
  static const String _askUntil = '${_prefix}ask_until';
  static const String _askYes = '${_prefix}ask_yes';
  static const String _askOs = '${_prefix}ask_os';
  static const String _asked = '${_prefix}asked';
  static const String _park = '${_prefix}park';

  late final SharedPreferences _prefs;
  final LockBox _lock;

  Future<void> prime() async {
    _prefs = await SharedPreferences.getInstance();
  }

  PathMark get path => PathMark.parse(_prefs.getString(_path));

  Future<void> savePath(PathMark value) => _prefs.setString(_path, value.wire);

  Future<String?> cachedDest() => _lock.read(_href);

  Future<void> cacheDest(String url, int? expiresUnix) async {
    await _lock.write(_href, url);
    final int until =
        expiresUnix ?? _now() + Brand.cachedUrlLifetimeSeconds;
    await _prefs.setInt(_hrefEnd, until);
  }

  bool get cachedDestExpired {
    final int? until = _prefs.getInt(_hrefEnd);
    if (until == null) return true;
    return _now() >= until;
  }

  bool get askGranted => _prefs.getBool(_askYes) ?? false;

  Future<void> markAskGranted(bool value) => _prefs.setBool(_askYes, value);

  bool get askBlockedByOs => _prefs.getBool(_askOs) ?? false;

  Future<void> markAskBlockedByOs() => _prefs.setBool(_askOs, true);

  bool get askConsumed => _prefs.getBool(_asked) ?? false;

  Future<void> markAskConsumed() => _prefs.setBool(_asked, true);

  Future<void> writeAskSnoozeUntil(int unixSeconds) =>
      _prefs.setInt(_askUntil, unixSeconds);

  bool get shouldAsk {
    if (askConsumed) return false;
    final int? until = _prefs.getInt(_askUntil);
    if (until == null) return true;
    return _now() >= until;
  }

  Future<void> parkUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _lock.remove(_park);
    } else {
      await _lock.write(_park, url);
    }
  }

  Future<String?> takeParkedUrl() async {
    final String? url = await _lock.read(_park);
    if (url != null) await _lock.remove(_park);
    return url;
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
