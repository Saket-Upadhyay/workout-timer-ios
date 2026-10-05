//
//  WorkoutProfile.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import Foundation

struct WorkoutProfile: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    /// Number of times to repeat the full exercise list in a row.
    var rounds: Int

    init(id: UUID = UUID(), name: String, exercises: [Exercise], rounds: Int = 1) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.rounds = rounds
    }

    enum CodingKeys: String, CodingKey {
        case id, name, exercises, rounds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        exercises = try container.decode([Exercise].self, forKey: .exercises)
        rounds = try container.decodeIfPresent(Int.self, forKey: .rounds) ?? 1
    }
}
