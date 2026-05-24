# 🚨 S.O.S Panic Button — Flutter App

An offline emergency app for mountain climbers, hikers, and general outdoor survival.  
100% Offline · GPS · Compass · SMS · Flash Strobe · Siren · AI (Optional)

---

## 📁 Project Structure

```
sos_flutter/
├── lib/
│   ├── core/
│   │   ├── theme/          → AppColors, AppTheme
│   │   ├── constants/      → (additional: emergency numbers, etc.)
│   │   └── utils/          → (additional: formatters, validators)
│   ├── data/
│   │   ├── models/         → EmergencyContact, ActivityLog (Hive)
│   │   ├── repositories/   → GpsRepository, CompassRepository, SmsRepository
│   │   └── datasources/    → GeminiService (Google AI Studio)
│   ├── domain/
│   │   ├── entities/       → (additional: pure entities for Clean Architecture)
│   │   └── usecases/       → (additional: ActivateSOS, SendSmsUseCase, etc.)
│   └── presentation/
│       ├── screens/        → SosScreen, CompassScreen
│       ├── widgets/        → (additional: reusable widgets)
│       └── providers/      → SosProvider, ActivityLogProvider
├── android/
│   └── app/src/main/AndroidManifest.xml  → Permissions & configuration
├── assets/
│   ├── audio/siren.mp3    → [Add yourself: siren audio file]
│   └── data/              → [Add: offline survival tips JSON]
└── pubspec.yaml           → Dependencies configuration
```

---

## 🚀 Setup & Run

### 1. Prerequisites
```bash
flutter --version  # >= 3.19.0
dart --version     # >= 3.3.0
```

### 2. Install dependencies
```bash
cd SOS
flutter pub get
```

### 3. Generate Hive adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
> This generates the code files: `emergency_contact.g.dart` and `activity_log.g.dart`

### 4. Add Audio Asset
Place an audio file named `siren.mp3` in the `assets/audio/` directory.  
You can download one for free from freesound.org (CC0 license) — search for "emergency siren".

### 5. Configure Google AI Studio (Optional)
```dart
// In main.dart or settings screen:
final gemini = ref.read(geminiServiceProvider);
gemini.init('YOUR_GEMINI_API_KEY');
```
Get a free API key at: https://aistudio.google.com

### 6. Run on Android
```bash
flutter run -d android
# or build the release APK:
flutter build apk --release
```

### 7. Run on iOS
```bash
# Add to ios/Runner/Info.plist:
# NSLocationWhenInUseUsageDescription
# NSLocationAlwaysUsageDescription  
# NSSensorUsageDescription (for compass)

flutter run -d ios
```

---

## 📱 Permissions (Android)

All required permissions are already configured in the `AndroidManifest.xml` file:

| Permission | Purpose |
|-----------|---------|
| `ACCESS_FINE_LOCATION` | High-precision GPS |
| `SEND_SMS` | Send emergency SMS messages in the background |
| `CAMERA` | Access LED torch for Morse code SOS strobe |
| `VIBRATE` | Haptic feedback for SOS interactions |
| `FOREGROUND_SERVICE` | Keeps GPS active when the app is in the background |
| `INTERNET` | Gemini AI integration (optional) |

---

## 🧠 Google AI Studio — System Prompt

Copy & paste these instructions to Google AI Studio → System Instructions:
```
You are an emergency survival assistant named SIGMA (Mobile Emergency Information System).
Assist the user in outdoor emergency situations with guidance on:
- Basic first aid
- Navigation and orientation
- Survival techniques
- Emergency communication

RULES:
- ALWAYS answer in English
- Short, clear, and actionable (maximum 5 points)
- Prioritize human life and safety above all else
- If the situation is critical, always suggest calling emergency services (911, 112) or Search & Rescue
- Never suggest actions that worsen the condition
```

Recommended Model: **gemini-2.0-flash** (lightweight, ultra-fast)

---

## 🗺️ Roadmap

- [x] SOS Button + Countdown anti-mispress protection
- [x] Real-time GPS Tracking
- [x] Emergency SMS containing exact coordinates  
- [x] Digital Compass (Magnetometer)
- [x] Morse Code SOS LED Strobe Light
- [x] Loud Emergency Siren Audio
- [x] Google AI Studio / Gemini Integration
- [x] Contacts Management Screen (UI)
- [x] Activity Log Screen (UI)
- [x] Offline Reverse Geocoding (Global Prominent Peaks Database)
- [x] Background GPS Foreground Service
- [x] Google Play Store Submission Configuration

---

## ⚠️ Important Considerations

- **SMS**: Requires GSM network signal (does not need internet). It works even at 0 bars of data as long as there is basic GSM coverage.
- **GPS**: Works completely offline. GPS lock is faster and more precise in open areas.
- **Compass**: Calibrate by waving the phone in a figure-8 motion in the air. Keep it away from metal items and powerbanks.
- **AI Integration**: Requires an internet connection. The offline mode operates using local cached survival tips.

---

## 📞 Emergency Contacts (Indonesia & Global)

| Number | Service |
|-------|---------|
| **112** | National Emergency (all-in-one) / Universal European |
| **911** | Universal US/Global Emergency |
| **115** | Basarnas / Search & Rescue (SAR) |
| **119** | Ambulance |
| **113** | Fire Department |
| **110** | Police |
