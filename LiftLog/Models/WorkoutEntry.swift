import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise?
    var date: Date

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workoutEntry)
    var sets: [SetEntry]

    init(exercise: Exercise, date: Date = .now) {
        self.id = UUID()
        self.exercise = exercise
        self.date = date
        self.sets = []
    }

    var sortedSets: [SetEntry] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }
}
