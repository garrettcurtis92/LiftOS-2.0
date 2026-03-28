import Foundation
import SwiftData

@Model
final class SessionSet {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    var rpe: Double?
    var isWarmup: Bool
    var isDropSet: Bool
    var completedAt: Date?
    var sessionExercise: SessionExercise?

    var isCompleted: Bool {
        completedAt != nil
    }

    var volume: Double {
        weight * Double(reps)
    }

    var displayString: String {
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
        return "\(weightStr) x \(reps)"
    }

    var estimatedOneRepMax: Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    init(
        setNumber: Int,
        reps: Int = 0,
        weight: Double = 0,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isDropSet: Bool = false
    ) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isDropSet = isDropSet
        self.completedAt = nil
    }
}
