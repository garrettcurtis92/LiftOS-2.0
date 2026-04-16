import Foundation

enum ProgressTimeRange: String, CaseIterable, Identifiable {
    case fourWeeks
    case threeMonths
    case sixMonths
    case oneYear

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .fourWeeks: return 28
        case .threeMonths: return 90
        case .sixMonths: return 183
        case .oneYear: return 365
        }
    }

    var displayName: String {
        switch self {
        case .fourWeeks: return "4W"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        }
    }
}

struct WeeklyVolumePoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let volume: Double
}

struct MuscleGroupCount: Identifiable {
    let id = UUID()
    let muscleGroup: MuscleGroup
    let setCount: Int
}

struct TonnagePoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeVolume: Double
}

enum ProgressCalculator {

    // MARK: - Hero KPIs

    static func totalVolume(_ sessions: [WorkoutSession]) -> Double {
        sessions.reduce(0) { $0 + sessionVolume($1) }
    }

    static func totalCompletedWorkouts(_ sessions: [WorkoutSession]) -> Int {
        sessions.count
    }

    // MARK: - Weekly Volume

    static func weeklyVolume(_ sessions: [WorkoutSession], range: ProgressTimeRange) -> [WeeklyVolumePoint] {
        let calendar = Calendar.current
        let today = Date()
        guard let rangeStart = calendar.date(byAdding: .day, value: -range.days, to: today) else {
            return []
        }

        // Bucket sessions by week start
        var buckets: [Date: Double] = [:]
        for session in sessions where session.startedAt >= rangeStart {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startedAt)?.start else {
                continue
            }
            buckets[weekStart, default: 0] += sessionVolume(session)
        }

        // Generate continuous weekly points from range start to today
        guard let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: rangeStart)?.start,
              let lastWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }

        var points: [WeeklyVolumePoint] = []
        var cursor = firstWeekStart
        while cursor <= lastWeekStart {
            points.append(WeeklyVolumePoint(weekStart: cursor, volume: buckets[cursor] ?? 0))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    // MARK: - Muscle Group Balance

    static func muscleGroupBalance(_ sessions: [WorkoutSession], range: ProgressTimeRange) -> [MuscleGroupCount] {
        let calendar = Calendar.current
        guard let rangeStart = calendar.date(byAdding: .day, value: -range.days, to: Date()) else {
            return []
        }

        var counts: [MuscleGroup: Int] = [:]
        for session in sessions where session.startedAt >= rangeStart {
            for sessionExercise in session.exercises {
                guard let group = sessionExercise.exercise?.muscleGroup else { continue }
                let workingSets = sessionExercise.sets.filter { $0.isCompleted && !$0.isWarmup }
                counts[group, default: 0] += workingSets.count
            }
        }

        return counts
            .filter { $0.value > 0 }
            .map { MuscleGroupCount(muscleGroup: $0.key, setCount: $0.value) }
            .sorted { $0.setCount > $1.setCount }
    }

    // MARK: - Cumulative Tonnage

    static func cumulativeTonnage(_ sessions: [WorkoutSession]) -> [TonnagePoint] {
        let sorted = sessions
            .compactMap { session -> (Date, Double)? in
                guard let completedAt = session.completedAt else { return nil }
                return (completedAt, sessionVolume(session))
            }
            .sorted { $0.0 < $1.0 }

        var running: Double = 0
        return sorted.map { date, volume in
            running += volume
            return TonnagePoint(date: date, cumulativeVolume: running)
        }
    }

    // MARK: - Streak

    static func streak(plan: WorkoutPlan?, sessions: [WorkoutSession]) -> (current: Int, longest: Int) {
        guard let plan,
              let scheduledDays = plan.currentWeek?.routines.compactMap({ $0.dayOfWeek }),
              !scheduledDays.isEmpty else {
            return (0, 0)
        }

        let scheduledSet = Set(scheduledDays)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let earliest = sessions.map({ $0.startedAt }).min() else {
            return (0, 0)
        }

        let startDay = calendar.startOfDay(for: earliest)
        let completedDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })

        var runningStreak = 0
        var longest = 0
        var cursor = startDay

        while cursor <= today {
            let weekday = calendar.component(.weekday, from: cursor)
            let appDayOfWeek = weekday == 1 ? 7 : weekday - 1

            if scheduledSet.contains(appDayOfWeek) {
                if completedDays.contains(cursor) {
                    runningStreak += 1
                    longest = max(longest, runningStreak)
                } else if !calendar.isDate(cursor, inSameDayAs: today) {
                    runningStreak = 0
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return (runningStreak, longest)
    }

    // MARK: - Helpers

    private static func sessionVolume(_ session: WorkoutSession) -> Double {
        session.exercises.reduce(0.0) { total, exercise in
            let working = exercise.sets.filter { $0.isCompleted && !$0.isWarmup }
            return total + working.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }
}
