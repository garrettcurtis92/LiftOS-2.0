import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routine: Routine

    @State private var showingExercisePicker = false
    @State private var exerciseToDelete: RoutineExercise? = nil
    @State private var showingDeleteConfirm = false
    @State private var showSyncPrompt = false
    @State private var pendingSyncAction: (() -> Void)? = nil
    @State private var pendingExercise: Exercise? = nil
    @State private var showExerciseConfig = false
    @State private var showEditRoutine = false

    private var isWeekOne: Bool {
        PlanSyncService.isWeekOne(routine)
    }

    var body: some View {
        List {
            ForEach(routine.sortedExercises) { routineExercise in
                RoutineExerciseSection(routineExercise: routineExercise) {
                    exerciseToDelete = routineExercise
                    showingDeleteConfirm = true
                }
            }
            .onMove(perform: moveExercises)

            Section {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showEditRoutine = true
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                    .accessibilityLabel("Edit Routine")
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showEditRoutine) {
            EditRoutineSheet(routine: routine)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingExercisePicker, onDismiss: {
            if pendingExercise != nil {
                showExerciseConfig = true
            }
        }) {
            ExercisePickerView { exercise in
                pendingExercise = exercise
                showingExercisePicker = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showExerciseConfig) {
            if let exercise = pendingExercise {
                ExerciseConfigSheet(exercise: exercise) { sets, repMin, repMax, weight in
                    addExercise(exercise, sets: sets, repMin: repMin, repMax: repMax, weight: weight)
                    pendingExercise = nil
                }
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
            }
        }
        .confirmationDialog(
            "Remove \(exerciseToDelete?.exercise?.name ?? "Exercise")?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let ex = exerciseToDelete {
                    deleteExercise(ex)
                }
            }
        }
        .confirmationDialog("Apply to other weeks?", isPresented: $showSyncPrompt) {
            Button("All weeks") {
                pendingSyncAction?()
                syncToOtherWeeks()
                pendingSyncAction = nil
            }
            Button("This week only") {
                pendingSyncAction?()
                pendingSyncAction = nil
            }
            Button("Cancel", role: .cancel) { pendingSyncAction = nil }
        } message: {
            Text("Apply this change to all weeks, or just this week?")
        }
        .onDisappear {
            // When leaving Week 1 editor, auto-sync to all weeks
            if isWeekOne, let plan = routine.week?.plan {
                PlanSyncService.syncExercises(from: routine, across: plan, context: modelContext)
            }
        }
    }

    private func addExercise(_ exercise: Exercise, sets: Int = 3, repMin: Int = 8, repMax: Int? = 12, weight: Double? = nil) {
        let routineExercise = RoutineExercise(
            sortOrder: routine.exercises.count,
            restSeconds: 120
        )
        routineExercise.exercise = exercise
        routineExercise.routine = routine

        for i in 1...sets {
            let set = RoutineSet(
                setNumber: i,
                targetReps: repMin,
                targetRepRangeMax: repMax,
                targetWeight: weight
            )
            set.routineExercise = routineExercise
            routineExercise.sets.append(set)
        }

        routine.exercises.append(routineExercise)

        // Week 1 auto-syncs on disappear; other weeks prompt
        if !isWeekOne {
            pendingSyncAction = {}
            showSyncPrompt = true
        }
    }

    private func deleteExercise(_ routineExercise: RoutineExercise) {
        routine.exercises.removeAll { $0.id == routineExercise.id }
        modelContext.delete(routineExercise)
        reindexSortOrder()

        if !isWeekOne {
            pendingSyncAction = {}
            showSyncPrompt = true
        }
    }

    private func syncToOtherWeeks() {
        guard let plan = routine.week?.plan else { return }
        PlanSyncService.syncExercises(from: routine, across: plan, context: modelContext)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = routine.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() {
            exercise.sortOrder = index
        }
    }

    private func reindexSortOrder() {
        for (index, exercise) in routine.sortedExercises.enumerated() {
            exercise.sortOrder = index
        }
    }
}

