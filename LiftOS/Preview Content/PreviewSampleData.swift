import Foundation
import SwiftData

@MainActor
struct PreviewSampleData {
    static func populate(context: ModelContext) {
        // Seed exercises
        SeedDataService.seedIfNeeded(context: context)

        // Fetch a few exercises for the plan
        var descriptor = FetchDescriptor<Exercise>()
        descriptor.fetchLimit = 20
        guard let exercises = try? context.fetch(descriptor), exercises.count >= 10 else { return }

        let benchPress = exercises.first { $0.name == "Barbell Bench Press" } ?? exercises[0]
        let squat = exercises.first { $0.name == "Barbell Squat" } ?? exercises[1]
        let deadlift = exercises.first { $0.name == "Deadlift" } ?? exercises[2]
        let overhead = exercises.first { $0.name == "Overhead Press" } ?? exercises[3]
        let row = exercises.first { $0.name == "Barbell Row" } ?? exercises[4]
        let latPull = exercises.first { $0.name == "Lat Pulldown" } ?? exercises[5]
        let legPress = exercises.first { $0.name == "Leg Press" } ?? exercises[6]
        let curl = exercises.first { $0.name == "Barbell Curl" } ?? exercises[7]
        let pushdown = exercises.first { $0.name == "Tricep Pushdown" } ?? exercises[8]
        let lateralRaise = exercises.first { $0.name == "Lateral Raise" } ?? exercises[9]

        // Create a sample plan
        let plan = WorkoutPlan(name: "Upper/Lower 4-Day", numberOfWeeks: 4, deloadFrequency: 4, isActive: true)
        context.insert(plan)

        // Week 1
        let week1 = PlanWeek(weekNumber: 1)
        week1.plan = plan
        plan.weeks.append(week1)

        // Upper A
        let upperA = Routine(name: "Upper A", dayOfWeek: 1, sortOrder: 0)
        upperA.week = week1
        week1.routines.append(upperA)
        addRoutineExercise(benchPress, to: upperA, sets: 4, reps: 8, maxReps: 12, weight: 135, order: 0)
        addRoutineExercise(row, to: upperA, sets: 4, reps: 8, maxReps: 12, weight: 135, order: 1)
        addRoutineExercise(overhead, to: upperA, sets: 3, reps: 8, maxReps: 12, weight: 95, order: 2)
        addRoutineExercise(latPull, to: upperA, sets: 3, reps: 10, maxReps: 15, weight: 120, order: 3)
        addRoutineExercise(curl, to: upperA, sets: 3, reps: 10, maxReps: 15, weight: 65, order: 4)
        addRoutineExercise(pushdown, to: upperA, sets: 3, reps: 10, maxReps: 15, weight: 50, order: 5)

        // Lower A
        let lowerA = Routine(name: "Lower A", dayOfWeek: 2, sortOrder: 1)
        lowerA.week = week1
        week1.routines.append(lowerA)
        addRoutineExercise(squat, to: lowerA, sets: 4, reps: 6, maxReps: 10, weight: 185, order: 0)
        addRoutineExercise(legPress, to: lowerA, sets: 3, reps: 10, maxReps: 15, weight: 270, order: 1)
        addRoutineExercise(deadlift, to: lowerA, sets: 3, reps: 5, maxReps: 8, weight: 225, order: 2)
        addRoutineExercise(lateralRaise, to: lowerA, sets: 3, reps: 12, maxReps: 15, weight: 20, order: 3)

        // Create a completed session for history
        let session = WorkoutSession(routine: upperA)
        session.startedAt = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        session.completedAt = Calendar.current.date(byAdding: .hour, value: 1, to: session.startedAt)
        context.insert(session)

        let seBench = SessionExercise(sortOrder: 0)
        seBench.exercise = benchPress
        seBench.session = session
        session.exercises.append(seBench)

        for i in 1...4 {
            let set = SessionSet(setNumber: i, reps: i <= 2 ? 10 : 8, weight: 135)
            set.completedAt = Date()
            set.sessionExercise = seBench
            seBench.sets.append(set)
        }

        let seRow = SessionExercise(sortOrder: 1)
        seRow.exercise = row
        seRow.session = session
        session.exercises.append(seRow)

        for i in 1...4 {
            let set = SessionSet(setNumber: i, reps: 10, weight: 135)
            set.completedAt = Date()
            set.sessionExercise = seRow
            seRow.sets.append(set)
        }
    }

    private static func addRoutineExercise(
        _ exercise: Exercise,
        to routine: Routine,
        sets: Int,
        reps: Int,
        maxReps: Int,
        weight: Double,
        order: Int
    ) {
        let re = RoutineExercise(sortOrder: order)
        re.exercise = exercise
        re.routine = routine
        routine.exercises.append(re)

        for i in 1...sets {
            let set = RoutineSet(setNumber: i, targetReps: reps, targetRepRangeMax: maxReps, targetWeight: weight)
            set.routineExercise = re
            re.sets.append(set)
        }
    }
}
