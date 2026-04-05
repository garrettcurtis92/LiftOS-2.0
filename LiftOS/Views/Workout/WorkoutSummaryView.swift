import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    statsGrid
                    exerciseBreakdown
                }
                .padding()
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                        .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(session.routine?.name ?? "Quick Workout")
                .font(.title2.weight(.bold))

            if let formatted = session.durationFormatted {
                Text(formatted)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Exercises", value: "\(session.exercises.count)", icon: "figure.strengthtraining.traditional")
            StatCard(title: "Sets", value: "\(completedSetsCount)", icon: "checkmark.circle.fill")
            StatCard(title: "Volume", value: formattedVolume, icon: "scalemass.fill")
        }
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Summary")
                .font(.headline)

            ForEach(session.sortedExercises) { sessionExercise in
                if let exercise = sessionExercise.exercise {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: exercise.muscleGroup.symbolName)
                                    .foregroundStyle(Color.accentColor)
                                Text(exercise.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(sessionExercise.completedSets.count) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let topSet = sessionExercise.topSet {
                                HStack {
                                    Label("Top Set", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Spacer()
                                    Text(topSet.displayString)
                                        .font(.subheadline.weight(.medium))
                                }
                            }

                            // Show all completed sets
                            ForEach(sessionExercise.sortedSets.filter(\.isCompleted)) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(set.displayString)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed

    private var completedSetsCount: Int {
        session.exercises.reduce(0) { $0 + $1.completedSets.count }
    }

    private var formattedVolume: String {
        let vol = session.totalVolume
        if vol >= 1000 {
            return String(format: "%.1fk", vol / 1000)
        }
        return String(format: "%.0f", vol)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                Text(value)
                    .font(.title3.weight(.bold))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    WorkoutSummaryView(session: WorkoutSession(isQuickWorkout: true)) {}
        .modelContainer(.preview)
}
