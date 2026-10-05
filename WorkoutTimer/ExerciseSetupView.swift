//
//  ExerciseSetupView.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import SwiftUI

struct ExerciseSetupView: View {
    @Binding var exercises: [Exercise]
    @Binding var rounds: Int
    let profileStore: ProfileStore
    var onStart: () -> Void

    @State private var isAddingExercise = false
    @State private var isShowingProfiles = false
    @State private var isShowingSaveProfileAlert = false
    @State private var newProfileName = ""
    @State private var editingExercise: Exercise?

    var body: some View {
        VStack(spacing: 0) {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Yet",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Add an exercise to build your workout.")
                )
                .frame(maxHeight: .infinity)
            } else {
                Stepper("Rounds: \(rounds)", value: $rounds, in: 1...10)
                    .padding()
                List {
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.totalSets) sets · \(Int(exercise.restBetweenSetsSeconds))s between sets · \(Int(exercise.restBetweenExercisesSeconds))s after exercise")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingExercise = exercise
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { exercises.remove(atOffsets: $0) }
                }
            }

            Button {
                onStart()
            } label: {
                Text("Start Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(exercises.isEmpty)
            .padding()
        }
        .navigationTitle("Workout")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingProfiles = true
                } label: {
                    Label("Profiles", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingSaveProfileAlert = true
                } label: {
                    Label("Save Profile", systemImage: "square.and.arrow.down")
                }
                .disabled(exercises.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            ExerciseFormView { exercise in
                exercises.append(exercise)
            }
        }
        .sheet(item: $editingExercise) { exercise in
            ExerciseFormView(exercise: exercise) { updated in
                if let index = exercises.firstIndex(where: { $0.id == updated.id }) {
                    exercises[index] = updated
                }
            }
        }
        .sheet(isPresented: $isShowingProfiles) {
            ProfileListView(store: profileStore) { profile in
                exercises = profile.exercises
                rounds = profile.rounds
            }
        }
        .alert("Save Profile", isPresented: $isShowingSaveProfileAlert) {
            TextField("Profile Name", text: $newProfileName)
            Button("Cancel", role: .cancel) {
                newProfileName = ""
            }
            Button("Save") {
                profileStore.save(name: newProfileName, exercises: exercises, rounds: rounds)
                newProfileName = ""
            }
            .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Save this workout sequence so you can load it again later.")
        }
    }
}

private struct ExerciseFormView: View {
    var exercise: Exercise?
    var onSave: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var totalSets: Int
    @State private var restBetweenSetsSeconds: Double
    @State private var restBetweenExercisesSeconds: Double

    init(exercise: Exercise? = nil, onSave: @escaping (Exercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        _name = State(initialValue: exercise?.name ?? "")
        _totalSets = State(initialValue: exercise?.totalSets ?? 3)
        _restBetweenSetsSeconds = State(initialValue: exercise?.restBetweenSetsSeconds ?? 60)
        _restBetweenExercisesSeconds = State(initialValue: exercise?.restBetweenExercisesSeconds ?? 90)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name (e.g. Push-ups)", text: $name)
                }
                Section("Sets") {
                    Stepper("\(totalSets) sets", value: $totalSets, in: 1...10)
                }
                Section("Rest Between Sets") {
                    Slider(value: $restBetweenSetsSeconds, in: 30...180, step: 5) {
                        Text("Rest Between Sets")
                    }
                    Text("\(Int(restBetweenSetsSeconds))s")
                        .foregroundStyle(.secondary)
                }
                Section("Rest Between Exercises") {
                    Slider(value: $restBetweenExercisesSeconds, in: 30...300, step: 5) {
                        Text("Rest Between Exercises")
                    }
                    Text("\(Int(restBetweenExercisesSeconds))s")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(exercise == nil ? "Add Exercise" : "Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(exercise == nil ? "Add" : "Save") {
                        onSave(Exercise(
                            id: exercise?.id ?? UUID(),
                            name: name,
                            totalSets: totalSets,
                            restBetweenSetsSeconds: restBetweenSetsSeconds,
                            restBetweenExercisesSeconds: restBetweenExercisesSeconds
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseSetupView(
            exercises: .constant([
                Exercise(name: "Push-ups", totalSets: 3, restBetweenSetsSeconds: 60, restBetweenExercisesSeconds: 90),
                Exercise(name: "Pull-ups", totalSets: 3, restBetweenSetsSeconds: 90, restBetweenExercisesSeconds: 120)
            ]),
            rounds: .constant(1),
            profileStore: ProfileStore(),
            onStart: {}
        )
    }
}
