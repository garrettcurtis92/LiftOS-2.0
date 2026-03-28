import Foundation
import SwiftData

struct SeedDataService {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        var descriptor = FetchDescriptor<Exercise>()
        descriptor.fetchLimit = 1
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            seedExercises(context: context)
        }
    }

    @MainActor
    private static func seedExercises(context: ModelContext) {
        for exercise in defaultExercises {
            context.insert(exercise)
        }
    }

    private static var defaultExercises: [Exercise] {
        [
            // MARK: - Chest
            Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipmentType: .barbell),
            Exercise(name: "Incline Barbell Bench Press", muscleGroup: .chest, equipmentType: .barbell),
            Exercise(name: "Dumbbell Bench Press", muscleGroup: .chest, equipmentType: .dumbbell),
            Exercise(name: "Incline Dumbbell Bench Press", muscleGroup: .chest, equipmentType: .dumbbell),
            Exercise(name: "Dumbbell Fly", muscleGroup: .chest, equipmentType: .dumbbell),
            Exercise(name: "Cable Fly", muscleGroup: .chest, equipmentType: .cable),
            Exercise(name: "Machine Chest Press", muscleGroup: .chest, equipmentType: .machine),
            Exercise(name: "Pec Deck", muscleGroup: .chest, equipmentType: .machine),
            Exercise(name: "Push Up", muscleGroup: .chest, equipmentType: .bodyweight),
            Exercise(name: "Dip (Chest)", muscleGroup: .chest, equipmentType: .bodyweight),

            // MARK: - Back
            Exercise(name: "Barbell Row", muscleGroup: .back, equipmentType: .barbell),
            Exercise(name: "Pendlay Row", muscleGroup: .back, equipmentType: .barbell),
            Exercise(name: "Dumbbell Row", muscleGroup: .back, equipmentType: .dumbbell),
            Exercise(name: "Pull Up", muscleGroup: .back, equipmentType: .bodyweight),
            Exercise(name: "Chin Up", muscleGroup: .back, equipmentType: .bodyweight),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipmentType: .cable),
            Exercise(name: "Seated Cable Row", muscleGroup: .back, equipmentType: .cable),
            Exercise(name: "T-Bar Row", muscleGroup: .back, equipmentType: .barbell),
            Exercise(name: "Machine Row", muscleGroup: .back, equipmentType: .machine),
            Exercise(name: "Face Pull", muscleGroup: .back, equipmentType: .cable),
            Exercise(name: "Deadlift", muscleGroup: .back, equipmentType: .barbell),
            Exercise(name: "Rack Pull", muscleGroup: .back, equipmentType: .barbell),

            // MARK: - Shoulders
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipmentType: .barbell),
            Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipmentType: .dumbbell),
            Exercise(name: "Arnold Press", muscleGroup: .shoulders, equipmentType: .dumbbell),
            Exercise(name: "Lateral Raise", muscleGroup: .shoulders, equipmentType: .dumbbell),
            Exercise(name: "Cable Lateral Raise", muscleGroup: .shoulders, equipmentType: .cable),
            Exercise(name: "Front Raise", muscleGroup: .shoulders, equipmentType: .dumbbell),
            Exercise(name: "Reverse Fly", muscleGroup: .shoulders, equipmentType: .dumbbell),
            Exercise(name: "Machine Shoulder Press", muscleGroup: .shoulders, equipmentType: .machine),
            Exercise(name: "Upright Row", muscleGroup: .shoulders, equipmentType: .barbell),
            Exercise(name: "Shrug", muscleGroup: .shoulders, equipmentType: .barbell),
            Exercise(name: "Dumbbell Shrug", muscleGroup: .shoulders, equipmentType: .dumbbell),

            // MARK: - Quads
            Exercise(name: "Barbell Squat", muscleGroup: .quads, equipmentType: .barbell),
            Exercise(name: "Front Squat", muscleGroup: .quads, equipmentType: .barbell),
            Exercise(name: "Goblet Squat", muscleGroup: .quads, equipmentType: .dumbbell),
            Exercise(name: "Leg Press", muscleGroup: .quads, equipmentType: .machine),
            Exercise(name: "Hack Squat", muscleGroup: .quads, equipmentType: .machine),
            Exercise(name: "Leg Extension", muscleGroup: .quads, equipmentType: .machine),
            Exercise(name: "Bulgarian Split Squat", muscleGroup: .quads, equipmentType: .dumbbell),
            Exercise(name: "Walking Lunge", muscleGroup: .quads, equipmentType: .dumbbell),
            Exercise(name: "Smith Machine Squat", muscleGroup: .quads, equipmentType: .smithMachine),

            // MARK: - Hamstrings
            Exercise(name: "Romanian Deadlift", muscleGroup: .hamstrings, equipmentType: .barbell),
            Exercise(name: "Dumbbell Romanian Deadlift", muscleGroup: .hamstrings, equipmentType: .dumbbell),
            Exercise(name: "Lying Leg Curl", muscleGroup: .hamstrings, equipmentType: .machine),
            Exercise(name: "Seated Leg Curl", muscleGroup: .hamstrings, equipmentType: .machine),
            Exercise(name: "Stiff-Leg Deadlift", muscleGroup: .hamstrings, equipmentType: .barbell),
            Exercise(name: "Good Morning", muscleGroup: .hamstrings, equipmentType: .barbell),
            Exercise(name: "Nordic Hamstring Curl", muscleGroup: .hamstrings, equipmentType: .bodyweight),

            // MARK: - Glutes
            Exercise(name: "Hip Thrust", muscleGroup: .glutes, equipmentType: .barbell),
            Exercise(name: "Cable Pull Through", muscleGroup: .glutes, equipmentType: .cable),
            Exercise(name: "Glute Bridge", muscleGroup: .glutes, equipmentType: .bodyweight),
            Exercise(name: "Cable Kickback", muscleGroup: .glutes, equipmentType: .cable),
            Exercise(name: "Hip Abduction Machine", muscleGroup: .glutes, equipmentType: .machine),

            // MARK: - Arms (Biceps)
            Exercise(name: "Barbell Curl", muscleGroup: .arms, equipmentType: .barbell),
            Exercise(name: "Dumbbell Curl", muscleGroup: .arms, equipmentType: .dumbbell),
            Exercise(name: "Hammer Curl", muscleGroup: .arms, equipmentType: .dumbbell),
            Exercise(name: "Preacher Curl", muscleGroup: .arms, equipmentType: .barbell),
            Exercise(name: "Incline Dumbbell Curl", muscleGroup: .arms, equipmentType: .dumbbell),
            Exercise(name: "Cable Curl", muscleGroup: .arms, equipmentType: .cable),
            Exercise(name: "Concentration Curl", muscleGroup: .arms, equipmentType: .dumbbell),
            Exercise(name: "EZ-Bar Curl", muscleGroup: .arms, equipmentType: .barbell),

            // MARK: - Arms (Triceps)
            Exercise(name: "Close-Grip Bench Press", muscleGroup: .arms, equipmentType: .barbell),
            Exercise(name: "Tricep Pushdown", muscleGroup: .arms, equipmentType: .cable),
            Exercise(name: "Overhead Tricep Extension", muscleGroup: .arms, equipmentType: .cable),
            Exercise(name: "Skull Crusher", muscleGroup: .arms, equipmentType: .barbell),
            Exercise(name: "Dumbbell Tricep Extension", muscleGroup: .arms, equipmentType: .dumbbell),
            Exercise(name: "Dip (Triceps)", muscleGroup: .arms, equipmentType: .bodyweight),
            Exercise(name: "Diamond Push Up", muscleGroup: .arms, equipmentType: .bodyweight),

            // MARK: - Core
            Exercise(name: "Plank", muscleGroup: .core, equipmentType: .bodyweight),
            Exercise(name: "Hanging Leg Raise", muscleGroup: .core, equipmentType: .bodyweight),
            Exercise(name: "Cable Crunch", muscleGroup: .core, equipmentType: .cable),
            Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipmentType: .bodyweight),
            Exercise(name: "Russian Twist", muscleGroup: .core, equipmentType: .bodyweight),
            Exercise(name: "Pallof Press", muscleGroup: .core, equipmentType: .cable),
            Exercise(name: "Decline Sit Up", muscleGroup: .core, equipmentType: .bodyweight),
            Exercise(name: "Bicycle Crunch", muscleGroup: .core, equipmentType: .bodyweight),

            // MARK: - Full Body / Compound
            Exercise(name: "Clean and Press", muscleGroup: .fullBody, equipmentType: .barbell),
            Exercise(name: "Power Clean", muscleGroup: .fullBody, equipmentType: .barbell),
            Exercise(name: "Kettlebell Swing", muscleGroup: .fullBody, equipmentType: .dumbbell),
            Exercise(name: "Thruster", muscleGroup: .fullBody, equipmentType: .barbell),
            Exercise(name: "Burpee", muscleGroup: .fullBody, equipmentType: .bodyweight),
            Exercise(name: "Turkish Get Up", muscleGroup: .fullBody, equipmentType: .dumbbell),
        ]
    }
}
