import Foundation
import SwiftData

@MainActor
struct PlanSyncService {

    // MARK: - Replicate a routine from one week to all other weeks in the plan

    static func replicateRoutine(_ routine: Routine, across plan: WorkoutPlan) {
        guard let sourceWeek = routine.week else { return }

        for week in plan.weeks where week.id != sourceWeek.id {
            // Skip if this week already has a routine with the same name
            guard !week.routines.contains(where: { $0.name == routine.name }) else { continue }
            let copy = copyRoutine(routine)
            copy.week = week
            week.routines.append(copy)
        }
    }

    // MARK: - Remove a routine by name from all other weeks

    static func removeRoutineFromOtherWeeks(named name: String, excludingWeek: PlanWeek, in plan: WorkoutPlan, context: ModelContext) {
        for week in plan.weeks where week.id != excludingWeek.id {
            if let match = week.routines.first(where: { $0.name == name }) {
                week.routines.removeAll { $0.id == match.id }
                context.delete(match)
            }
        }
    }

    // MARK: - Sync exercises from a source routine to matching routines in other weeks

    static func syncExercises(from source: Routine, across plan: WorkoutPlan, context: ModelContext) {
        guard let sourceWeek = source.week else { return }

        for week in plan.weeks where week.id != sourceWeek.id {
            if let target = week.routines.first(where: { $0.name == source.name }) {
                replaceExercises(in: target, from: source, context: context)
            }
        }
    }

    // MARK: - Sync routines when a new week is added (copy all from week 1)

    static func populateWeekFromTemplate(_ newWeek: PlanWeek, plan: WorkoutPlan) {
        guard let templateWeek = plan.weeks
            .filter({ $0.id != newWeek.id })
            .sorted(by: { $0.weekNumber < $1.weekNumber })
            .first else { return }

        for routine in templateWeek.sortedRoutines {
            let copy = copyRoutine(routine)
            copy.week = newWeek
            newWeek.routines.append(copy)
        }
    }

    // MARK: - Check if a routine is in Week 1

    static func isWeekOne(_ routine: Routine) -> Bool {
        routine.week?.weekNumber == 1
    }

    // MARK: - Private Helpers

    private static func copyRoutine(_ source: Routine) -> Routine {
        let copy = Routine(
            name: source.name,
            dayOfWeek: source.dayOfWeek,
            sortOrder: source.sortOrder
        )

        for re in source.sortedExercises {
            let reCopy = RoutineExercise(
                sortOrder: re.sortOrder,
                restSeconds: re.restSeconds,
                notes: re.notes
            )
            reCopy.exercise = re.exercise
            reCopy.routine = copy

            for set in re.sortedSets {
                let setCopy = RoutineSet(
                    setNumber: set.setNumber,
                    targetReps: set.targetReps,
                    targetRepRangeMax: set.targetRepRangeMax,
                    targetWeight: set.targetWeight
                )
                setCopy.routineExercise = reCopy
                reCopy.sets.append(setCopy)
            }

            copy.exercises.append(reCopy)
        }

        return copy
    }

    private static func replaceExercises(in target: Routine, from source: Routine, context: ModelContext) {
        // Remove existing exercises from target
        for existing in target.exercises {
            context.delete(existing)
        }
        target.exercises.removeAll()

        // Copy exercises from source
        for re in source.sortedExercises {
            let reCopy = RoutineExercise(
                sortOrder: re.sortOrder,
                restSeconds: re.restSeconds,
                notes: re.notes
            )
            reCopy.exercise = re.exercise
            reCopy.routine = target

            for set in re.sortedSets {
                let setCopy = RoutineSet(
                    setNumber: set.setNumber,
                    targetReps: set.targetReps,
                    targetRepRangeMax: set.targetRepRangeMax,
                    targetWeight: set.targetWeight
                )
                setCopy.routineExercise = reCopy
                reCopy.sets.append(setCopy)
            }

            target.exercises.append(reCopy)
        }
    }
}
