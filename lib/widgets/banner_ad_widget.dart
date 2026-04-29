import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_helper.dart';
import '../billing_service.dart';
import '../consent_manager.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _isPremium => BillingService.instance.isPremium.value;

  @override
  void initState() {
    super.initState();
    BillingService.instance.isPremium.addListener(_onPremiumChanged);
    if (!_isPremium) _loadAd();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    if (_isPremium) {
      _bannerAd?.dispose();
      _bannerAd = null;
      setState(() => _isLoaded = false);
    } else if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!ConsentManager.adsAvailable) return;
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted || _isPremium) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null) {
      return Container(
        height: 50,
        color: const Color(0xFF0D0D0D),
      );
    }
    return Container(
      color: const Color(0xFF0D0D0D),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    BillingService.instance.isPremium.removeListener(_onPremiumChanged);
    _bannerAd?.dispose();
    super.dispose();
  }
}
