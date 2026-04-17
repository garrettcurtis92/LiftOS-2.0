import SwiftUI
import SwiftData

struct NewPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var numberOfWeeks = 4
    @State private var useDeload = true
    @State private var deloadFrequency = 4
    @State private var deloadPercentage = 0.6
    @State private var setAsActive = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Info") {
                    TextField("e.g. Upper/Lower 4-Day", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Stepper("**\(numberOfWeeks)** weeks", value: $numberOfWeeks, in: 1...52)
                } header: {
                    Text("Duration")
                } footer: {
                    Text("You can add or remove weeks later.")
                }

                Section {
                    Toggle("Include Deload Week", isOn: $useDeload.animation())

                    if useDeload {
                        Stepper(
                            "Every **\(deloadFrequency)** weeks",
                            value: $deloadFrequency,
                            in: 2...12
                        )

                        HStack {
                            Text("Deload Intensity")
                            Spacer()
                            Text("\(Int(deloadPercentage * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $deloadPercentage, in: 0.4...0.8, step: 0.05)
                            .tint(.orange)
                    }
                } header: {
                    Text("Deload")
                } footer: {
                    if useDeload {
                        Text("Every \(deloadFrequency)th week will be marked as a deload with weights at \(Int(deloadPercentage * 100))% of working weight.")
                    }
                }

                Section {
                    Toggle("Set as Active Plan", isOn: $setAsActive)
                } footer: {
                    Text("Only one plan can be active at a time.")
                }
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createPlan() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createPlan() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Deactivate other plans if needed
        if setAsActive {
            let descriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate { $0.isActive }
            )
            let activePlans = (try? modelContext.fetch(descriptor)) ?? []
            activePlans.forEach { $0.isActive = false }
        }

        let plan = WorkoutPlan(
            name: trimmed,
            numberOfWeeks: numberOfWeeks,
            deloadFrequency: useDeload ? deloadFrequency : nil,
            deloadPercentage: useDeload ? deloadPercentage : nil,
            isActive: setAsActive
        )
        modelContext.insert(plan)

        // Create weeks
        for weekNum in 1...numberOfWeeks {
            let isDeload = useDeload && (weekNum % deloadFrequency == 0)
            let week = PlanWeek(weekNumber: weekNum, isDeloadWeek: isDeload)
            week.plan = plan
            plan.weeks.append(week)
        }

        dismiss()
    }
}

struct EditPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: WorkoutPlan

    @State private var name: String
    @State private var useDeload: Bool
    @State private var deloadFrequency: Int
    @State private var deloadPercentage: Double

    init(plan: WorkoutPlan) {
        self.plan = plan
        _name = State(initialValue: plan.name)
        _useDeload = State(initialValue: plan.deloadFrequency != nil)
        _deloadFrequency = State(initialValue: plan.deloadFrequency ?? 4)
        _deloadPercentage = State(initialValue: plan.deloadPercentage ?? 0.6)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Info") {
                    TextField("Plan name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Toggle("Include Deload Week", isOn: $useDeload.animation())
                    if useDeload {
                        Stepper("Every **\(deloadFrequency)** weeks", value: $deloadFrequency, in: 2...12)
                        HStack {
                            Text("Deload Intensity")
                            Spacer()
                            Text("\(Int(deloadPercentage * 100))%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $deloadPercentage, in: 0.4...0.8, step: 0.05)
                            .tint(.orange)
                    }
                } header: {
                    Text("Deload")
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        plan.name = name.trimmingCharacters(in: .whitespaces)
        plan.deloadFrequency = useDeload ? deloadFrequency : nil
        plan.deloadPercentage = useDeload ? deloadPercentage : nil
        dismiss()
    }
}

struct NewRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var week: PlanWeek

    @State private var name = ""
    @State private var dayOfWeek: Int? = nil

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Info") {
                    TextField("e.g. Push Day A, Legs, Upper", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "Unset", isSelected: dayOfWeek == nil) {
                                dayOfWeek = nil
                            }
                            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                                FilterChip(label: day, isSelected: dayOfWeek == index + 1) {
                                    dayOfWeek = dayOfWeek == index + 1 ? nil : index + 1
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Day of Week")
                } footer: {
                    Text("Optional — used to show today's workout on the home screen.")
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addRoutine() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addRoutine() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let routine = Routine(
            name: trimmed,
            dayOfWeek: dayOfWeek,
            sortOrder: week.routines.count
        )
        routine.week = week
        week.routines.append(routine)

        // Replicate to all other weeks in the plan
        if let plan = week.plan {
            PlanSyncService.replicateRoutine(routine, across: plan)
        }

        dismiss()
    }
}

struct EditRoutineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var routine: Routine

    @State private var name: String = ""
    @State private var dayOfWeek: Int? = nil

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Info") {
                    TextField("e.g. Push Day A, Legs, Upper", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "Unset", isSelected: dayOfWeek == nil) {
                                dayOfWeek = nil
                            }
                            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                                FilterChip(label: day, isSelected: dayOfWeek == index + 1) {
                                    dayOfWeek = dayOfWeek == index + 1 ? nil : index + 1
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Day of Week")
                }
            }
            .navigationTitle("Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = routine.name
                dayOfWeek = routine.dayOfWeek
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        routine.name = trimmed
        routine.dayOfWeek = dayOfWeek
        dismiss()
    }
}

#Preview {
    NewPlanSheet()
        .modelContainer(.preview)
}
