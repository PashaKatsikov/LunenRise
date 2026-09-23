import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../brand.dart';
import '../drawer/shelf.dart';
import '../post/courier.dart';

const String chimeChannelId = 'tower_chime_v1';
const String chimeChannelName = 'Tower Chime';
const String _smallIcon = '@drawable/ic_notification';

@pragma('vm:entry-point')
Future<void> towerBackgroundMessage(RemoteMessage message) async {}

class Chime {
  Chime(this._shelf);

  final Shelf _shelf;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  String? _token;
  Future<String?>? _tokenJob;
  bool _ready = false;

  void Function(String url)? onIncomingUrl;
  void Function(String token)? onTokenChanged;

  String? get token => _token;

  /// Wires messaging and starts the token fetch without waiting, so the
  /// token round-trip overlaps attribution instead of blocking it.
  Future<void> boot() async {
    if (!_ready) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _messaging = FirebaseMessaging.instance;
        FirebaseMessaging.onBackgroundMessage(towerBackgroundMessage);
        await _setupLocal();

        final RemoteMessage? initial = await _messaging!.getInitialMessage();
        if (initial != null) {
          await _onColdTap(initial);
        } else {
          await _shelf.parkUrl(null);
        }

        FirebaseMessaging.onMessage.listen(_onForeground);
        FirebaseMessaging.onMessageOpenedApp.listen(_onWarmTap);
        _messaging!.onTokenRefresh.listen((String t) {
          _token = t;
          onTokenChanged?.call(t);
        });
        _ready = true;
      } catch (_) {}
    }
    if (_ready && (_token == null || _token!.isEmpty)) {
      _tokenJob ??= _fetchToken();
    }
  }

  Future<String?> awaitToken() => _tokenJob ?? Future<String?>.value(_token);

  Future<String?> _fetchToken() async {
    try {
      final String? fresh = await _messaging?.getToken().timeout(
            Duration(seconds: Brand.pushTokenAwaitSeconds),
          );
      if (fresh != null && fresh.isNotEmpty) _token = fresh;
    } catch (_) {
    } finally {
      _tokenJob = null;
    }
    return _token;
  }

  Future<void> _setupLocal() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings(_smallIcon);

    await _local.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final String? payload = r.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final Map<String, dynamic> data =
              jsonDecode(payload) as Map<String, dynamic>;
          final String? url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onIncomingUrl?.call(url);
        } catch (_) {}
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        chimeChannelId,
        chimeChannelName,
        description: 'Notes from the tower terrace',
        importance: Importance.high,
      ),
    );
  }

  Future<bool> askPermission() async {
    FirebaseMessaging? messaging = _messaging;
    if (messaging == null) {
      try {
        if (Firebase.apps.isEmpty) await Firebase.initializeApp();
        messaging = FirebaseMessaging.instance;
        _messaging = messaging;
      } catch (_) {}
    }
    if (messaging == null) return false;

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final AuthorizationStatus status = settings.authorizationStatus;
    final bool granted = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    await _shelf.markAskGranted(granted);
    if (status == AuthorizationStatus.denied) {
      await _shelf.markAskBlockedByOs();
    }
    if (granted) {
      try {
        final String? fresh =
            await messaging.getToken().timeout(const Duration(seconds: 6));
        if (fresh != null && fresh.isNotEmpty) {
          _token = fresh;
          onTokenChanged?.call(fresh);
        }
      } catch (_) {}
    }
    return granted;
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final RemoteNotification? n = message.notification;
    if (n == null) return;

    AndroidNotificationDetails? details;
    final String? imageUrl = n.android?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final List<int>? bytes = await courier.getBytes(imageUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          chimeChannelId,
          chimeChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: _smallIcon,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(Uint8List.fromList(bytes)),
            largeIcon: const DrawableResourceAndroidBitmap(_smallIcon),
          ),
        );
      }
    }

    details ??= const AndroidNotificationDetails(
      chimeChannelId,
      chimeChannelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
    );

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(android: details),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  Future<void> _onColdTap(RemoteMessage message) async {
    final String? url = message.data['url'] as String?;
    await _shelf.parkUrl(url != null && url.isNotEmpty ? url : null);
  }

  void _onWarmTap(RemoteMessage message) {
    final String? url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) onIncomingUrl?.call(url);
  }
}
