//
//  ActiveWorkoutView.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import SwiftUI

struct ActiveWorkoutView: View {
    let manager: WorkoutManager
    var onFinish: () -> Void

    @State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                if manager.phase == .finished {
                    completedView
                } else if let exercise = manager.currentExercise {
                    Text(exercise.name)
                        .font(.largeTitle.bold())

                    Text("Set \(manager.currentSet) of \(exercise.totalSets)")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if manager.rounds > 1 {
                        Text("Round \(manager.currentRound) of \(manager.rounds)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    timerView

                    Spacer()

                    controls(exercise: exercise)
                }
            }
            .padding()

            Color.green
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onChange(of: manager.restEndTick) { _, _ in
            withAnimation(.easeOut(duration: 0.15)) { flashOpacity = 0.35 }
            withAnimation(.easeIn(duration: 0.5).delay(0.15)) { flashOpacity = 0 }
        }
        .onAppear { manager.start() }
    }

    private var timerView: some View {
        VStack(spacing: 8) {
            Text(manager.phase == .resting ? "REST" : "WORK")
                .font(.headline)
                .foregroundStyle(manager.phase == .resting ? .orange : .green)

            Text(formattedTime(manager.phase == .resting ? manager.restRemaining : manager.elapsed))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(manager.phase == .resting ? .orange : .primary)

            if let nextExercise = manager.nextExercise {
                Text("Next: \(nextExercise.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func controls(exercise: Exercise) -> some View {
        switch manager.phase {
        case .working:
            Button("Done Set") {
                manager.finishSet()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        case .resting:
            Button("Skip Rest") {
                manager.skipRest()
            }
            .buttonStyle(.bordered)
            .controlSize(.extraLarge)
        case .notStarted, .finished:
            EmptyView()
        }
    }

    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.title.bold())
            Spacer()
            Button("Done") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded())
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

#Preview {
    ActiveWorkoutView(
        manager: WorkoutManager(exercises: [
            Exercise(name: "Push-ups", totalSets: 3, restBetweenSetsSeconds: 60, restBetweenExercisesSeconds: 90)
        ]),
        onFinish: {}
    )
}
