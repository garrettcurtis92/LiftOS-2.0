import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession
    let routine: Routine?
    let onDismiss: () -> Void

    @State private var showUpdatePrompt = false
    @State private var hasCheckedChanges = false
    @State private var notesText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    statsGrid
                    notesSection
                    exerciseBreakdown
                }
                .padding()
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if !hasCheckedChanges && routineChanged {
                            hasCheckedChanges = true
                            showUpdatePrompt = true
                        } else {
                            onDismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Update Routine?", isPresented: $showUpdatePrompt) {
                Button("Update Routine") {
                    applyChangesToRoutine()
                    onDismiss()
                }
                Button("Keep as One-Off") {
                    onDismiss()
                }
                Button("Cancel", role: .cancel) { hasCheckedChanges = false }
            } message: {
                Text("Your workout had different exercises than the routine. Update the routine to match?")
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextField("How did it go?", text: $notesText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)
                .onChange(of: notesText) { _, newValue in
                    session.notes = newValue.isEmpty ? nil : newValue
                }
        }
    }

    // MARK: - Change Detection

    private var routineChanged: Bool {
        guard let routine else { return false }

        let routineExerciseIDs = Set(routine.sortedExercises.compactMap { $0.exercise?.id })
        let sessionExerciseIDs = Set(session.sortedExercises.compactMap { $0.exercise?.id })

        return routineExerciseIDs != sessionExerciseIDs
    }

    // MARK: - Apply Changes

    private func applyChangesToRoutine() {
        guard let routine else { return }

        // Remove existing exercises from routine
        for existing in routine.exercises {
            modelContext.delete(existing)
        }
        routine.exercises.removeAll()

        // Rebuild from session exercises
        for (index, sessionExercise) in session.sortedExercises.enumerated() {
            guard let exercise = sessionExercise.exercise else { continue }

            let routineExercise = RoutineExercise(
                sortOrder: index,
                restSeconds: 120
            )
            routineExercise.exercise = exercise
            routineExercise.routine = routine

            // Use the session's completed sets as the new targets
            let completedSets = sessionExercise.sortedSets.filter { $0.isCompleted && !$0.isWarmup }
            let setsToUse = completedSets.isEmpty ? sessionExercise.sortedSets : completedSets

            for (setIndex, sessionSet) in setsToUse.enumerated() {
                let routineSet = RoutineSet(
                    setNumber: setIndex + 1,
                    targetReps: sessionSet.reps > 0 ? sessionSet.reps : 8,
                    targetRepRangeMax: nil,
                    targetWeight: sessionSet.weight > 0 ? sessionSet.weight : nil
                )
                routineSet.routineExercise = routineExercise
                routineExercise.sets.append(routineSet)
            }

            routine.exercises.append(routineExercise)
        }

        // Sync to other weeks if this is Week 1
        if let plan = routine.week?.plan {
            PlanSyncService.syncExercises(from: routine, across: plan, context: modelContext)
        }
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
    WorkoutSummaryView(session: WorkoutSession(isQuickWorkout: true), routine: nil) {}
        .modelContainer(.preview)
}
