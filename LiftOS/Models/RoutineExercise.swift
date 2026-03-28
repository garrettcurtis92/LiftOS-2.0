import Foundation
import SwiftData

@Model
final class RoutineExercise {
    var id: UUID
    var sortOrder: Int
    var restSeconds: Int?
    var notes: String?
    var routine: Routine?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \RoutineSet.routineExercise)
    var sets: [RoutineSet]

    var sortedSets: [RoutineSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    init(sortOrder: Int, restSeconds: Int? = 120, notes: String? = nil) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.restSeconds = restSeconds
        self.notes = notes
        self.sets = []
    }
}
