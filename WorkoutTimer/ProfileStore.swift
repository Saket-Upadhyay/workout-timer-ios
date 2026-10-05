//
//  ProfileStore.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import Foundation

@MainActor
@Observable
final class ProfileStore {
    private(set) var profiles: [WorkoutProfile] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("profiles.json")
        load()
    }

    func save(name: String, exercises: [Exercise], rounds: Int = 1) {
        profiles.append(WorkoutProfile(name: name, exercises: exercises, rounds: rounds))
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            profiles.remove(at: index)
        }
        persist()
    }

    func exportData() -> Data? {
        try? JSONEncoder().encode(profiles)
    }

    /// Accepts either a JSON array of profiles or a single profile object.
    /// Returns the number of profiles actually added (duplicates by id are skipped).
    @discardableResult
    func importProfiles(from data: Data) -> Int {
        let decoder = JSONDecoder()
        let imported: [WorkoutProfile]
        if let array = try? decoder.decode([WorkoutProfile].self, from: data) {
            imported = array
        } else if let single = try? decoder.decode(WorkoutProfile.self, from: data) {
            imported = [single]
        } else {
            return 0
        }
        let existingIDs = Set(profiles.map(\.id))
        let newProfiles = imported.filter { !existingIDs.contains($0.id) }
        profiles.append(contentsOf: newProfiles)
        persist()
        return newProfiles.count
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        profiles = (try? JSONDecoder().decode([WorkoutProfile].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
