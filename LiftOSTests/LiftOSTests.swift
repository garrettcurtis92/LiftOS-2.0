import Testing
import Foundation
import SwiftData
@testable import AdaptOS

// MARK: - ProgressionEngine Tests

@Suite("ProgressionEngine")
struct ProgressionEngineTests {

    @Test("Below target reps → maintain weight")
    func belowMinReps() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 135, prevReps: 6,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 5.0, deloadPercentage: nil
        )
        #expect(result.reason == .maintainWeight)
        #expect(result.suggestedWeight == 135)
        #expect(result.suggestedReps == 8)
    }

    @Test("At target reps but below max → add one rep")
    func midRange() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 135, prevReps: 10,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 5.0, deloadPercentage: nil
        )
        #expect(result.reason == .addRep)
        #expect(result.suggestedWeight == 135)
        #expect(result.suggestedReps == 11)
    }

    @Test("At or above range max → increase weight, reset to target reps")
    func atMaxReps() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 135, prevReps: 12,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 5.0, deloadPercentage: nil
        )
        #expect(result.reason == .increaseWeight)
        #expect(result.suggestedWeight == 140)
        #expect(result.suggestedReps == 8)
    }

    @Test("Above range max → still increases weight")
    func aboveMaxReps() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 50, prevReps: 15,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 5.0, deloadPercentage: nil
        )
        #expect(result.reason == .increaseWeight)
        #expect(result.suggestedWeight == 55)
        #expect(result.suggestedReps == 8)
    }

    @Test("Deload → reduce weight by percentage")
    func deloadWeek() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 200, prevReps: 10,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 5.0, deloadPercentage: 0.7
        )
        #expect(result.reason == .deload)
        #expect(result.suggestedWeight == 140)
        #expect(result.suggestedReps == 8)
    }

    @Test("No rep range max → target reps used as max")
    func noRepRangeMax() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 100, prevReps: 8,
            targetReps: 8, targetRepRangeMax: nil,
            increment: 5.0, deloadPercentage: nil
        )
        #expect(result.reason == .increaseWeight)
        #expect(result.suggestedWeight == 105)
    }

    @Test("Cable increment is 2.5 lbs")
    func cableIncrement() async {
        let result = await ProgressionEngine.computeSuggestion(
            prevWeight: 40, prevReps: 12,
            targetReps: 8, targetRepRangeMax: 12,
            increment: 2.5, deloadPercentage: nil
        )
        #expect(result.suggestedWeight == 42.5)
    }

    @Test("Round to increment works correctly")
    func roundToIncrement() async {
        let r1 = await ProgressionEngine.roundToIncrement(137.0, increment: 5.0)
        #expect(r1 == 135.0)

        let r2 = await ProgressionEngine.roundToIncrement(138.0, increment: 5.0)
        #expect(r2 == 140.0)

        let r3 = await ProgressionEngine.roundToIncrement(41.3, increment: 2.5)
        #expect(r3 == 42.5)

        let r4 = await ProgressionEngine.roundToIncrement(100.0, increment: 0.0)
        #expect(r4 == 100.0)
    }
}

// MARK: - ProgressCalculator Tests

@Suite("ProgressCalculator")
struct ProgressCalculatorTests {

    private func makeSession(startedAt: Date, completedAt: Date, volume: Double = 0) -> WorkoutSession {
        let session = WorkoutSession()
        session.startedAt = startedAt
        session.completedAt = completedAt
        if volume > 0 {
            let exercise = SessionExercise(sortOrder: 0)
            let set = SessionSet(setNumber: 1, reps: Int(volume / 100), weight: 100)
            set.completedAt = completedAt
            exercise.sets = [set]
            exercise.session = session
            session.exercises = [exercise]
        }
        return session
    }

    @Test("Total completed workouts counts sessions")
    func totalWorkouts() {
        let sessions = [
            makeSession(startedAt: Date(), completedAt: Date()),
            makeSession(startedAt: Date(), completedAt: Date()),
        ]
        #expect(ProgressCalculator.totalCompletedWorkouts(sessions) == 2)
    }

