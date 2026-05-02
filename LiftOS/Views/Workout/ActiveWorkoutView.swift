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
    @State private var showDiscardConfirmation = false
    @State private var showSummary = false
    @State private var expandedExerciseID: UUID?
    @State private var restTimerExercise: SessionExercise?
    @State private var restTimerSeconds: Int = 0
    @Query private var profiles: [UserProfile]
    @State private var showSwapPicker = false
    @State private var exerciseToSwap: SessionExercise?
    @State private var exerciseToRemove: SessionExercise?
    @State private var showRemoveConfirmation = false
    @State private var addExerciseTrigger = false
    @State private var finishTrigger = false
    @State private var autoRestTimer = true
    @State private var editMode: EditMode = .inactive
    @State private var reorderTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            workoutHeader

            List {
                Section {
                    ForEach(session.sortedExercises) { sessionExercise in
                        ExerciseLogCard(
                            sessionExercise: sessionExercise,
                            previousSets: previousSets(for: sessionExercise),
                            isExpanded: expandedExerciseID == sessionExercise.id,
                            onToggle: { toggleExpanded(sessionExercise) },
                            onSetCompleted: { handleSetCompleted(sessionExercise) },
                            onRemove: {
                                exerciseToRemove = sessionExercise
                                showRemoveConfirmation = true
                            },
                            onSwap: {
                                exerciseToSwap = sessionExercise
                                showSwapPicker = true
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onMove { source, destination in
                        SessionExercise.reorder(session.sortedExercises, from: source, to: destination)
                        reorderTrigger.toggle()
                    }
                }

                if !editMode.isEditing {
                    Section {
                        addExerciseButton
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
            .sensoryFeedback(.success, trigger: reorderTrigger)
            .onChange(of: editMode.isEditing) { _, isEditing in
                if isEditing {
                    expandedExerciseID = nil
                }
            }

            bottomBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .destructive) {
                    showDiscardConfirmation = true
                }
                .disabled(editMode.isEditing)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                let _ = SessionBuilder.addExercise(exercise, to: session)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showSummary) {
            WorkoutSummaryView(session: session, routine: session.routine) {
                dismiss()
            }
            .presentationDetents([.large])
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showSwapPicker) {
            ExercisePickerView { newExercise in
                if let target = exerciseToSwap {
                    swapExercise(target, with: newExercise)
                }
                exerciseToSwap = nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .confirmationDialog(
            "Remove \(exerciseToRemove?.exercise?.name ?? "Exercise")?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let target = exerciseToRemove {
                    removeExercise(target)
                }
                exerciseToRemove = nil
            }
        } message: {
            Text("This will remove the exercise and all its sets from this workout.")
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
        .confirmationDialog("Finish Workout?", isPresented: $showFinishConfirmation) {
            Button("Finish") { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            let completed = session.exercises.reduce(0) { $0 + $1.completedSets.count }
            let total = session.totalSets
            Text("You've completed \(completed) of \(total) sets. Save this workout?")
        }
        .confirmationDialog("End Workout?", isPresented: $showDiscardConfirmation) {
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
        HStack {
            Spacer()

            VStack(spacing: 4) {
                Text(session.routine?.name ?? "Quick Workout")
                    .font(.headline)

                Text(formattedElapsed)
                    .font(.system(.title2, design: .monospaced, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                autoRestTimer.toggle()
            } label: {
                Image(systemName: autoRestTimer ? "timer" : "timer.slash")
                    .font(.body.weight(.medium))
                    .foregroundStyle(autoRestTimer ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .sensoryFeedback(.selection, trigger: autoRestTimer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        Button {
            showFinishConfirmation = true
            finishTrigger.toggle()
        } label: {
            Text("Finish Workout")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .sensoryFeedback(.success, trigger: finishTrigger)
    }

    // MARK: - Add Exercise

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
            addExerciseTrigger.toggle()
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: addExerciseTrigger)
    }

    // MARK: - Actions

    private func toggleExpanded(_ exercise: SessionExercise) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedExerciseID = expandedExerciseID == exercise.id ? nil : exercise.id
        }
    }

    private func handleSetCompleted(_ sessionExercise: SessionExercise) {
        guard autoRestTimer else { return }
        let restSeconds = findRestSeconds(for: sessionExercise)
        if restSeconds > 0 {
            restTimerExercise = sessionExercise
            restTimerSeconds = restSeconds
        }
    }

    private func previousSets(for sessionExercise: SessionExercise) -> [Int: String] {
        guard let exercise = sessionExercise.exercise else { return [:] }
        let exerciseID = exercise.id
        let predicate = #Predicate<SessionExercise> {
            $0.exercise?.id == exerciseID
        }
        var descriptor = FetchDescriptor<SessionExercise>(predicate: predicate)
        descriptor.fetchLimit = 10

        guard let results = try? modelContext.fetch(descriptor) else { return [:] }

        let previous = results
            .filter { se in
                guard let completed = se.session?.completedAt else { return false }
                return completed < session.startedAt
            }
            .sorted { ($0.session?.completedAt ?? .distantPast) > ($1.session?.completedAt ?? .distantPast) }
            .first

        guard let previous else { return [:] }

        var map: [Int: String] = [:]
        for set in previous.sortedSets where set.isCompleted {
            map[set.setNumber] = set.displayString
        }
        return map
    }

    private var defaultRestSeconds: Int {
        profiles.first?.defaultRestSeconds ?? 120
    }

    private func findRestSeconds(for sessionExercise: SessionExercise) -> Int {
        guard let routine = session.routine,
              let exercise = sessionExercise.exercise else {
            return defaultRestSeconds
        }
        let match = routine.sortedExercises.first {
            $0.exercise?.id == exercise.id
        }
        return match?.restSeconds ?? defaultRestSeconds
    }

    private func removeExercise(_ sessionExercise: SessionExercise) {
        session.exercises.removeAll { $0.id == sessionExercise.id }
        modelContext.delete(sessionExercise)
        if expandedExerciseID == sessionExercise.id {
            expandedExerciseID = nil
        }
        // Reindex sort orders
        for (index, ex) in session.sortedExercises.enumerated() {
            ex.sortOrder = index
        }
    }

    private func swapExercise(_ sessionExercise: SessionExercise, with newExercise: Exercise) {
        sessionExercise.exercise = newExercise
        // Reset uncompleted sets
        for set in sessionExercise.sets where !set.isCompleted {
            set.weight = 0
            set.reps = 0
        }
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
            Task { @MainActor in
                elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
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
    @Environment(\.modelContext) private var modelContext
    @Bindable var sessionExercise: SessionExercise
    let previousSets: [Int: String]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSetCompleted: () -> Void
    let onRemove: () -> Void
    let onSwap: () -> Void

    @State private var expandTrigger = false

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                exerciseHeader
                    .contentShape(Rectangle())
                    .onTapGesture {
                        expandTrigger.toggle()
                        onToggle()
                    }
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.4), trigger: expandTrigger)

                if isExpanded {
                    Divider()
                        .padding(.vertical, 8)

                    setHeader

                    ForEach(sessionExercise.sortedSets) { sessionSet in
                        SetLogRow(
                            sessionSet: sessionSet,
                            allSets: sessionExercise.sortedSets,
                            previousDisplay: previousSets[sessionSet.setNumber],
                            onCompleted: onSetCompleted,
                            onDelete: sessionExercise.sets.count > 1 ? {
                                deleteSet(sessionSet)
                            } : nil
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

            Menu {
                Button {
                    onSwap()
                } label: {
                    Label("Swap Exercise", systemImage: "arrow.triangle.2.circlepath")
                }
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove Exercise", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }

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

    private func deleteSet(_ sessionSet: SessionSet) {
        withAnimation(.easeOut(duration: 0.2)) {
            sessionExercise.sets.removeAll { $0.id == sessionSet.id }
            modelContext.delete(sessionSet)
            // Reindex set numbers
            for (index, set) in sessionExercise.sortedSets.enumerated() {
                set.setNumber = index + 1
            }
        }
    }

    @State private var addSetTrigger = false

    private var addSetButton: some View {
        Button {
            let newSet = SessionSet(setNumber: sessionExercise.sets.count + 1)
            newSet.sessionExercise = sessionExercise
            sessionExercise.sets.append(newSet)
            addSetTrigger.toggle()
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.subheadline)
        }
        .buttonStyle(.borderless)
        .padding(.top, 8)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: addSetTrigger)
    }
}

// MARK: - Set Log Row

struct SetLogRow: View {
    @Bindable var sessionSet: SessionSet
    let allSets: [SessionSet]
    let previousDisplay: String?
    let onCompleted: () -> Void
    var onDelete: (() -> Void)?

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var focusedField: Field?

    enum Field { case weight, reps }

    @State private var showRIR = false
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var rowFlash = false
    @State private var completionTrigger = false
    @State private var uncheckTrigger = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteButton = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .trailing) {
                // Delete button revealed on swipe
                if onDelete != nil {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 36)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .opacity(showDeleteButton ? 1 : 0)
                }

                HStack {
                    // Set number — tap to toggle warmup
                    Button {
                        sessionSet.isWarmup.toggle()
                    } label: {
                        Text(sessionSet.isWarmup ? "W" : "\(sessionSet.setNumber)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(sessionSet.isWarmup ? .orange : .primary)
                            .frame(width: 36, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: sessionSet.isWarmup)

                    // Previous session
                    Text(previousDisplay ?? "–")
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
                        .onChange(of: focusedField) { oldFocus, newFocus in
                            if oldFocus == .weight && newFocus != .weight && sessionSet.weight > 0 {
                                autoFillWeight(sessionSet.weight)
                            }
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
                            .scaleEffect(checkmarkScale)
                    }
                    .buttonStyle(.borderless)
                    .frame(width: 36)
                    .sensoryFeedback(.success, trigger: completionTrigger)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: uncheckTrigger)
                }
                .offset(x: swipeOffset)
                .background(rowFlash ? Color.green.opacity(0.08) : Color.clear)
                .gesture(
                    onDelete != nil ?
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                swipeOffset = max(value.translation.width, -70)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if value.translation.width < -40 {
                                    swipeOffset = -70
                                    showDeleteButton = true
                                } else {
                                    swipeOffset = 0
                                    showDeleteButton = false
                                }
                            }
                        }
                    : nil
                )
            }

            // RIR selector — shown after set is completed
            if showRIR && sessionSet.isCompleted {
                HStack(spacing: 6) {
                    Text("RIR")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(0...5, id: \.self) { value in
                        Button {
                            sessionSet.rir = value
                            withAnimation(.easeOut(duration: 0.2)) { showRIR = false }
                        } label: {
                            Text("\(value)")
                                .font(.caption.weight(.medium))
                                .frame(width: 32, height: 28)
                                .background(sessionSet.rir == value ? Color.accentColor : Color.secondarySystemBackground)
                                .foregroundStyle(sessionSet.rir == value ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .sensoryFeedback(.selection, trigger: sessionSet.rir)
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { showRIR = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                .padding(.leading, 36)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            weightText = sessionSet.weight > 0 ? formatWeight(sessionSet.weight) : ""
            repsText = sessionSet.reps > 0 ? "\(sessionSet.reps)" : ""
        }
        .onChange(of: sessionSet.weight) { _, newWeight in
            if focusedField != .weight {
                weightText = newWeight > 0 ? formatWeight(newWeight) : ""
            }
        }
    }

    private func autoFillWeight(_ weight: Double) {
        for set in allSets where set.setNumber > sessionSet.setNumber {
            if set.weight == 0 && !set.isCompleted {
                set.weight = weight
            }
        }
    }

    private func toggleCompletion() {
        if sessionSet.isCompleted {
            // Un-check
            sessionSet.completedAt = nil
            sessionSet.rir = nil
            withAnimation(.easeOut(duration: 0.2)) { showRIR = false }
            uncheckTrigger.toggle()
        } else {
            // Complete — bounce + flash + haptic
            sessionSet.completedAt = Date()
            focusedField = nil
            completionTrigger.toggle()

            // Checkmark scale bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkmarkScale = 0.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 1.0
                }
            }

            // Row flash
            withAnimation(.easeIn(duration: 0.1)) { rowFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) { rowFlash = false }
            }

            withAnimation(.easeOut(duration: 0.25)) { showRIR = true }
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
