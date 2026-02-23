import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var exerciseOrder: [UUID]  // Stores exercise IDs in order

    @Relationship
    var exercises: [Exercise]

    init(name: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.exerciseOrder = exercises.map { $0.id }
    }

    /// Returns exercises sorted by the saved order
    var orderedExercises: [Exercise] {
        let lookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        // Return exercises in saved order, falling back to any unordered ones at the end
        var result: [Exercise] = []
        for id in exerciseOrder {
            if let ex = lookup[id] {
                result.append(ex)
            }
        }
        // Append any exercises not yet in the order list
        let orderedSet = Set(exerciseOrder)
        for ex in exercises where !orderedSet.contains(ex.id) {
            result.append(ex)
        }
        return result
    }

    /// Updates the exercise list and saves the order
    func setExercises(_ newExercises: [Exercise]) {
        exercises = newExercises
        exerciseOrder = newExercises.map { $0.id }
    }
}
