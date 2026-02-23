import Foundation
import SwiftData

struct SeedData {
    static let exercises: [(name: String, category: String)] = [
        // Chest
        ("Bench Press", "Chest"),
        ("Incline DB Press", "Chest"),
        ("Cable Flyes", "Chest"),
        ("Dips", "Chest"),
        // Back
        ("Barbell Row", "Back"),
        ("Pull-ups", "Back"),
        ("Lat Pulldown", "Back"),
        ("Seated Cable Row", "Back"),
        // Legs
        ("Squat", "Legs"),
        ("Deadlift", "Legs"),
        ("Leg Press", "Legs"),
        ("Romanian Deadlift", "Legs"),
        ("Leg Curl", "Legs"),
        // Shoulders
        ("Overhead Press", "Shoulders"),
        ("Lateral Raise", "Shoulders"),
        ("Face Pull", "Shoulders"),
        // Arms
        ("Barbell Curl", "Arms"),
        ("Tricep Pushdown", "Arms"),
        ("Hammer Curl", "Arms"),
        // Core
        ("Plank", "Core"),
        ("Cable Crunch", "Core"),
        ("Hanging Leg Raise", "Core"),
    ]

    static let routines: [(name: String, exerciseNames: [String])] = [
        ("Push Day", ["Bench Press", "Incline DB Press", "Overhead Press", "Lateral Raise", "Tricep Pushdown"]),
        ("Pull Day", ["Barbell Row", "Pull-ups", "Lat Pulldown", "Face Pull", "Barbell Curl"]),
        ("Leg Day", ["Squat", "Deadlift", "Leg Press", "Romanian Deadlift", "Leg Curl"]),
    ]

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        var exerciseMap: [String: Exercise] = [:]
        for item in exercises {
            let exercise = Exercise(name: item.name, category: item.category)
            context.insert(exercise)
            exerciseMap[item.name] = exercise
        }

        for item in routines {
            let routineExercises = item.exerciseNames.compactMap { exerciseMap[$0] }
            let routine = Routine(name: item.name, exercises: routineExercises)
            context.insert(routine)
        }

        try? context.save()
    }
}
