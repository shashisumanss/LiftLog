import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var exercises: [Exercise]

    init(name: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
    }
}
