import Foundation
import SwiftData

@MainActor
struct SessionBuilder {
    static func createSession(
        from routine: Routine,
        context: ModelContext
    ) -> WorkoutSession {
        let session = WorkoutSession(routine: routine)

        for (index, routineExercise) in routine.sortedExercises.enumerated() {
            let sessionExercise = SessionExercise(sortOrder: index)
            sessionExercise.exercise = routineExercise.exercise
            sessionExercise.session = session

            for routineSet in routineExercise.sortedSets {
                let sessionSet = SessionSet(
                    setNumber: routineSet.setNumber,
                    reps: 0,
                    weight: routineSet.targetWeight ?? 0
                )
                sessionSet.sessionExercise = sessionExercise
                sessionExercise.sets.append(sessionSet)
            }

            session.exercises.append(sessionExercise)
        }

        context.insert(session)
        return session
    }

    static func createQuickSession(context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(isQuickWorkout: true)
        context.insert(session)
        return session
    }

    static func addExercise(
        _ exercise: Exercise,
        to session: WorkoutSession,
        defaultSets: Int = 3
    ) -> SessionExercise {
        let sessionExercise = SessionExercise(sortOrder: session.exercises.count)
        sessionExercise.exercise = exercise
        sessionExercise.session = session

        for i in 1...defaultSets {
            let set = SessionSet(setNumber: i)
            set.sessionExercise = sessionExercise
            sessionExercise.sets.append(set)
        }

        session.exercises.append(sessionExercise)
        return sessionExercise
    }
}
