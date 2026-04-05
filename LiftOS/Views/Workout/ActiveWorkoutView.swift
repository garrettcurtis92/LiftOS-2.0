import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var showExercisePicker = false
    @State private var showFinishConfirmation = false
    @State private var showSummary = false
    @State private var expandedExerciseID: UUID?
    @State private var restTimerExercise: SessionExercise?
    @State private var restTimerSeconds: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            workoutHeader

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(session.sortedExercises) { sessionExercise in
                        ExerciseLogCard(
                            sessionExercise: sessionExercise,
                            isExpanded: expandedExerciseID == sessionExercise.id,
                            onToggle: { toggleExpanded(sessionExercise) },
                            onSetCompleted: { handleSetCompleted(sessionExercise) }
                        )
                    }

                    addExerciseButton
                }
                .padding()
            }

            bottomBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .destructive) {
                    showFinishConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                let _ = SessionBuilder.addExercise(exercise, to: session)
            }
        }
        .sheet(isPresented: $showSummary) {
            WorkoutSummaryView(session: session) {
                dismiss()
            }
        }
        .overlay {
            if restTimerSeconds > 0, let exercise = restTimerExercise {
                RestTimerView(
                    seconds: $restTimerSeconds,
                    exerciseName: exercise.exercise?.name ?? "Rest",
                    onDismiss: { restTimerSeconds = 0; restTimerExercise = nil }
                )
            }
        }
        .confirmationDialog("End Workout?", isPresented: $showFinishConfirmation) {
            Button("Discard Workout", role: .destructive) {
                modelContext.delete(session)
                dismiss()
            }
            Button("Keep as In-Progress") {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can resume this workout later or discard it.")
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - Header

    private var workoutHeader: some View {
        VStack(spacing: 4) {
            Text(session.routine?.name ?? "Quick Workout")
                .font(.headline)

            Text(formattedElapsed)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        Button {
            finishWorkout()
        } label: {
            Text("Finish Workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
    }

    // MARK: - Add Exercise

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: - Actions

    private func toggleExpanded(_ exercise: SessionExercise) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedExerciseID = expandedExerciseID == exercise.id ? nil : exercise.id
        }
    }

    private func handleSetCompleted(_ sessionExercise: SessionExercise) {
        let restSeconds = findRestSeconds(for: sessionExercise)
        if restSeconds > 0 {
            restTimerExercise = sessionExercise
            restTimerSeconds = restSeconds
        }
    }

    private func findRestSeconds(for sessionExercise: SessionExercise) -> Int {
        guard let routine = session.routine,
              let exercise = sessionExercise.exercise else {
            return 120
        }
        let match = routine.sortedExercises.first {
            $0.exercise?.id == exercise.id
        }
        return match?.restSeconds ?? 120
    }

    private func finishWorkout() {
        session.completedAt = Date()
        showSummary = true
    }

    // MARK: - Timer

    private func startTimer() {
        let start = session.startedAt
        elapsedSeconds = Int(Date().timeIntervalSince(start))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private var formattedElapsed: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    @Bindable var sessionExercise: SessionExercise
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSetCompleted: () -> Void

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                exerciseHeader
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onToggle)

                if isExpanded {
                    Divider()
                        .padding(.vertical, 8)

                    setHeader

                    ForEach(sessionExercise.sortedSets) { sessionSet in
                        SetLogRow(
                            sessionSet: sessionSet,
                            onCompleted: onSetCompleted
                        )
                    }

                    addSetButton
                }
            }
        }
    }

    private var exerciseHeader: some View {
        HStack {
            if let exercise = sessionExercise.exercise {
                Image(systemName: exercise.muscleGroup.symbolName)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)

                    let completed = sessionExercise.completedSets.count
                    let total = sessionExercise.sets.count
                    Text("\(completed)/\(total) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var setHeader: some View {
        HStack {
            Text("SET")
                .frame(width: 36, alignment: .leading)
            Text("PREV")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("LBS")
                .frame(width: 72, alignment: .center)
            Text("REPS")
                .frame(width: 56, alignment: .center)
            Image(systemName: "checkmark")
                .frame(width: 36)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
    }

    private var addSetButton: some View {
        Button {
            let newSet = SessionSet(setNumber: sessionExercise.sets.count + 1)
            newSet.sessionExercise = sessionExercise
            sessionExercise.sets.append(newSet)
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.subheadline)
        }
        .buttonStyle(.borderless)
        .padding(.top, 8)
    }
}

// MARK: - Set Log Row

struct SetLogRow: View {
    @Bindable var sessionSet: SessionSet
    let onCompleted: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var focusedField: Field?

    enum Field { case weight, reps }

    var body: some View {
        HStack {
            // Set number
            Text("\(sessionSet.setNumber)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(sessionSet.isWarmup ? .orange : .primary)
                .frame(width: 36, alignment: .leading)

            // Previous (placeholder)
            Text("--")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)

            // Weight input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.body.weight(.medium))
                .frame(width: 72)
                .padding(.vertical, 6)
                .background(Color.secondarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .focused($focusedField, equals: .weight)
                .onChange(of: weightText) { _, newValue in
                    sessionSet.weight = Double(newValue) ?? 0
                }

            // Reps input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body.weight(.medium))
                .frame(width: 56)
                .padding(.vertical, 6)
                .background(Color.secondarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .focused($focusedField, equals: .reps)
                .onChange(of: repsText) { _, newValue in
                    sessionSet.reps = Int(newValue) ?? 0
                }

            // Complete toggle
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: sessionSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(sessionSet.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.borderless)
            .frame(width: 36)
        }
        .padding(.vertical, 4)
        .onAppear {
            weightText = sessionSet.weight > 0 ? formatWeight(sessionSet.weight) : ""
            repsText = sessionSet.reps > 0 ? "\(sessionSet.reps)" : ""
        }
    }

    private func toggleCompletion() {
        if sessionSet.isCompleted {
            sessionSet.completedAt = nil
        } else {
            sessionSet.completedAt = Date()
            focusedField = nil
            onCompleted()
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(isQuickWorkout: true))
    }
    .modelContainer(.preview)
}
