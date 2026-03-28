import Foundation
import SwiftData

enum WeightUnit: String, Codable, CaseIterable {
    case lbs, kg

    var displayName: String {
        rawValue
    }

    var conversionToKg: Double {
        switch self {
        case .lbs: return 0.453592
        case .kg: return 1.0
        }
    }
}

@Model
final class UserProfile {
    var id: UUID
    var appleUserID: String?
    var displayName: String?
    var weightUnitRaw: String
    var defaultRestSeconds: Int
    var createdAt: Date

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .lbs }
        set { weightUnitRaw = newValue.rawValue }
    }

    init(
        appleUserID: String? = nil,
        displayName: String? = nil,
        weightUnit: WeightUnit = .lbs,
        defaultRestSeconds: Int = 120
    ) {
        self.id = UUID()
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.weightUnitRaw = weightUnit.rawValue
        self.defaultRestSeconds = defaultRestSeconds
        self.createdAt = Date()
    }
}
