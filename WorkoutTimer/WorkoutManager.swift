//
//  WorkoutManager.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import Foundation

enum WorkoutPhase: Equatable {
    case notStarted
    case working
    case resting
    case finished
}

@MainActor
@Observable
final class WorkoutManager {
    let exercises: [Exercise]
    let rounds: Int
    private(set) var currentExerciseIndex: Int = 0
    private(set) var currentSet: Int = 1
    private(set) var currentRound: Int = 1
    private(set) var phase: WorkoutPhase = .notStarted
    private(set) var elapsed: TimeInterval = 0
    private(set) var restRemaining: TimeInterval = 0
    /// Increments each time a rest period ends, so views can trigger a one-off flash/alert.
    private(set) var restEndTick: Int = 0

    private var phaseStartDate = Date()
    private var currentRestDuration: TimeInterval = 0
    private var advanceToNextExerciseAfterRest = false
    private var tickTask: Task<Void, Never>?

    var currentExercise: Exercise? {
        exercises.indices.contains(currentExerciseIndex) ? exercises[currentExerciseIndex] : nil
    }

    /// The exercise coming up next, only set while resting between exercises (as opposed to between sets).
    var nextExercise: Exercise? {
        guard phase == .resting, advanceToNextExerciseAfterRest else { return nil }
        let isLastExerciseInRound = currentExerciseIndex >= exercises.count - 1
        if isLastExerciseInRound {
            guard currentRound < rounds else { return nil }
            return exercises.first
        }
        let nextIndex = currentExerciseIndex + 1
        return exercises.indices.contains(nextIndex) ? exercises[nextIndex] : nil
    }

    init(exercises: [Exercise], rounds: Int = 1) {
        self.exercises = exercises
        self.rounds = max(1, rounds)
    }

    func start() {
        guard !exercises.isEmpty else { return }
        currentExerciseIndex = 0
        currentSet = 1
        currentRound = 1
        beginWorkingSet()
    }

    func finishSet() {
        guard phase == .working, let exercise = currentExercise else { return }
        let isLastSetOfExercise = currentSet >= exercise.totalSets
        let isLastExerciseInRound = currentExerciseIndex >= exercises.count - 1
        let isLastRound = currentRound >= rounds

        if isLastSetOfExercise && isLastExerciseInRound && isLastRound {
            finishWorkout()
        } else {
            advanceToNextExerciseAfterRest = isLastSetOfExercise
            let duration = isLastSetOfExercise ? exercise.restBetweenExercisesSeconds : exercise.restBetweenSetsSeconds
            beginRest(duration: duration)
        }
    }

    func skipRest() {
        guard phase == .resting else { return }
        completeRestAndAdvance()
    }

    func stop() {
        tickTask?.cancel()
        phase = .notStarted
        currentExerciseIndex = 0
        currentSet = 1
        currentRound = 1
        elapsed = 0
        restRemaining = 0
    }

    private func beginWorkingSet() {
        phase = .working
        elapsed = 0
        phaseStartDate = Date()
        startTicking()
    }

    private func beginRest(duration: TimeInterval) {
        phase = .resting
        currentRestDuration = duration
        restRemaining = duration
        phaseStartDate = Date()
        startTicking()
    }

    private func finishWorkout() {
        tickTask?.cancel()
        phase = .finished
    }

    private func completeRestAndAdvance() {
        tickTask?.cancel()
        if advanceToNextExerciseAfterRest {
            if currentExerciseIndex >= exercises.count - 1 {
                currentExerciseIndex = 0
                currentRound += 1
            } else {
                currentExerciseIndex += 1
            }
            currentSet = 1
        } else {
            currentSet += 1
        }
        advanceToNextExerciseAfterRest = false
        beginWorkingSet()
    }

    // Ticks off a stored start date rather than accumulating per-tick deltas, so the
    // displayed time stays accurate even if a tick is delayed (e.g. briefly backgrounded).
    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                self.tick()
            }
        }
    }

    private func tick() {
        let elapsedSincePhaseStart = Date().timeIntervalSince(phaseStartDate)
        switch phase {
        case .working:
            elapsed = elapsedSincePhaseStart
        case .resting:
            let remaining = currentRestDuration - elapsedSincePhaseStart
            if remaining <= 0 {
                restRemaining = 0
                restEndTick += 1
                RestAlert.playRestEndAlert()
                completeRestAndAdvance()
            } else {
                restRemaining = remaining
            }
        case .notStarted, .finished:
            break
        }
    }
}
