import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'billing_service.dart';
import 'consent_manager.dart';
import 'entitlement_service.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gather GDPR/EU consent before touching the ads SDK.
  // canRequest will be false for EEA users who decline consent.
  final canRequest = await ConsentManager.gatherConsent();
  if (canRequest) {
    await MobileAds.instance.initialize();
    ConsentManager.adsAvailable = true;
  }

  unawaited(BillingService.instance.init());
  unawaited(EntitlementService.instance.init());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A96E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
