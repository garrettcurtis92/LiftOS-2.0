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
            fatalError("Failed to create ModelContainer: \(error)")
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
}
