import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var routine: Routine

    @State private var showingExercisePicker = false
    @State private var exerciseToDelete: RoutineExercise? = nil
    @State private var showingDeleteConfirm = false

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
            EditButton()
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
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
    }

    private func addExercise(_ exercise: Exercise) {
        let routineExercise = RoutineExercise(
            sortOrder: routine.exercises.count,
            restSeconds: 120
        )
        routineExercise.exercise = exercise
        routineExercise.routine = routine

        // Add 3 default sets
        for i in 1...3 {
            let set = RoutineSet(setNumber: i, targetReps: 8, targetRepRangeMax: 12)
            set.routineExercise = routineExercise
            routineExercise.sets.append(set)
        }

        routine.exercises.append(routineExercise)
    }

    private func deleteExercise(_ routineExercise: RoutineExercise) {
        routine.exercises.removeAll { $0.id == routineExercise.id }
        modelContext.delete(routineExercise)
        reindexSortOrder()
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

#Preview {
    let container = ModelContainer.preview
    let routine = Routine(name: "Push Day A")
    container.mainContext.insert(routine)
    return NavigationStack {
        RoutineEditorView(routine: routine)
    }
    .modelContainer(container)
}
