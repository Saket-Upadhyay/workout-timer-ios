//
//  ContentView.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var exercises: [Exercise] = []
    @State private var rounds = 1
    @State private var activeManager: WorkoutManager?
    @State private var profileStore = ProfileStore()

    var body: some View {
        NavigationStack {
            ExerciseSetupView(exercises: $exercises, rounds: $rounds, profileStore: profileStore) {
                activeManager = WorkoutManager(exercises: exercises, rounds: rounds)
            }
        }
        .fullScreenCover(item: $activeManager) { manager in
            ActiveWorkoutView(manager: manager) {
                activeManager = nil
            }
        }
    }
}

extension WorkoutManager: Identifiable {}

#Preview {
    ContentView()
}
