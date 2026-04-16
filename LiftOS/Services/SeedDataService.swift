import Foundation
import SwiftData

struct SeedDataService {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let bundled = loadExercisesFromBundle()
        guard !bundled.isEmpty else { return }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingNames = Set(existing.map { $0.name.lowercased() })

        var inserted = 0
        for exercise in bundled {
            if !existingNames.contains(exercise.name.lowercased()) {
                context.insert(exercise)
                inserted += 1
            }
        }

        if inserted > 0 {
            try? context.save()
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
