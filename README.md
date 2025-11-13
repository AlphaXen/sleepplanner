# SleepPlanner 💤

A Flutter app for tracking daily sleep time and helping **night-shift / rotating workers** stay healthy.

## Features

- Record sleep sessions (sleep time → wake time)
- Mark whether the sleep is after a night shift
- See today\'s total sleep time vs daily target
- Circular progress indicator for daily goal
- Simple settings for:
  - Daily sleep target hours
  - Night-shift worker mode toggle
- Health tips section for night workers

## Getting Started

### 1. Clone this repository

```bash
git clone https://github.com/thetkomaung9/sleepplanner.git
cd sleepplanner
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run
```

You can run it on:

- Android emulator / physical device
- iOS simulator / device
- Web (`flutter run -d chrome`)

## Tech Stack

- Flutter (Material 3, dark theme)
- provider (simple state management)

## Folder Structure

```text
lib/
 ├─ main.dart
 ├─ models/
 │   └─ sleep_entry.dart
 ├─ providers/
 │   └─ sleep_provider.dart
 └─ screens/
     ├─ home_screen.dart
     └─ shift_settings_screen.dart
```

## Next Steps / Ideas

- Persist data using Drift (SQLite)
- Add charts (weekly/monthly graphs)
- Integrate local notifications for bedtime reminders
- Add multi-language support (Korean, Myanmar)
- Export sleep report as PDF
