import Foundation
import SwiftData

struct SeedDataService {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Exercise>()
        descriptor.fetchLimit = 1
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            seedExercises(context: context)
        }
    }

    @MainActor
    private static func seedExercises(context: ModelContext) {
        for exercise in loadExercisesFromBundle() {
            context.insert(exercise)
        }
    }

    private static func loadExercisesFromBundle() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SeedEntry].self, from: data) else {
            return []
        }

        return entries.compactMap { entry in
            guard let group = MuscleGroup(rawValue: entry.muscleGroup),
                  let equip = EquipmentType(rawValue: entry.equipmentType) else {
                return nil
            }
            return Exercise(name: entry.name, muscleGroup: group, equipmentType: equip)
        }
    }
}

private struct SeedEntry: Decodable {
    let name: String
    let muscleGroup: String
    let equipmentType: String
}
