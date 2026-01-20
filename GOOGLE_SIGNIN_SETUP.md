# Google Sign-In Setup Guide

## Current Issue
Google Sign-In requires SHA-1 fingerprint configuration in Firebase Console.

## Steps to Fix Google Sign-In:

### 1. Get SHA-1 Fingerprint
Run this command in your project root:
```bash
cd android
./gradlew signingReport
```

Or on Windows:
```cmd
cd android
gradlew signingReport
```

Look for the SHA1 fingerprint under "Variant: debug" section.

### 2. Add SHA-1 to Firebase Console
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: "my-app-11ae0"
3. Go to Project Settings (gear icon)
4. Select "Your apps" tab
5. Find your Android app (my_App.com)
6. Click "Add fingerprint"
7. Paste the SHA1 fingerprint from step 1
8. Save

### 3. Enable Google Sign-In
1. In Firebase Console, go to Authentication
2. Click "Sign-in method" tab
3. Enable "Google" provider
4. Add your email as authorized domain if needed
5. Save

### 4. Download Updated google-services.json
1. After adding SHA-1, download the updated google-services.json
2. Replace the existing file in android/app/google-services.json

### 5. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Use Firebase CLI
```bash
firebase login
firebase projects:list
firebase use my-app-11ae0
```

## Test Google Sign-In
After setup, the Google Sign-In button should work properly in the auth screen.