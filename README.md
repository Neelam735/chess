# ♟ Chess App — Flutter (Android & iOS) with AdMob Monetization

A complete Chess game with Google AdMob ads integrated for monetization.

---

## 🔑 FIRST: Add Your AdMob IDs

Before building, replace all placeholder IDs:

### 1. Android — `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>  ← Replace this
```

### 2. iOS — `ios/Runner/Info.plist`
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>  ← Replace this
```

### 3. Ad Unit IDs — `lib/ad_helper.dart`
Replace all 6 ad unit ID strings with your real ones from the AdMob console.

---

## 📱 Ad Placements

| Ad Type        | Where                            | Trigger                        |
|----------------|----------------------------------|--------------------------------|
| **Banner**     | Bottom of screen                 | Always visible                 |
| **Interstitial**| Full screen                     | After each game ends           |
| **Rewarded**   | 💡 Hint button (top-right)       | Player watches ad to get hint  |

> **Note:** During development (`flutter run`), test ads are shown automatically — no real AdMob IDs needed until release.

---

## 🚀 Setup & Run

```bash
flutter pub get
flutter run
```

### Build release APK (Android):
```bash
flutter build apk --release
```

### Build for iOS (Mac only):
```bash
cd ios && pod install && cd ..
flutter build ios --release
```

---

## 📂 Project Structure

```
lib/
├── main.dart                    # Entry point + AdMob init
├── ad_helper.dart               # Centralized ad unit IDs
├── chess_logic.dart             # Chess rules & move generation
├── chess_controller.dart        # Game state (ChangeNotifier)
├── chess_game.dart              # Main screen + all ad logic
└── widgets/
    ├── board_widget.dart        # Interactive chess board
    ├── banner_ad_widget.dart    # Reusable banner ad
    ├── captured_pieces.dart     # Captured pieces display
    ├── move_history.dart        # Move history in notation
    └── promotion_dialog.dart    # Pawn promotion picker
```

---

## ✅ Features
- Full chess rules (castling, en passant, promotion, check/checkmate/stalemate)
- AdMob Banner, Interstitial & Rewarded ads
- Move history in algebraic notation
- Portrait & landscape layouts
- Two-player local multiplayer

---

## ⚠️ AdMob Rules
- Never click your own ads
- Always test with test IDs during development
- Add a Privacy Policy URL to your Play Store / App Store listing
- For EU users, implement GDPR consent (UMP SDK)
