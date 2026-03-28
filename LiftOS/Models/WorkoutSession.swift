import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var isQuickWorkout: Bool
    var notes: String?
    var routine: Routine?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise]

    var sortedExercises: [SessionExercise] {
        exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var duration: TimeInterval? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }

    var durationFormatted: String? {
        guard let duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    init(isQuickWorkout: Bool = false, routine: Routine? = nil) {
        self.id = UUID()
        self.startedAt = Date()
        self.completedAt = nil
        self.isQuickWorkout = isQuickWorkout
        self.notes = nil
        self.routine = routine
        self.exercises = []
    }
}
