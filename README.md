<p align="center">
  <img src="WorkoutTimer/Assets.xcassets/AppIcon.appiconset/icon-light.png" width="128" alt="WorkoutTimer icon">
</p>

<h1 align="center">WorkoutTimer</h1>

<p align="center">A simple iOS app for timing sets and rest periods during a workout.</p>

## Features

- **Build a workout** – add exercises with a set count, rest between sets, and rest between exercises.
- **Rounds** – repeat the full exercise list up to 10 times.
- **Active timer** – tap *Done Set* to start the rest countdown; *Skip Rest* to move on early. Shows the next exercise during rests and alerts when rest ends.
- **Profiles** – save workouts and reload them later.
- **Import / export** – share profiles as JSON backup files.

## Requirements

- Xcode with the iOS 27.0 SDK
- Swift 5, SwiftUI

## Build & Run

```sh
open WorkoutTimer.xcodeproj
```

Select the `WorkoutTimer` scheme and a simulator or device, then press **Run** (⌘R).

## Project Layout

| File | Purpose |
| --- | --- |
| `WorkoutManager.swift` | Workout state machine and timer |
| `ExerciseSetupView.swift` | Exercise list and editor |
| `ActiveWorkoutView.swift` | Live workout screen |
| `ProfileStore.swift`, `ProfileListView.swift` | Saved profiles |
| `ProfileBackupDocument.swift` | JSON import/export |
