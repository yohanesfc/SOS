# Google Play Store Submission Guide 🚀

This document provides a step-by-step production guide to compile, sign, and submit the **S.O.S Panic Button** application to the Google Play Store.

---

## 🔑 Phase 1: Generate a Release Keystore

To sign the app for production, you need an upload keystore. Run the following command in your terminal or command prompt:

### Windows (PowerShell/CMD):
```powershell
keytool -genkey -v -keystore c:\Users\Yohanes\Project\SOS\android\app\upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### macOS / Linux:
```bash
keytool -genkey -v -keystore ./android/app/upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> [!WARNING]
> Keep the generated keystore file (`upload-keystore.jks`) safe! If you lose this key, you will not be able to push updates to your existing Play Store listing.

---

## ⚙️ Phase 2: Configure Signing Properties Locally

Create a new file named `key.properties` in the `android/` directory (e.g. `c:\Users\Yohanes\Project\SOS\android\key.properties`). 

Add the following credentials to it:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

> [!IMPORTANT]
> The `android/app/build.gradle.kts` file is already pre-configured to automatically load these properties when building for production. If `key.properties` does not exist, it will automatically fallback to debug keys to prevent local run errors.
> Never commit `key.properties` or `.jks` files to version control! They are already added to your `.gitignore`.

---

## 📦 Phase 3: Build the Android App Bundle (AAB)

Run the following command in the root folder of the project to generate the production-ready Android App Bundle (AAB):

```bash
flutter build appbundle --release
```

Once the compilation completes, the signed AAB file will be generated at:
📂 `build/app/outputs/bundle/release/app-release.aab`

---

## 🏢 Phase 4: Google Play Console Submission Steps

### 1. Create a Developer Account
Sign in or register at the [Google Play Console](https://play.google.com/console) (requires a one-time $25 USD developer fee).

### 2. Create a New App
1. Click **Create app** in the top right corner.
2. Enter the app details:
   - **App Name**: `SOS Panic Button`
   - **Default Language**: `English (United States)`
   - **App or Game**: `App`
   - **Free or Paid**: `Free`
3. Accept the developer declarations and click **Create app**.

### 3. Set Up Your Store Listing (Checklist)
Navigate to **Grow** ➔ **Store presence** ➔ **Main store listing** in the side menu:
- [ ] **Short Description** (Max 80 characters):
  *e.g. Offline SOS emergency panic button with GPS, compass, siren, and AI survival guides.*
- [ ] **Full Description** (Max 4000 characters):
  *Provide a comprehensive explanation of offline SMS dispatch, GPS accuracy indicator, morse code light strobe, siren volume, and the fully offline AI assistant.*
- [ ] **App Icon**: 512x512 pixels (PNG format, max 1MB).
- [ ] **Feature Graphic**: 1024x500 pixels (JPG or PNG, max 1MB).
- [ ] **Phone Screenshots**: Upload 2 to 8 screenshots showcasing:
  * 1. The main big red SOS active button.
  * 2. The GPS coordinate status locking.
  * 3. The Digital Compass view with lock bearing.
  * 4. The offline AI Emergency assistant screen.

### 4. Provide App Content Declarations
Complete the **App content** section (under Policy and programs in the side menu):
- [ ] **Privacy Policy**: Required for apps requesting location permissions (`ACCESS_FINE_LOCATION`). Create a basic hosting page (e.g. GitHub Pages) and input the URL.
- [ ] **Permissions Declaration**: Declare that the app uses location and background services for the core feature of safety tracking during emergency SOS active status.

### 5. Roll Out to Production
1. Navigate to **Release** ➔ **Production** in the side menu.
2. Click **Create new release**.
3. Upload the generated signed AAB file (`app-release.aab`).
4. Enter release notes (e.g. *Initial release with offline geocoding, Morse strobe light, and background GPS location tracking*).
5. Click **Next** ➔ **Save and publish** to send it for Google Play's policy review!
