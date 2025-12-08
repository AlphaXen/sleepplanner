# Firebase Setup Guide

## Current Status
✅ App runs without Firebase  
⚠️ Firebase configuration is incomplete

## Why You See the Firebase Warning
The Android app is looking for Firebase credentials in `google_services.xml`, but they're not configured. This is **normal and safe** - the app continues to work without Firebase.

## Option 1: Continue Without Firebase (Recommended for Development)
No action needed! The app works perfectly without Firebase. Features that don't require Firebase will work fine.

## Option 2: Set Up Firebase (For Production)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a new project" or select existing
3. Name it "SleepPlanner"
4. Enable Google Analytics (optional)

### Step 2: Register Android App
1. Click "Add app" → Select "Android"
2. Package name: `com.example.my_flutter_app` (or your custom package name)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### Step 3: Update Android Build Files
Make sure `android/build.gradle` includes:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

And `android/app/build.gradle` includes:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 4: Generate values.xml
The google-services.json will auto-generate Firebase values when you run:
```bash
flutter pub get
flutter clean
flutter run
```

## Firebase Features Available
- ☁️ Cloud Firestore (for saving sleep data to cloud)
- 🔐 Firebase Authentication
- 📱 Cloud Messaging (push notifications)
- 📊 Analytics

## Disable Firebase Completely (If Not Needed)

If you don't plan to use Firebase, remove it from `pubspec.yaml`:

```yaml
# Remove these lines:
firebase_core: ^4.0.0
cloud_firestore: ^6.0.0
```

Then update `lib/main.dart` to remove Firebase code.

## Troubleshooting

### Error: "Failed to load FirebaseOptions from resource"
- **Cause**: Firebase config not found
- **Solution**: Either set up Firebase (Option 2) or remove firebase_core dependency

### Error: "FirebaseException: [core/no-app]"
- **Cause**: Firebase not initialized
- **Solution**: Ensure `_initializeFirebase()` is called in main()

### Firebase features not working
- Check Firebase project is active
- Verify credentials in google-services.json
- Check Firebase rules in Firestore console

## Current Config Location
`android/app/src/main/res/values/google_services.xml` - Placeholder file
