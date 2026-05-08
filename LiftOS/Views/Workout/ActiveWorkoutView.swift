import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var session: WorkoutSession

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
    @State private var previousSetsCache: [UUID: [Int: String]] = [:]

    var body: some View {
        VStack(spacing: 0) {
            workoutHeader

            List {
                Section {
                    ForEach(session.sortedExercises) { sessionExercise in
                        ExerciseLogCard(
                            sessionExercise: sessionExercise,
                            previousSets: previousSetsCache[sessionExercise.id] ?? [:],
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
        .task {
            refreshPreviousSets()
        }
        .onChange(of: session.exercises.count) { _, _ in
            refreshPreviousSets()
        }
    }

    // MARK: - Header

    private var workoutHeader: some View {
        HStack {
            Spacer()

            VStack(spacing: 4) {
                Text(session.routine?.name ?? "Quick Workout")
                    .font(.headline)

                TimerLabel(startedAt: session.startedAt)
            }

            Spacer()

            Button {
                autoRestTimer.toggle()
            } label: {
                Image(systemName: autoRestTimer ? "timer" : "timer.slash")
                    .font(.body.weight(.medium))
                    .foregroundStyle(autoRestTimer ? LiftTheme.accent : .secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, LiftTheme.cardSpacing)
            .accessibilityLabel("Auto rest timer")
            .accessibilityValue(autoRestTimer ? "On" : "Off")
            .accessibilityHint("Double-tap to toggle automatic rest timer between sets")
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
        withAnimation(Animation.liftEaseInOut(duration: 0.2, reduceMotion: reduceMotion)) {
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

    private func refreshPreviousSets() {
        var newCache: [UUID: [Int: String]] = [:]
        for sessionExercise in session.sortedExercises {
            newCache[sessionExercise.id] = computePreviousSets(for: sessionExercise)
        }
        previousSetsCache = newCache
    }

    private func computePreviousSets(for sessionExercise: SessionExercise) -> [Int: String] {
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
        for set in sessionExercise.sets where !set.isCompleted {
            set.weight = 0
            set.reps = 0
        }
        refreshPreviousSets()
    }

    private func finishWorkout() {
        session.completedAt = Date()
        showSummary = true
    }

}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                        .padding(.vertical, LiftTheme.compactSpacing)

                    if !dynamicTypeSize.isAccessibilitySize {
                        setHeader
                    }

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
                    .foregroundStyle(LiftTheme.accent)
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
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Exercise options")
            .accessibilityHint("Swap or remove this exercise")

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
                .accessibilityHidden(true)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.bottom, LiftTheme.listItemSpacing)
        .accessibilityHidden(true)
    }

    private func deleteSet(_ sessionSet: SessionSet) {
        withAnimation(Animation.liftEaseOut(duration: 0.2, reduceMotion: reduceMotion)) {
            sessionExercise.sets.removeAll { $0.id == sessionSet.id }
            modelContext.delete(sessionSet)
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
        .padding(.top, LiftTheme.compactSpacing)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: addSetTrigger)
    }
}

// MARK: - Set Log Row

struct SetLogRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
    @State private var completionAnimationStep: Int = 0
    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteButton = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .trailing) {
                swipeDeleteButton
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityRow
                } else {
                    mainRow
                }
            }

            if showRIR && sessionSet.isCompleted {
                rirSelector
            }
        }
        .padding(.vertical, LiftTheme.listItemSpacing)
        .accessibilityActions { rowAccessibilityActions }
        .onAppear {
            weightText = sessionSet.weight > 0 ? formatWeight(sessionSet.weight) : ""
            repsText = sessionSet.reps > 0 ? "\(sessionSet.reps)" : ""
        }
        .onChange(of: sessionSet.weight) { _, newWeight in
            if focusedField != .weight {
                weightText = newWeight > 0 ? formatWeight(newWeight) : ""
            }
        }
        .task(id: completionAnimationStep) {
            guard completionAnimationStep > 0 else { return }

            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            withAnimation(Animation.liftBounce(reduceMotion: reduceMotion)) {
                checkmarkScale = 1.0
            }

            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled, rowFlash else { return }
            withAnimation(Animation.liftEaseOut(duration: 0.3, reduceMotion: reduceMotion)) {
                rowFlash = false
            }
        }
    }

    @ViewBuilder
    private var swipeDeleteButton: some View {
        if onDelete != nil {
            Button {
                onDelete?()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 36)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius))
            }
            .buttonStyle(.plain)
            .opacity(showDeleteButton ? 1 : 0)
        }
    }

    private var mainRow: some View {
        HStack {
            setNumberButton
            previousLabel
            weightField.frame(width: 72)
            repsField.frame(width: 56)
            completionButton
        }
        .offset(x: swipeOffset)
        .background(rowFlash ? LiftTheme.success.opacity(0.08) : Color.clear)
        .gesture(swipeGesture)
    }

    private var accessibilityRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                setNumberButton
                Spacer()
                completionButton
            }

            if previousDisplay != nil {
                HStack(spacing: 6) {
                    Text("Last:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(previousDisplay ?? "")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(alignment: .bottom, spacing: 12) {
                labeledField("Weight", field: weightField)
                labeledField("Reps", field: repsField)
            }
        }
        .offset(x: swipeOffset)
        .background(rowFlash ? LiftTheme.success.opacity(0.08) : Color.clear)
        .gesture(swipeGesture)
    }

    private func labeledField<Field: View>(_ label: String, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            field.frame(maxWidth: .infinity)
        }
    }

    private var setNumberButton: some View {
        Button {
            sessionSet.isWarmup.toggle()
        } label: {
            Text(sessionSet.isWarmup ? "W" : "\(sessionSet.setNumber)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(sessionSet.isWarmup ? LiftTheme.warmup : .primary)
                .frame(width: 36, alignment: .leading)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set \(sessionSet.setNumber)")
        .accessibilityValue(sessionSet.isWarmup ? "Warmup" : "Working set")
        .accessibilityHint("Double-tap to toggle warmup")
        .sensoryFeedback(.selection, trigger: sessionSet.isWarmup)
    }

    private var previousLabel: some View {
        Text(previousDisplay ?? "–")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var weightField: some View {
        TextField("0", text: $weightText)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .font(.body.weight(.medium))
            .padding(.vertical, 6)
            .background(LiftTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius))
            .focused($focusedField, equals: .weight)
            .accessibilityLabel("Weight")
            .onChange(of: weightText) { _, newValue in
                sessionSet.weight = Double(newValue) ?? 0
            }
            .onChange(of: focusedField) { oldFocus, newFocus in
                if oldFocus == .weight && newFocus != .weight && sessionSet.weight > 0 {
                    autoFillWeight(sessionSet.weight)
                }
            }
    }

    private var repsField: some View {
        TextField("0", text: $repsText)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.body.weight(.medium))
            .padding(.vertical, 6)
            .background(LiftTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius))
            .focused($focusedField, equals: .reps)
            .accessibilityLabel("Reps")
            .onChange(of: repsText) { _, newValue in
                sessionSet.reps = Int(newValue) ?? 0
            }
    }

    private var completionButton: some View {
        Button {
            toggleCompletion()
        } label: {
            Image(systemName: sessionSet.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(sessionSet.isCompleted ? LiftTheme.success : .secondary)
                .scaleEffect(checkmarkScale)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Set \(sessionSet.setNumber)")
        .accessibilityValue(sessionSet.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double-tap to toggle completion")
        .sensoryFeedback(.success, trigger: completionTrigger)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: uncheckTrigger)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard onDelete != nil, value.translation.width < 0 else { return }
                swipeOffset = max(value.translation.width, -70)
            }
            .onEnded { value in
                guard onDelete != nil else { return }
                withAnimation(Animation.liftEaseOut(duration: 0.2, reduceMotion: reduceMotion)) {
                    if value.translation.width < -40 {
                        swipeOffset = -70
                        showDeleteButton = true
                    } else {
                        swipeOffset = 0
                        showDeleteButton = false
                    }
                }
            }
    }

    @ViewBuilder
    private var rirSelector: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityRIRSelector
        } else {
            compactRIRSelector
        }
    }

    private var compactRIRSelector: some View {
        HStack(spacing: 6) {
            Text("RIR")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(0...5, id: \.self) { value in
                rirChip(for: value)
            }
            .sensoryFeedback(.selection, trigger: sessionSet.rir)
            Spacer()
            rirCloseButton
        }
        .padding(.top, LiftTheme.listItemSpacing)
        .padding(.leading, 36)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var accessibilityRIRSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RIR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                rirCloseButton
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0...5, id: \.self) { value in
                        rirChip(for: value)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: sessionSet.rir)
        }
        .padding(.top, LiftTheme.listItemSpacing)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func rirChip(for value: Int) -> some View {
        Button {
            sessionSet.rir = value
            withAnimation(Animation.liftEaseOut(duration: 0.2, reduceMotion: reduceMotion)) { showRIR = false }
        } label: {
            Text("\(value)")
                .font(.caption.weight(.medium))
                .frame(width: 32, height: 28)
                .background(sessionSet.rir == value ? LiftTheme.accent : LiftTheme.cardBackground)
                .foregroundStyle(sessionSet.rir == value ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("RIR \(value)")
        .accessibilityHint("Reps in reserve. Double-tap to record.")
    }

    private var rirCloseButton: some View {
        Button {
            withAnimation(Animation.liftEaseOut(duration: 0.2, reduceMotion: reduceMotion)) { showRIR = false }
        } label: {
            Image(systemName: "xmark")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close RIR selector")
    }

    @ViewBuilder
    private var rowAccessibilityActions: some View {
        Button(sessionSet.isCompleted ? "Mark not completed" : "Mark completed") {
            toggleCompletion()
        }
        Button(sessionSet.isWarmup ? "Mark working set" : "Mark as warmup") {
            sessionSet.isWarmup.toggle()
        }
        if let onDelete {
            Button("Delete set", role: .destructive) {
                onDelete()
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
            sessionSet.completedAt = nil
            sessionSet.rir = nil
            withAnimation(Animation.liftEaseOut(duration: 0.2, reduceMotion: reduceMotion)) { showRIR = false }
            uncheckTrigger.toggle()
        } else {
            sessionSet.completedAt = Date()
            focusedField = nil
            completionTrigger.toggle()

            withAnimation(Animation.liftBounce(reduceMotion: reduceMotion)) {
                checkmarkScale = 0.5
            }
            withAnimation(Animation.liftEaseOut(duration: 0.1, reduceMotion: reduceMotion)) { rowFlash = true }
            withAnimation(Animation.liftEaseOut(duration: 0.25, reduceMotion: reduceMotion)) { showRIR = true }

            completionAnimationStep += 1
            onCompleted()
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}

// MARK: - Timer Label

struct TimerLabel: View {
    let startedAt: Date

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    var body: some View {
        Text(formattedElapsed)
            .font(.system(.title2, design: .monospaced, weight: .medium))
            .foregroundStyle(.secondary)
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
    }

    private func startTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(startedAt))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds = Int(Date().timeIntervalSince(startedAt))
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

#Preview {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(isQuickWorkout: true))
    }
    .modelContainer(.preview)
}
