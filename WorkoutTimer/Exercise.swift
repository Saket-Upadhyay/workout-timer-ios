//
//  Exercise.swift
//  WorkoutTimer
//
//  Created by Saket Upadhyay on 05/10/26.
//

import Foundation

struct Exercise: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var totalSets: Int
    /// Rest taken between consecutive sets of this exercise.
    var restBetweenSetsSeconds: TimeInterval
    /// Rest taken after this exercise's last set, before the next exercise begins.
    var restBetweenExercisesSeconds: TimeInterval

    init(
        id: UUID = UUID(),
        name: String,
        totalSets: Int = 3,
        restBetweenSetsSeconds: TimeInterval = 60,
        restBetweenExercisesSeconds: TimeInterval = 90
    ) {
        self.id = id
        self.name = name
        self.totalSets = totalSets
        self.restBetweenSetsSeconds = restBetweenSetsSeconds
        self.restBetweenExercisesSeconds = restBetweenExercisesSeconds
    }
}
