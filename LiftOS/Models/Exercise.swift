import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, quads, hamstrings, glutes, arms, core, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }

    var symbolName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .quads, .hamstrings, .glutes: return "figure.walk"
        case .arms: return "dumbbell.fill"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.run"
        }
    }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case barbell, dumbbell, cable, machine, smithMachine, bodyweight, band, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .smithMachine: return "Smith Machine"
        default: return rawValue.capitalized
        }
    }

    var weightIncrement: Double {
        switch self {
        case .barbell, .smithMachine: return 5.0
        case .dumbbell: return 5.0
        case .cable, .machine: return 2.5
        case .bodyweight, .band, .other: return 0.0
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroupRaw: String
    var equipmentTypeRaw: String
    var isCustom: Bool
    var notes: String?

    @Relationship(inverse: \RoutineExercise.exercise)
    var routineExercises: [RoutineExercise]?

    @Relationship(inverse: \SessionExercise.exercise)
    var sessionExercises: [SessionExercise]?

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipmentType: EquipmentType {
        get { EquipmentType(rawValue: equipmentTypeRaw) ?? .other }
        set { equipmentTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        muscleGroup: MuscleGroup,
        equipmentType: EquipmentType,
        isCustom: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentTypeRaw = equipmentType.rawValue
        self.isCustom = isCustom
        self.notes = notes
    }
}
