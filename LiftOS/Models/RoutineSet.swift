import Foundation
import SwiftData

@Model
final class RoutineSet {
    var id: UUID
    var setNumber: Int
    var targetReps: Int
    var targetRepRangeMax: Int?
    var targetWeight: Double?
    var routineExercise: RoutineExercise?

    var repRangeDisplay: String {
        if let max = targetRepRangeMax, max != targetReps {
            return "\(targetReps)-\(max)"
        }
        return "\(targetReps)"
    }

    init(setNumber: Int, targetReps: Int, targetRepRangeMax: Int? = nil, targetWeight: Double? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.targetRepRangeMax = targetRepRangeMax
        self.targetWeight = targetWeight
    }
}