struct RoutineExerciseSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routineExercise: RoutineExercise
    let onDelete: () -> Void

    @State private var isExpanded = true

    var body: some View {
        Section {
            // Sets
            if isExpanded {
                ForEach(routineExercise.sortedSets) { set in
                    SetConfigRow(set: set)
                }
                .onDelete { offsets in
                    deleteSets(at: offsets)
                }

                Button {
                    addSet()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
        } header: {
            exerciseHeader
        }
    }

    private var exerciseHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    if let exercise = routineExercise.exercise {
                        Image(systemName: exercise.muscleGroup.symbolName)
                            .foregroundStyle(exercise.muscleGroup.accentColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(exercise.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("\(routineExercise.sets.count) sets · \(restLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Exercise", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    private var restLabel: String {
        guard let rest = routineExercise.restSeconds else { return "No rest" }
        if rest >= 60 {
            let mins = rest / 60
            let secs = rest % 60
            return secs == 0 ? "\(mins)m rest" : "\(mins)m \(secs)s rest"
        }
        return "\(rest)s rest"
    }

    private func addSet() {
        let nextNumber = (routineExercise.sortedSets.last?.setNumber ?? 0) + 1
        let lastSet = routineExercise.sortedSets.last
        let set = RoutineSet(
            setNumber: nextNumber,
            targetReps: lastSet?.targetReps ?? 8,
            targetRepRangeMax: lastSet?.targetRepRangeMax,
            targetWeight: lastSet?.targetWeight
        )
        set.routineExercise = routineExercise
        routineExercise.sets.append(set)
    }

    private func deleteSets(at offsets: IndexSet) {
        let sorted = routineExercise.sortedSets
        for index in offsets {
            let set = sorted[index]
            routineExercise.sets.removeAll { $0.id == set.id }
            modelContext.delete(set)
        }
        // Reindex set numbers
        for (index, set) in routineExercise.sortedSets.enumerated() {
            set.setNumber = index + 1
        }
    }
}

struct SetConfigRow: View {
    @Bindable var set: RoutineSet

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(set.setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            // Reps range
            HStack(spacing: 4) {
                TextField("8", value: $set.targetReps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 36)
                    .monospacedDigit()

                Text("–")
                    .foregroundStyle(.tertiary)

                TextField("12", value: $set.targetRepRangeMax, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 36)
                    .monospacedDigit()

                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Target weight (optional)
            HStack(spacing: 4) {
                TextField("Weight", value: $set.targetWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .monospacedDigit()
                Text("lbs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Exercise Config Sheet

struct ExerciseConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let onAdd: (_ sets: Int, _ repMin: Int, _ repMax: Int?, _ weight: Double?) -> Void

    @State private var numberOfSets = 3
    @State private var repMin = 8
    @State private var repMax = 12
    @State private var useRepRange = true
    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: exercise.muscleGroup.symbolName)
                            .foregroundStyle(exercise.muscleGroup.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.headline)
                            Text(exercise.equipmentType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Sets") {
                    Stepper("**\(numberOfSets)** sets", value: $numberOfSets, in: 1...10)
                }

                Section {
                    Toggle("Use rep range", isOn: $useRepRange)

                    HStack {
                        Text("Min reps")
                        Spacer()
                        TextField("8", value: $repMin, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .monospacedDigit()
                    }

                    if useRepRange {
                        HStack {
                            Text("Max reps")
                            Spacer()
                            TextField("12", value: $repMax, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Rep Range")
                } footer: {
                    if useRepRange {
                        Text("Each set will target \(repMin)–\(repMax) reps.")
                    } else {
                        Text("Each set will target \(repMin) reps.")
                    }
                }

                Section {
                    HStack {
                        Text("Starting weight")
                        Spacer()
                        TextField("Optional", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .monospacedDigit()
                        Text("lbs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Leave blank to set weight later or let progression fill it in.")
                }
            }
            .navigationTitle("Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let weight = Double(weightText)
                        onAdd(
                            numberOfSets,
                            repMin,
                            useRepRange ? repMax : nil,
                            weight
                        )
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let container = ModelContainer.preview
    let routine = Routine(name: "Push Day A")
    container.mainContext.insert(routine)
    return NavigationStack {
        RoutineEditorView(routine: routine)
    }
    .modelContainer(container)
}
