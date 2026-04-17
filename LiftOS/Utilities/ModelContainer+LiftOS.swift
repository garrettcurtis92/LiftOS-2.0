import Foundation
import SwiftData

// MARK: - Versioned Schema

enum LiftOSSchemaV1: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
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
        ]
    }
}

// MARK: - Migration Plan

enum LiftOSMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LiftOSSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Container

extension ModelContainer {
    static var liftOS: ModelContainer {
        let schema = Schema(LiftOSSchemaV1.models)

        let configuration = ModelConfiguration(
            "LiftOS",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: LiftOSMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    static var preview: ModelContainer {
        let schema = Schema(LiftOSSchemaV1.models)

        let configuration = ModelConfiguration(
            "Preview",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: LiftOSMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}
