import Foundation
import SwiftData

@MainActor
struct SessionBuilder {
    static func createSession(
        from routine: Routine,
        context: ModelContext
    ) -> WorkoutSession {
        let session = WorkoutSession(routine: routine)

        // Check if this is a deload week
        let deloadPercentage = routine.week?.isDeloadWeek == true
            ? routine.week?.plan?.deloadPercentage
            : nil

        for (index, routineExercise) in routine.sortedExercises.enumerated() {
            let sessionExercise = SessionExercise(sortOrder: index)
            sessionExercise.exercise = routineExercise.exercise
            sessionExercise.session = session

            // Get progression suggestion if we have history
            var suggestion: ProgressionSuggestion?
            if let exercise = routineExercise.exercise,
               let firstSet = routineExercise.sortedSets.first {
                suggestion = ProgressionEngine.suggestion(
                    for: exercise,
                    targetReps: firstSet.targetReps,
                    targetRepRangeMax: firstSet.targetRepRangeMax,
                    deloadPercentage: deloadPercentage,
                    context: context
                )
            }

            for routineSet in routineExercise.sortedSets {
                let suggestedWeight: Double
                if let suggestion {
                    suggestedWeight = suggestion.suggestedWeight
                } else {
                    suggestedWeight = routineSet.targetWeight ?? 0
                }

                let sessionSet = SessionSet(
                    setNumber: routineSet.setNumber,
                    reps: 0,
                    weight: suggestedWeight
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
