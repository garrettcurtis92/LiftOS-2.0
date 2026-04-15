import Foundation
import SwiftData

extension ModelContainer {
    static var liftOS: ModelContainer {
        let schema = Schema([
            Exercise.self,
            WorkoutPlan.self,
            PlanWeek.self,
            Routine.self,
            RoutineExercise.self,
            RoutineSet.self,
            WorkoutSession.self,
            SessionExercise.self,
            SessionSet.self,
            UserProfile.self,
        ])

        let configuration = ModelConfiguration(
            "LiftOS",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // During development, if the schema changed incompatibly,
            // delete the old store and retry.
            print("⚠️ ModelContainer failed: \(error). Deleting old store and retrying...")
            Self.deleteExistingStore(named: "LiftOS")
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    static var preview: ModelContainer {
        let schema = Schema([
            Exercise.self,
            WorkoutPlan.self,
            PlanWeek.self,
            Routine.self,
            RoutineExercise.self,
            RoutineSet.self,
            WorkoutSession.self,
            SessionExercise.self,
            SessionSet.self,
            UserProfile.self,
        ])

        let configuration = ModelConfiguration(
            "Preview",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    /// Removes the existing SwiftData store files for a fresh start during development.
    private static func deleteExistingStore(named name: String) {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        let basePath = appSupport.appendingPathComponent("\(name).store").path
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: basePath + suffix)
        }
    }
}
