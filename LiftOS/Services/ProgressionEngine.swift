import Foundation
import SwiftData

struct ProgressionSuggestion {
    let suggestedWeight: Double
    let suggestedReps: Int
    let previousWeight: Double
    let previousReps: Int
    let reason: ProgressionReason
}

enum ProgressionReason {
    case maintainWeight
    case addRep
    case increaseWeight
    case deload
    case firstTime
}

@MainActor
struct ProgressionEngine {
    static func suggestion(
        for exercise: Exercise,
        targetReps: Int,
        targetRepRangeMax: Int?,
        deloadPercentage: Double?,
        before date: Date = Date(),
        context: ModelContext
    ) -> ProgressionSuggestion? {
        guard let previousSet = fetchPreviousTopSet(
            for: exercise,
            before: date,
            context: context
        ) else {
            return nil
        }

        return computeSuggestion(
            prevWeight: previousSet.weight,
            prevReps: previousSet.reps,
            targetReps: targetReps,
            targetRepRangeMax: targetRepRangeMax,
            increment: exercise.equipmentType.weightIncrement,
            deloadPercentage: deloadPercentage
        )
    }

    static func computeSuggestion(
        prevWeight: Double,
        prevReps: Int,
        targetReps: Int,
        targetRepRangeMax: Int?,
        increment: Double,
        deloadPercentage: Double?
    ) -> ProgressionSuggestion {
        let rangeMax = targetRepRangeMax ?? targetReps

        if let deloadPercentage {
            let deloadWeight = roundToIncrement(prevWeight * deloadPercentage, increment: increment)
            return ProgressionSuggestion(
                suggestedWeight: deloadWeight,
                suggestedReps: targetReps,
                previousWeight: prevWeight,
                previousReps: prevReps,
                reason: .deload
            )
        }

        if prevReps < targetReps {
            return ProgressionSuggestion(
                suggestedWeight: prevWeight,
                suggestedReps: targetReps,
                previousWeight: prevWeight,
                previousReps: prevReps,
                reason: .maintainWeight
            )
        }

        if prevReps >= targetReps && prevReps < rangeMax {
            return ProgressionSuggestion(
                suggestedWeight: prevWeight,
                suggestedReps: prevReps + 1,
                previousWeight: prevWeight,
                previousReps: prevReps,
                reason: .addRep
            )
        }

        let newWeight = prevWeight + increment
        return ProgressionSuggestion(
            suggestedWeight: newWeight,
            suggestedReps: targetReps,
            previousWeight: prevWeight,
            previousReps: prevReps,
            reason: .increaseWeight
        )
    }

    private static func fetchPreviousTopSet(
        for exercise: Exercise,
        before date: Date,
        context: ModelContext
    ) -> SessionSet? {
        let exerciseID = exercise.id
        let predicate = #Predicate<SessionExercise> {
            $0.exercise?.id == exerciseID
        }
        var descriptor = FetchDescriptor<SessionExercise>(predicate: predicate)
        descriptor.fetchLimit = 10

        guard let sessionExercises = try? context.fetch(descriptor) else { return nil }

        let completedBefore = sessionExercises
            .filter { se in
                guard let completedAt = se.session?.completedAt else { return false }
                return completedAt < date
            }
            .sorted { a, b in
                (a.session?.completedAt ?? .distantPast) > (b.session?.completedAt ?? .distantPast)
            }

        guard let mostRecent = completedBefore.first else { return nil }

        return mostRecent.sortedSets
            .filter { !$0.isWarmup && $0.isCompleted }
            .max { $0.volume < $1.volume }
    }

    static func roundToIncrement(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value }
        return (value / increment).rounded() * increment
    }
}