    @Test("Total volume sums working sets excluding warmups")
    func totalVolume() {
        let session = WorkoutSession()
        session.completedAt = Date()
        let exercise = SessionExercise(sortOrder: 0)
        let workingSet = SessionSet(setNumber: 1, reps: 10, weight: 100)
        workingSet.completedAt = Date()
        let warmupSet = SessionSet(setNumber: 2, reps: 5, weight: 50, isWarmup: true)
        warmupSet.completedAt = Date()
        exercise.sets = [workingSet, warmupSet]
        exercise.session = session
        session.exercises = [exercise]

        let vol = ProgressCalculator.totalVolume([session])
        #expect(vol == 1000.0)
    }

    @Test("Weekly volume buckets sessions by calendar week")
    func weeklyVolumeBucketing() {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let s1 = makeSession(startedAt: now, completedAt: now, volume: 500)
        let s2 = makeSession(startedAt: oneWeekAgo, completedAt: oneWeekAgo, volume: 300)

        let points = ProgressCalculator.weeklyVolume([s1, s2], range: .fourWeeks)
        let nonZero = points.filter { $0.volume > 0 }
        #expect(nonZero.count >= 1)
    }

    @Test("Muscle group balance counts working sets per group")
    func muscleBalance() {
        let session = WorkoutSession()
        session.startedAt = Date()
        session.completedAt = Date()

        let chestExercise = Exercise(name: "Bench", muscleGroup: .chest, equipmentType: .barbell)
        let se = SessionExercise(sortOrder: 0)
        se.exercise = chestExercise
        let s1 = SessionSet(setNumber: 1, reps: 8, weight: 135)
        s1.completedAt = Date()
        let s2 = SessionSet(setNumber: 2, reps: 8, weight: 135)
        s2.completedAt = Date()
        se.sets = [s1, s2]
        se.session = session
        session.exercises = [se]

        let balance = ProgressCalculator.muscleGroupBalance([session], range: .fourWeeks)
        let chest = balance.first { $0.muscleGroup == .chest }
        #expect(chest?.setCount == 2)
    }

    @Test("Cumulative tonnage accumulates in order")
    func cumulativeTonnage() {
        let d1 = Date(timeIntervalSince1970: 1000)
        let d2 = Date(timeIntervalSince1970: 2000)

        let s1 = makeSession(startedAt: d1, completedAt: d1, volume: 500)
        let s2 = makeSession(startedAt: d2, completedAt: d2, volume: 300)

        let points = ProgressCalculator.cumulativeTonnage([s1, s2])
        #expect(points.count == 2)
        #expect(points[0].cumulativeVolume == 500)
        #expect(points[1].cumulativeVolume == 800)
    }

    @Test("Streak with no plan returns zero")
    func streakNoPlan() {
        let session = makeSession(startedAt: Date(), completedAt: Date())
        let result = ProgressCalculator.streak(plan: nil, sessions: [session])
        #expect(result.current == 0)
        #expect(result.longest == 0)
    }
}

// MARK: - SessionBuilder Tests

@Suite("SessionBuilder")
struct SessionBuilderTests {

    @Test("Quick session is marked as quick workout with no exercises")
    @MainActor func quickSession() throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        let session = SessionBuilder.createQuickSession(context: context)
        #expect(session.isQuickWorkout == true)
        #expect(session.exercises.isEmpty)
        #expect(session.completedAt == nil)
    }

    @Test("addExercise creates correct number of default sets")
    @MainActor func addExerciseDefaultSets() throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        let session = SessionBuilder.createQuickSession(context: context)
        let exercise = Exercise(name: "Test Curl", muscleGroup: .arms, equipmentType: .dumbbell)
        context.insert(exercise)

        let se = SessionBuilder.addExercise(exercise, to: session)
        #expect(se.sets.count == 3)
        #expect(se.exercise?.name == "Test Curl")
        #expect(session.exercises.count == 1)
    }

    @Test("addExercise respects custom set count")
    @MainActor func addExerciseCustomSets() throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        let session = SessionBuilder.createQuickSession(context: context)
        let exercise = Exercise(name: "Squat", muscleGroup: .quads, equipmentType: .barbell)
        context.insert(exercise)

        let se = SessionBuilder.addExercise(exercise, to: session, defaultSets: 5)
        #expect(se.sets.count == 5)
    }
}

// MARK: - PlanSyncService Tests

@Suite("PlanSyncService")
struct PlanSyncServiceTests {

