import Foundation
import SwiftData

@Model
final class PlanWeek {
    var id: UUID
    var weekNumber: Int
    var isDeloadWeek: Bool
    var plan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \Routine.week)
    var routines: [Routine]

    var sortedRoutines: [Routine] {
        routines.sorted { $0.sortOrder < $1.sortOrder }
    }

    init(weekNumber: Int, isDeloadWeek: Bool = false) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.isDeloadWeek = isDeloadWeek
        self.routines = []
    }
}
