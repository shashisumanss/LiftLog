import Foundation
import SwiftData

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isWarmup: Bool
    var workoutEntry: WorkoutEntry?

    init(setNumber: Int, weight: Double, reps: Int, isWarmup: Bool = false) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
    }
}
