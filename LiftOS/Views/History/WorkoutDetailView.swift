import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsRow
                exerciseSections
            }
            .padding()
        }
        .navigationTitle(session.routine?.name ?? "Quick Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(session.startedAt, format: .dateTime.weekday(.wide).month().day().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let duration = session.durationFormatted {
                Text(duration)
                    .font(.title.weight(.bold))
            }

            Text("\(session.startedAt, format: .dateTime.hour().minute()) – \(session.completedAt ?? Date(), format: .dateTime.hour().minute())")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(session.exercises.count)", label: "Exercises")
            Divider().frame(height: 32)
            statItem(value: "\(completedSetsCount)", label: "Sets")
            Divider().frame(height: 32)
            statItem(value: formattedVolume, label: "Volume")
        }
        .padding(.vertical, 12)
        .background(Color.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercises

    private var exerciseSections: some View {
        VStack(spacing: 12) {
            ForEach(session.sortedExercises) { sessionExercise in
                if let exercise = sessionExercise.exercise {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: exercise.muscleGroup.symbolName)
                                    .foregroundStyle(Color.accentColor)
                                Text(exercise.name)
                                    .font(.headline)
                                Spacer()
                            }

                            // Set header
                            HStack {
                                Text("SET")
                                    .frame(width: 36, alignment: .leading)
                                Text("WEIGHT")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text("REPS")
                                    .frame(width: 50, alignment: .center)
                                Text("VOL")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                            ForEach(sessionExercise.sortedSets) { set in
                                setRow(set)
                            }

                            if let topSet = sessionExercise.topSet {
                                Divider()
                                HStack {
                                    Label("Top Set", systemImage: "star.fill")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.orange)
                                    Spacer()
                                    Text(topSet.displayString)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func setRow(_ set: SessionSet) -> some View {
        HStack {
            Text("\(set.setNumber)")
                .frame(width: 36, alignment: .leading)
                .foregroundStyle(set.isWarmup ? Color.orange : (set.isCompleted ? Color.primary : Color.secondary))

            Text(set.isCompleted ? formatWeight(set.weight) : "–")
                .frame(maxWidth: .infinity, alignment: .center)

            Text(set.isCompleted ? "\(set.reps)" : "–")
                .frame(width: 50, alignment: .center)

            Text(set.isCompleted ? formatVolume(set.volume) : "–")
                .frame(width: 60, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.vertical, 2)
        .opacity(set.isCompleted ? 1 : 0.4)
    }

    // MARK: - Helpers

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

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return String(format: "%.0f", v)
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(session: WorkoutSession(isQuickWorkout: true))
    }
    .modelContainer(.preview)
}
