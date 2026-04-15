import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var showingNewExercise = false

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesMuscle = selectedMuscleGroup == nil || exercise.muscleGroup == selectedMuscleGroup
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            return matchesMuscle && matchesSearch
        }
    }

    @State private var selectedExercise: Exercise?

    var body: some View {
        List {
            ForEach(MuscleGroup.allCases) { group in
                let groupExercises = filtered.filter { $0.muscleGroup == group }
                if !groupExercises.isEmpty {
                    Section(group.displayName) {
                        ForEach(groupExercises) { exercise in
                            Button {
                                selectedExercise = exercise
                            } label: {
                                ExerciseRowView(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedExercise) { exercise in
            ExerciseProgressView(exercise: exercise)
        }
        .navigationTitle("Exercise Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewExercise = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                muscleGroupMenu
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            NewExerciseSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private var muscleGroupMenu: some View {
        Menu {
            Button {
                selectedMuscleGroup = nil
            } label: {
                Label("All Muscles", systemImage: selectedMuscleGroup == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(MuscleGroup.allCases) { group in
                Button {
                    selectedMuscleGroup = group
                } label: {
                    Label(
                        group.displayName,
                        systemImage: selectedMuscleGroup == group ? "checkmark" : group.symbolName
                    )
                }
            }
        } label: {
            Label(selectedMuscleGroup?.displayName ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                .labelStyle(.iconOnly)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscleGroup.symbolName)
                .foregroundStyle(exercise.muscleGroup.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body)
                Text(exercise.equipmentType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if exercise.isCustom {
                Text("Custom")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

struct NewExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var equipmentType: EquipmentType = .barbell

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Info") {
                    TextField("Exercise name", text: $name)
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                    Picker("Equipment", selection: $equipmentType) {
                        ForEach(EquipmentType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        modelContext.insert(Exercise(
                            name: trimmed,
                            muscleGroup: muscleGroup,
                            equipmentType: equipmentType,
                            isCustom: true
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

extension MuscleGroup {
    var accentColor: Color {
        switch self {
        case .chest: return .blue
        case .back: return .green
        case .shoulders: return .orange
        case .quads: return .purple
        case .hamstrings: return .red
        case .glutes: return .pink
        case .arms: return .yellow
        case .core: return .cyan
        case .fullBody: return .indigo
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
    .modelContainer(.preview)
}
