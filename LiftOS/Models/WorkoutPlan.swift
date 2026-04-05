import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var id: UUID
    var name: String
    var planDescription: String?
    var numberOfWeeks: Int
    var deloadFrequency: Int?
    var deloadPercentage: Double?
    var isActive: Bool
    var currentWeekNumber: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PlanWeek.plan)
    var weeks: [PlanWeek]

    var currentWeek: PlanWeek? {
        weeks.first { $0.weekNumber == currentWeekNumber }
    }

    init(
        name: String,
        planDescription: String? = nil,
        numberOfWeeks: Int = 4,
        deloadFrequency: Int? = 4,
        deloadPercentage: Double? = 0.6,
        isActive: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.planDescription = planDescription
        self.numberOfWeeks = numberOfWeeks
        self.deloadFrequency = deloadFrequency
        self.deloadPercentage = deloadPercentage
        self.isActive = isActive
        self.currentWeekNumber = 1
        self.createdAt = Date()
        self.weeks = []
    }
}
