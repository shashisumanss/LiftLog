import Foundation
import SwiftData

struct SeedData {
    static let exercises: [(name: String, category: String)] = [
        // Chest
        ("Bench Press", "Chest"),
        ("Incline DB Press", "Chest"),
        ("Cable Flyes", "Chest"),
        ("Dips", "Chest"),
        ("Decline Bench Press", "Chest"),
        ("Push-ups", "Chest"),
        ("Pec Deck", "Chest"),
        ("DB Flyes", "Chest"),
        // Back
        ("Barbell Row", "Back"),
        ("Pull-ups", "Back"),
        ("Lat Pulldown", "Back"),
        ("Seated Cable Row", "Back"),
        ("T-Bar Row", "Back"),
        ("Single-Arm DB Row", "Back"),
        ("Chin-ups", "Back"),
        ("Cable Pullover", "Back"),
        // Legs
        ("Squat", "Legs"),
        ("Deadlift", "Legs"),
        ("Leg Press", "Legs"),
        ("Romanian Deadlift", "Legs"),
        ("Leg Curl", "Legs"),
        ("Leg Extension", "Legs"),
        ("Bulgarian Split Squat", "Legs"),
        ("Hip Thrust", "Legs"),
        ("Calf Raise", "Legs"),
        ("Hack Squat", "Legs"),
        ("Goblet Squat", "Legs"),
        // Shoulders
        ("Overhead Press", "Shoulders"),
        ("Lateral Raise", "Shoulders"),
        ("Face Pull", "Shoulders"),
        ("DB Shoulder Press", "Shoulders"),
        ("Arnold Press", "Shoulders"),
        ("Rear Delt Fly", "Shoulders"),
        ("Upright Row", "Shoulders"),
        ("Shrugs", "Shoulders"),
        // Arms
        ("Barbell Curl", "Arms"),
        ("Tricep Pushdown", "Arms"),
        ("Hammer Curl", "Arms"),
        ("Preacher Curl", "Arms"),
        ("Concentration Curl", "Arms"),
        ("Skull Crushers", "Arms"),
        ("Overhead Tricep Extension", "Arms"),
        ("Cable Curl", "Arms"),
        ("Dip (Tricep)", "Arms"),
        // Core
        ("Plank", "Core"),
        ("Cable Crunch", "Core"),
        ("Hanging Leg Raise", "Core"),
        ("Ab Wheel Rollout", "Core"),
        ("Russian Twist", "Core"),
        ("Dead Bug", "Core"),
        ("Mountain Climbers", "Core"),
        // Cardio
        ("Treadmill", "Cardio"),
        ("Rowing Machine", "Cardio"),
        ("Stair Climber", "Cardio"),
        ("Jump Rope", "Cardio"),
        // Olympic
        ("Clean & Jerk", "Olympic"),
        ("Snatch", "Olympic"),
        ("Power Clean", "Olympic"),
        ("Push Press", "Olympic"),
    ]

    static let routines: [(name: String, exerciseNames: [String])] = [
        ("Push Day", ["Bench Press", "Incline DB Press", "Overhead Press", "Lateral Raise", "Tricep Pushdown"]),
        ("Pull Day", ["Barbell Row", "Pull-ups", "Lat Pulldown", "Face Pull", "Barbell Curl"]),
        ("Leg Day", ["Squat", "Deadlift", "Leg Press", "Romanian Deadlift", "Leg Curl"]),
    ]

    static func seedIfNeeded(context: ModelContext) {
        // Fetch existing exercise names to avoid duplicates
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existingExercises.map { $0.name })

        var exerciseMap: [String: Exercise] = [:]
        for ex in existingExercises {
            exerciseMap[ex.name] = ex
        }

        // Add any missing exercises
        var addedNew = false
        for item in exercises {
            if !existingNames.contains(item.name) {
                let exercise = Exercise(name: item.name, category: item.category)
                context.insert(exercise)
                exerciseMap[item.name] = exercise
                addedNew = true
            }
        }

        // Only seed routines if there are no exercises at all (fresh install)
        if existingExercises.isEmpty {
            for item in routines {
                let routineExercises = item.exerciseNames.compactMap { exerciseMap[$0] }
                let routine = Routine(name: item.name, exercises: routineExercises)
                context.insert(routine)
            }
        }

        if addedNew {
            try? context.save()
        }
    }
}
