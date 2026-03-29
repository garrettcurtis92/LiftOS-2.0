import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let onSelect: (Exercise) -> Void

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesMuscle = selectedMuscleGroup == nil || exercise.muscleGroup == selectedMuscleGroup
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            return matchesMuscle && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                muscleGroupPicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                List {
                    ForEach(MuscleGroup.allCases) { group in
                        let groupExercises = filtered.filter { $0.muscleGroup == group }
                        if !groupExercises.isEmpty {
                            Section(group.displayName) {
                                ForEach(groupExercises) { exercise in
                                    Button {
                                        onSelect(exercise)
                                        dismiss()
                                    } label: {
                                        ExerciseRowView(exercise: exercise)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var muscleGroupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedMuscleGroup == nil) {
                    selectedMuscleGroup = nil
                }
                ForEach(MuscleGroup.allCases) { group in
                    FilterChip(label: group.displayName, isSelected: selectedMuscleGroup == group) {
                        selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondarySystemBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

extension Color {
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
}

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(.preview)
}
