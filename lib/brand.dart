import 'drawer/slips.dart';

// Timings and identity for the Lumen Rise launch fork.
// Endpoint, campaign key, project number and relay secret come from slips
// so they are not stored as plain string literals.

abstract final class Brand {
  static const String applicationId = 'com.lumenrise.lumenrisegame';
  static const String marketId = 'com.lumenrise.lumenrisegame';
  static const String displayName = 'Lumen Rise';

  static const String storeNumericId = '';

  /// Skip on the ask sheet hides it for a little under three days.
  static const int askSnoozeSeconds = 3 * 24 * 60 * 60 - 147;

  static const int verdictTimeoutSeconds = 6;
  static const int firstInstallAwaitSeconds = 5;
  static const int returningInstallAwaitSeconds = 3;
  static const int deepLinkAwaitSeconds = 4;
  static const int probeTimeoutSeconds = 3;
  static const int pushTokenAwaitSeconds = 5;
  static const int linkDropDebounceMs = 860;
  static const int redirectLoopRetries = 6;
  static const int cachedUrlLifetimeSeconds = 10 * 24 * 60 * 60;

  // Endpoint + relay secret moved to the native gate (liblumen_core.so); they
  // are no longer present in the Dart image.
  static String get campaignKey => pullCampaignKey();
  static String get projectNumber => pullProjectNumber();

  static String get storeId {
    if (storeNumericId.isNotEmpty) return 'id$storeNumericId';
    return marketId;
  }

  static bool get secretsReady =>
      campaignKey.isNotEmpty && projectNumber.isNotEmpty;
}
