import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var plan: WorkoutPlan

    @State private var selectedWeekIndex = 0
    @State private var showingNewRoutine = false
    @State private var showingEditPlan = false

    private var selectedWeek: PlanWeek? {
        let sorted = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }
        guard selectedWeekIndex < sorted.count else { return sorted.first }
        return sorted[selectedWeekIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            weekSelector
                .padding(.vertical, 12)

            if let week = selectedWeek {
                routineList(for: week)
            } else {
                emptyWeekState
            }
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewRoutine = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedWeek == nil)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditPlan = true
                    } label: {
                        Label("Edit Plan", systemImage: "pencil")
                    }

                    Divider()

                    Button {
                        addWeek()
                    } label: {
                        Label("Add Week", systemImage: "plus.rectangle.on.rectangle")
                    }

                    if let week = selectedWeek {
                        Button {
                            duplicateWeek(week)
                        } label: {
                            Label("Duplicate This Week", systemImage: "doc.on.doc")
                        }

                        if plan.weeks.count > 1 {
                            Button(role: .destructive) {
                                deleteWeek(week)
                            } label: {
                                Label("Delete This Week", systemImage: "trash")
                            }
                        }
                    }

                    Divider()

                    Button {
                        toggleActiveStatus()
                    } label: {
                        Label(
                            plan.isActive ? "Deactivate Plan" : "Set as Active Plan",
                            systemImage: plan.isActive ? "stop.circle" : "play.circle"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewRoutine) {
            if let week = selectedWeek {
                NewRoutineSheet(week: week)
            }
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanSheet(plan: plan)
        }
        .confirmationDialog("Remove Routine", isPresented: $showDeleteScope) {
            Button("This week only") {
                if let routine = routineToDelete, let week = routine.week {
                    week.routines.removeAll { $0.id == routine.id }
                    modelContext.delete(routine)
                    routineToDelete = nil
                }
            }
            Button("All weeks", role: .destructive) {
                if let routine = routineToDelete, let week = routine.week {
                    PlanSyncService.removeRoutineFromOtherWeeks(
                        named: routine.name,
                        excludingWeek: week,
                        in: plan,
                        context: modelContext
                    )
                    week.routines.removeAll { $0.id == routine.id }
                    modelContext.delete(routine)
                    routineToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { routineToDelete = nil }
        } message: {
            Text("Remove \"\(routineToDelete?.name ?? "")\" from this week only, or all weeks?")
        }
    }

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let sortedWeeks = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }
                ForEach(Array(sortedWeeks.enumerated()), id: \.element.id) { index, week in
                    WeekTab(
                        week: week,
                        isSelected: selectedWeekIndex == index
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedWeekIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func routineList(for week: PlanWeek) -> some View {
        List {
            if week.isDeloadWeek {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deload Week")
                                .font(.subheadline.weight(.semibold))
                            if let pct = plan.deloadPercentage {
                                Text("Weights reduced to \(Int(pct * 100))% of working weight")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if week.sortedRoutines.isEmpty {
                Section {
                    Text("No routines yet. Tap + to add one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                Section("Routines") {
                    ForEach(week.sortedRoutines) { routine in
                        NavigationLink(value: PlanNavDestination.routine(routine.id, planID: plan.id)) {
                            RoutineRowView(routine: routine)
                        }
                    }
                    .onDelete { offsets in
                        deleteRoutines(from: week, at: offsets)
                    }
                    .onMove { from, to in
                        moveRoutines(in: week, from: from, to: to)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: week.id)
    }

    private var emptyWeekState: some View {
        ContentUnavailableView {
            Label("No Weeks", systemImage: "calendar.badge.plus")
        } description: {
            Text("Add a week to start building your plan.")
        } actions: {
            Button("Add Week") { addWeek() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func addWeek() {
        let nextNumber = (plan.weeks.map(\.weekNumber).max() ?? 0) + 1
        let isDeload = plan.deloadFrequency.map { nextNumber % $0 == 0 } ?? false
        let week = PlanWeek(weekNumber: nextNumber, isDeloadWeek: isDeload)
        week.plan = plan
        plan.weeks.append(week)

        // Copy routines from Week 1 template
        PlanSyncService.populateWeekFromTemplate(week, plan: plan)

        plan.numberOfWeeks = plan.weeks.count

        let newIndex = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }.count - 1
        withAnimation { selectedWeekIndex = newIndex }
    }

    private func duplicateWeek(_ source: PlanWeek) {
        let nextNumber = (plan.weeks.map(\.weekNumber).max() ?? 0) + 1
        let newWeek = PlanWeek(weekNumber: nextNumber, isDeloadWeek: source.isDeloadWeek)
        newWeek.plan = plan

        for routine in source.sortedRoutines {
            let newRoutine = Routine(name: routine.name, dayOfWeek: routine.dayOfWeek, sortOrder: routine.sortOrder)
            newRoutine.week = newWeek
            for re in routine.sortedExercises {
                let newRE = RoutineExercise(sortOrder: re.sortOrder, restSeconds: re.restSeconds)
                newRE.exercise = re.exercise
                newRE.routine = newRoutine
                for set in re.sortedSets {
                    let newSet = RoutineSet(
                        setNumber: set.setNumber,
                        targetReps: set.targetReps,
                        targetRepRangeMax: set.targetRepRangeMax,
                        targetWeight: set.targetWeight
                    )
                    newSet.routineExercise = newRE
                    newRE.sets.append(newSet)
                }
                newRoutine.exercises.append(newRE)
            }
            newWeek.routines.append(newRoutine)
        }

        plan.weeks.append(newWeek)
        plan.numberOfWeeks = plan.weeks.count

        let newIndex = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }.count - 1
        withAnimation { selectedWeekIndex = newIndex }
    }

    private func deleteWeek(_ week: PlanWeek) {
        plan.weeks.removeAll { $0.id == week.id }
        modelContext.delete(week)
        plan.numberOfWeeks = plan.weeks.count
        selectedWeekIndex = max(0, selectedWeekIndex - 1)
    }

    @State private var routineToDelete: Routine?
    @State private var showDeleteScope = false

    private func deleteRoutines(from week: PlanWeek, at offsets: IndexSet) {
        let sorted = week.sortedRoutines
        for index in offsets {
            let routine = sorted[index]
            if PlanSyncService.isWeekOne(routine) {
                // Week 1 deletion — remove from all weeks
                PlanSyncService.removeRoutineFromOtherWeeks(
                    named: routine.name,
                    excludingWeek: week,
                    in: plan,
                    context: modelContext
                )
                week.routines.removeAll { $0.id == routine.id }
                modelContext.delete(routine)
            } else {
                // Other week — ask scope
                routineToDelete = routine
                showDeleteScope = true
            }
        }
    }

    private func moveRoutines(in week: PlanWeek, from source: IndexSet, to destination: Int) {
        var sorted = week.sortedRoutines
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, routine) in sorted.enumerated() {
            routine.sortOrder = index
        }
    }

    private func toggleActiveStatus() {
        plan.isActive.toggle()
    }
}

struct WeekTab: View {
    let week: PlanWeek
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Week \(week.weekNumber)")
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))

                if week.isDeloadWeek {
                    Text("Deload")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(routine.name)
                    .font(.body.weight(.semibold))
                Spacer()
                if let day = routine.dayName {
                    Text(day.prefix(3))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            let exerciseCount = routine.exercises.count
            let setCount = routine.exercises.reduce(0) { $0 + $1.sets.count }
            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") · \(setCount) sets")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let container = ModelContainer.preview
    let plan = WorkoutPlan(name: "Upper/Lower 4-Day", isActive: true)
    container.mainContext.insert(plan)
    let week = PlanWeek(weekNumber: 1)
    week.plan = plan
    plan.weeks.append(week)
    return NavigationStack {
        PlanDetailView(plan: plan)
    }
    .modelContainer(container)
}
