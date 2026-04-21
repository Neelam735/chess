import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // ─── Replace these with your real AdMob Ad Unit IDs ──────────────────────
  // Get them from: https://admob.google.com → Apps → Ad Units

  // static const String _bannerAndroid      = 'ca-app-pub-9434559843696647/5487563410';
  // static const String _bannerIOS          = 'ca-app-pub-9434559843696647/5487563410';
  // static const String _interstitialAndroid = 'ca-app-pub-9434559843696647/5519353009';
  // static const String _interstitialIOS    = 'ca-app-pub-9434559843696647/5519353009';
  // static const String _rewardedAndroid    = 'ca-app-pub-9434559843696647/6640862988';
  // static const String _rewardedIOS        = 'ca-app-pub-9434559843696647/6640862988';

  static const String _bannerAndroid      = 'ca-app-pub-9434559843696647/5487563410';
  static const String _bannerIOS          = 'ca-app-pub-9434559843696647/5487563410';
  static const String _interstitialAndroid = 'ca-app-pub-9434559843696647/5519353009';
  static const String _interstitialIOS    = 'ca-app-pub-9434559843696647/5519353009';
  static const String _rewardedAndroid    = 'ca-app-pub-9434559843696647/6640862988';
  static const String _rewardedIOS        = 'ca-app-pub-9434559843696647/6640862988';

  // ─── Google's official test Ad Unit IDs (safe to use during development) ──
  // Source: https://developers.google.com/admob/flutter/test-ads
  static const String _testBanner        = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial  = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded      = 'ca-app-pub-3940256099942544/5224354917';


  // ─── In debug mode, official test IDs are used automatically ─────────────
  static String get bannerAdUnitId {
    if (kDebugMode) return _testBanner;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _bannerIOS
        : _bannerAndroid;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) return _testInterstitial;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _interstitialIOS
        : _interstitialAndroid;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) return _testRewarded;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _rewardedIOS
        : _rewardedAndroid;
  }
}
