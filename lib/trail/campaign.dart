import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../brand.dart';

class Campaign {
  Campaign();

  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _install;
  Map<String, dynamic>? _deep;
  Map<String, dynamic>? _open;

  final Completer<Map<String, dynamic>> _installReady =
      Completer<Map<String, dynamic>>();
  final Completer<void> _deepReady = Completer<void>();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final String devKey = Brand.campaignKey;
    if (devKey.isEmpty) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
      return;
    }

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: Brand.storeNumericId,
      showDebug: kDebugMode,
    );

    final AppsflyerSdk sdk = AppsflyerSdk(options);
    _sdk = sdk;

    sdk.onInstallConversionData((dynamic raw) {
      final Map<String, dynamic> payload = _unpack(raw);
      _install = payload;
      _finishInstall(payload);
    });

    sdk.onAppOpenAttribution((dynamic raw) {
      _open = _unpack(raw);
    });

    sdk.onDeepLinking((DeepLinkResult result) {
      final Map<String, dynamic>? click = result.deepLink?.clickEvent;
      if (click != null) {
        _deep = Map<String, dynamic>.from(click);
      }
      _finishDeep();
    });

    try {
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {
      _finishInstall(<String, dynamic>{});
      _finishDeep();
    }
  }

  Future<void> awaitSignals({int? installSeconds}) async {
    final int seconds = installSeconds ?? Brand.firstInstallAwaitSeconds;
    final int deepSeconds = seconds < Brand.deepLinkAwaitSeconds
        ? seconds
        : Brand.deepLinkAwaitSeconds;
    await Future.wait<void>(<Future<void>>[
      _installReady.future.timeout(
        Duration(seconds: seconds),
        onTimeout: () => <String, dynamic>{},
      ),
      _deepReady.future.timeout(
        Duration(seconds: deepSeconds),
        onTimeout: () {},
      ),
    ]);
  }

  Future<String?> deviceId() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> compose({
    required String locale,
    String? pushToken,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};

    if (_install != null) body.addAll(_install!);
    _deep?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));
    _open?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));

    body['af_id'] = await deviceId() ?? '';
    body['bundle_id'] = Brand.applicationId;
    body['os'] = 'Android';
    body['store_id'] = Brand.storeId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
      final String project = Brand.projectNumber;
      if (project.isNotEmpty) {
        body['firebase_project_id'] = project;
      }
    }

    return body;
  }

  void _finishInstall(Map<String, dynamic> data) {
    if (!_installReady.isCompleted) _installReady.complete(data);
  }

  void _finishDeep() {
    if (!_deepReady.isCompleted) _deepReady.complete();
  }

  static Map<String, dynamic> _unpack(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final dynamic inner = raw['payload'] ?? raw['data'] ?? raw;
    if (inner is Map) {
      return inner.map(
        (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
      );
    }
    return <String, dynamic>{};
  }
}
