[![iOS CI](https://github.com/Saket-Upadhyay/workout-timer-ios/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/Saket-Upadhyay/workout-timer-ios/actions/workflows/ios.yml)

![WorkoutTimer icon](docs/icon.png)

# WorkoutTimer

A simple iOS app for timing sets and rest periods during a workout.

## Features

- **Build a workout** – add exercises with a set count, rest between sets, and rest between exercises.
- **Rounds** – repeat the full exercise list up to 10 times.
- **Active timer** – tap *Done Set* to start the rest countdown; *Skip Rest* to move on early. Shows the next exercise during rests and alerts when rest ends.
- **Profiles** – save workouts and reload them later.
- **Import/export** – share profiles as JSON backup files.

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
