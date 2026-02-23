import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var isCustom: Bool

    @Relationship(deleteRule: .nullify, inverse: \Routine.exercises)
    var routines: [Routine]

    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.exercise)
    var entries: [WorkoutEntry]

    init(name: String, category: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isCustom = isCustom
        self.routines = []
        self.entries = []
    }
}