    @Test("isWeekOne returns true for week number 1")
    @MainActor func weekOneCheck() {
        let week = PlanWeek(weekNumber: 1)
        let routine = Routine(name: "Push", dayOfWeek: 1, sortOrder: 0)
        routine.week = week
        #expect(PlanSyncService.isWeekOne(routine) == true)

        let week3 = PlanWeek(weekNumber: 3)
        let routine3 = Routine(name: "Pull", dayOfWeek: 2, sortOrder: 0)
        routine3.week = week3
        #expect(PlanSyncService.isWeekOne(routine3) == false)
    }

    @Test("populateWeekFromTemplate copies routines from earliest week")
    @MainActor func populateFromTemplate() {
        let plan = WorkoutPlan(name: "Test Plan", numberOfWeeks: 2)

        let week1 = PlanWeek(weekNumber: 1)
        week1.plan = plan
        let routine = Routine(name: "Push", dayOfWeek: 1, sortOrder: 0)
        let re = RoutineExercise(sortOrder: 0)
        let rs = RoutineSet(setNumber: 1, targetReps: 8)
        re.sets = [rs]
        routine.exercises = [re]
        routine.week = week1
        week1.routines = [routine]

        let week2 = PlanWeek(weekNumber: 2)
        week2.plan = plan
        week2.routines = []

        plan.weeks = [week1, week2]

        PlanSyncService.populateWeekFromTemplate(week2, plan: plan)

        #expect(week2.routines.count == 1)
        #expect(week2.routines.first?.name == "Push")
        #expect(week2.routines.first?.exercises.count == 1)
        #expect(week2.routines.first?.exercises.first?.sets.count == 1)
    }

    @Test("replicateRoutine skips weeks that already have the routine")
    @MainActor func replicateSkipsDuplicates() {
        let plan = WorkoutPlan(name: "Test", numberOfWeeks: 2)

        let week1 = PlanWeek(weekNumber: 1)
        week1.plan = plan
        let routine = Routine(name: "Legs", dayOfWeek: 3, sortOrder: 0)
        routine.week = week1
        week1.routines = [routine]

        let week2 = PlanWeek(weekNumber: 2)
        week2.plan = plan
        let existing = Routine(name: "Legs", dayOfWeek: 3, sortOrder: 0)
        existing.week = week2
        week2.routines = [existing]

        plan.weeks = [week1, week2]

        PlanSyncService.replicateRoutine(routine, across: plan)

        #expect(week2.routines.count == 1)
    }
}

// MARK: - SessionExercise.reorder Tests

@Suite("SessionExercise.reorder")
struct SessionExerciseReorderTests {

    private func makeExercises(count: Int) -> [SessionExercise] {
        (0..<count).map { SessionExercise(sortOrder: $0) }
    }

    @Test("Move single item from index 2 to index 0 reindexes sortOrder")
    func moveUp() {
        let items = makeExercises(count: 4)
        SessionExercise.reorder(items, from: IndexSet(integer: 2), to: 0)

        // Starting [A,B,C,D] sortOrders [0,1,2,3]
        // After move(fromOffsets: [2], toOffset: 0): [C,A,B,D]
        // Reindexed: A=1, B=2, C=0, D=3
        #expect(items[0].sortOrder == 1)
        #expect(items[1].sortOrder == 2)
        #expect(items[2].sortOrder == 0)
        #expect(items[3].sortOrder == 3)
    }

    @Test("Move from index 0 to index 3 reindexes sortOrder")
    func moveDown() {
        let items = makeExercises(count: 4)
        SessionExercise.reorder(items, from: IndexSet(integer: 0), to: 3)

        // After move(fromOffsets: [0], toOffset: 3): [B,C,A,D]
        // Reindexed: A=2, B=0, C=1, D=3
        #expect(items[0].sortOrder == 2)
        #expect(items[1].sortOrder == 0)
        #expect(items[2].sortOrder == 1)
        #expect(items[3].sortOrder == 3)
    }

    @Test("Move with empty IndexSet is a no-op")
    func moveEmpty() {
        let items = makeExercises(count: 3)
        SessionExercise.reorder(items, from: IndexSet(), to: 0)
        #expect(items[0].sortOrder == 0)
        #expect(items[1].sortOrder == 1)
        #expect(items[2].sortOrder == 2)
    }
}
