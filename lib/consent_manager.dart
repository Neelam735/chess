import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages GDPR/EU consent via the Google UMP SDK.
///
/// Call [gatherConsent] at startup before initializing MobileAds.
/// Check [adsAvailable] to decide whether to show ads.
class ConsentManager {
  /// True once MobileAds has been initialised with valid consent.
  static bool adsAvailable = false;

  /// Requests consent-info update and, if the UMP form is required, shows it.
  /// Returns true when the app is allowed to request ads.
  static Future<bool> gatherConsent() async {
    final completer = Completer<bool>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // Consent info updated successfully.
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadAndShowFormIfRequired(completer);
        } else {
          completer.complete(
            await ConsentInformation.instance.canRequestAds(),
          );
        }
      },
      (FormError error) {
        // On failure allow ads so non-EU users are not affected.
        debugPrint('UMP consent info update failed: ${error.message}');
        completer.complete(true);
      },
    );

    return completer.future;
  }

  static void _loadAndShowFormIfRequired(Completer<bool> completer) {
    ConsentForm.loadConsentForm(
      (ConsentForm form) async {
        final status =
            await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          form.show((FormError? error) async {
            if (error != null) {
              debugPrint('UMP form dismissed with error: ${error.message}');
            }
            completer.complete(
              await ConsentInformation.instance.canRequestAds(),
            );
          });
        } else {
          completer.complete(
            await ConsentInformation.instance.canRequestAds(),
          );
        }
      },
      (FormError error) {
        debugPrint('UMP consent form load failed: ${error.message}');
        completer.complete(true);
      },
    );
  }
}
