import Foundation
import SwiftData

@Model
final class SessionExercise {
    var id: UUID
    var sortOrder: Int
    var notes: String?
    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sets: [SessionSet]

    var sortedSets: [SessionSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var completedSets: [SessionSet] {
        sets.filter { $0.completedAt != nil }
    }

    var topSet: SessionSet? {
        completedSets
            .filter { !$0.isWarmup }
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }

    init(sortOrder: Int, notes: String? = nil) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.notes = notes
        self.sets = []
    }

    /// Applies a SwiftUI `.onMove` operation to a list of session exercises and reindexes
    /// `sortOrder` to match the new positions.
    static func reorder(_ exercises: [SessionExercise], from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }
        var reordered = exercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in reordered.enumerated() {
            exercise.sortOrder = index
        }
    }
}
