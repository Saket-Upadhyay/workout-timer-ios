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
    @State private var importResultMessage: String?

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
        .onOpenURL { url in
            handleIncomingProfile(at: url)
        }
        .alert("Import Profile", isPresented: .constant(importResultMessage != nil), presenting: importResultMessage) { _ in
            Button("OK") { importResultMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func handleIncomingProfile(at url: URL) {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            importResultMessage = "Couldn't read that file."
            return
        }

        let count = profileStore.importProfiles(from: data)
        importResultMessage = count > 0
            ? "Added \(count) profile\(count == 1 ? "" : "s")."
            : "No new profiles found in that file."

        try? FileManager.default.removeItem(at: url)
    }
}

extension WorkoutManager: Identifiable {}

#Preview {
    ContentView()
}
