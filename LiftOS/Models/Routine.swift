import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var dayOfWeek: Int?
    var sortOrder: Int
    var week: PlanWeek?

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise]

    @Relationship(inverse: \WorkoutSession.routine)
    var sessions: [WorkoutSession]?

    var sortedExercises: [RoutineExercise] {
        exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var dayName: String? {
        guard let dayOfWeek else { return nil }
        let formatter = DateFormatter()
        guard dayOfWeek >= 1, dayOfWeek <= 7 else { return nil }
        return formatter.weekdaySymbols[dayOfWeek - 1]
    }

    init(name: String, dayOfWeek: Int? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.dayOfWeek = dayOfWeek
        self.sortOrder = sortOrder
        self.exercises = []
    }
}
