import SwiftUI
import SwiftData

struct HomeTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutPlan> { $0.isActive }) private var activePlans: [WorkoutPlan]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt == nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    ) private var inProgressSessions: [WorkoutSession]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]

    private var activePlan: WorkoutPlan? { activePlans.first }
    private var activeSession: WorkoutSession? { inProgressSessions.first }

    @State private var navigateToSession: WorkoutSession?
    @State private var navigateToDetail: WorkoutSession?
    @State private var showStartConfirmation = false
    @State private var showQuickStartConfirmation = false
    @State private var pendingRoutine: Routine?
    @State private var startWorkoutTrigger = false
    @State private var weekAdvanceTrigger = false
    @State private var restDayToggleTrigger = false
    @State private var showProfile = false

    @AppStorage("checkedRestDays") private var checkedRestDaysJSON: String = "[]"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let activeSession {
                        activeSessionCard(activeSession)
                    }

                    if let activePlan {
                        weekIndicator(activePlan)
                        weekOverviewSection(activePlan)
                        todaysRoutineSection(activePlan)
                    } else {
                        noPlanEmptyState
                    }

                    quickWorkoutSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileTab(showDismissButton: true)
            }
            .navigationDestination(item: $navigateToSession) { session in
                ActiveWorkoutView(session: session)
            }
            .navigationDestination(item: $navigateToDetail) { session in
                WorkoutDetailView(session: session)
            }
        }
    }

    private func activeSessionCard(_ session: WorkoutSession) -> some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout In Progress")
                        .font(.headline)
                    Text("Started \(session.startedAt, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Resume") {
                    navigateToSession = session
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func weekIndicator(_ plan: WorkoutPlan) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Week \(plan.currentWeekNumber) of \(plan.numberOfWeeks)")
                    .font(.subheadline.weight(.semibold))
                if plan.currentWeek?.isDeloadWeek == true {
                    Text("Deload Week")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            if plan.currentWeekNumber < plan.numberOfWeeks {
                Button {
                    plan.currentWeekNumber += 1
                    weekAdvanceTrigger.toggle()
                } label: {
                    Label("Next Week", systemImage: "chevron.right")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: weekAdvanceTrigger)
            } else {
                Button {
                    plan.currentWeekNumber = 1
                    weekAdvanceTrigger.toggle()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: weekAdvanceTrigger)
            }
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Week Overview

    private func weekOverviewSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(1...7, id: \.self) { dayOfWeek in
                    weekDayRow(for: dayOfWeek, plan: plan)
                    if dayOfWeek < 7 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.secondarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiftTheme.cornerRadius))
        }
        .sensoryFeedback(.selection, trigger: restDayToggleTrigger)
    }

    @ViewBuilder
    private func weekDayRow(for dayOfWeek: Int, plan: WorkoutPlan) -> some View {
        let routine = routineForWeek(plan: plan, dayOfWeek: dayOfWeek)
        let isToday = (dayOfWeek == currentDayOfWeek)
        let isPast = dayOfWeek < currentDayOfWeek
        let completed = routine.flatMap { completedSessionThisWeek(for: $0) }
        let rowDate = date(forDayOfWeek: dayOfWeek)
        let restChecked = routine == nil && isRestDayChecked(rowDate)

        HStack(spacing: 0) {
            Text(dayAbbreviation(for: dayOfWeek))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isToday ? LiftTheme.accent : .secondary)
                .frame(width: 44, alignment: .leading)

            Text(routine?.name ?? "Rest")
                .font(.body.weight(isToday ? .semibold : .regular))
                .foregroundStyle(routine == nil ? .secondary : .primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            statusIndicator(
                routine: routine,
                isToday: isToday,
                isPast: isPast,
                completed: completed,
                restChecked: restChecked
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            handleWeekDayTap(
                routine: routine,
                isToday: isToday,
                completed: completed,
                rowDate: rowDate
            )
        }
    }

    @ViewBuilder
    private func statusIndicator(
        routine: Routine?,
        isToday: Bool,
        isPast: Bool,
        completed: WorkoutSession?,
        restChecked: Bool
    ) -> some View {
        if routine == nil {
            Image(systemName: restChecked ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(restChecked ? LiftTheme.success : Color.secondary.opacity(0.4))
                .contentTransition(.symbolEffect(.replace))
        } else if completed != nil {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(LiftTheme.success)
        } else if isToday {
            HStack(spacing: 6) {
                Circle()
                    .fill(LiftTheme.accent)
                    .frame(width: 8, height: 8)
                Text("Today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LiftTheme.accent)
            }
        } else {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(Color.secondary.opacity(isPast ? 0.5 : 0.3))
        }
    }

    private func handleWeekDayTap(
        routine: Routine?,
        isToday: Bool,
        completed: WorkoutSession?,
        rowDate: Date
    ) {
        if routine == nil {
            toggleRestDay(rowDate)
            restDayToggleTrigger.toggle()
            return
        }

        if let completed {
            navigateToDetail = completed
        } else if let routine {
            pendingRoutine = routine
            showStartConfirmation = true
            startWorkoutTrigger.toggle()
        }
    }

    // MARK: - Rest-day persistence

    private func isRestDayChecked(_ date: Date) -> Bool {
        checkedRestDaysSet.contains(dateKey(for: date))
    }

    private func toggleRestDay(_ date: Date) {
        var set = checkedRestDaysSet
        let key = dateKey(for: date)
        if set.contains(key) {
            set.remove(key)
        } else {
            set.insert(key)
        }
        if let data = try? JSONEncoder().encode(Array(set).sorted()),
           let json = String(data: data, encoding: .utf8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                checkedRestDaysJSON = json
            }
        }
    }

    private var checkedRestDaysSet: Set<String> {
        guard let data = checkedRestDaysJSON.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(arr)
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: date)
    }

    private func date(forDayOfWeek dayOfWeek: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let diff = dayOfWeek - currentDayOfWeek
        return calendar.date(byAdding: .day, value: diff, to: today) ?? today
    }

    private func routineForWeek(plan: WorkoutPlan, dayOfWeek: Int) -> Routine? {
        guard let currentWeek = plan.currentWeek else { return nil }
        return currentWeek.routines.first { $0.dayOfWeek == dayOfWeek }
    }

    private func completedSessionThisWeek(for routine: Routine) -> WorkoutSession? {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return nil
        }
        return completedSessions.first { session in
            session.routine?.id == routine.id && weekInterval.contains(session.startedAt)
        }
    }

    private var currentDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }

    private func dayAbbreviation(for dayOfWeek: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let index = dayOfWeek % 7
        return symbols[index]
    }

    // MARK: - Today's Routine (existing)

    private func todaysRoutineSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.name)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let todayRoutine = todaysRoutine(from: plan) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(todayRoutine.name)
                            .font(.title2.weight(.semibold))

                        Text("\(todayRoutine.exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(todayRoutine.sortedExercises) { routineExercise in
                            if let exercise = routineExercise.exercise {
                                HStack {
                                    Image(systemName: exercise.muscleGroup.symbolName)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(exercise.name)
                                        .font(.body)
                                    Spacer()
                                    Text("\(routineExercise.sets.count) sets")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Button {
                            pendingRoutine = todayRoutine
                            showStartConfirmation = true
                            startWorkoutTrigger.toggle()
                        } label: {
                            Text("Start Workout")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)
                        .sensoryFeedback(.impact(weight: .medium), trigger: startWorkoutTrigger)
                    }
                }
            } else {
                GroupBox {
                    Text("No routine scheduled for today")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    @State private var emptyStateAppeared = false

    private var noPlanEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Active Plan")
                .font(.title2.weight(.semibold))

            Text("Create a workout plan to get started, or jump right in with a quick workout.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .opacity(emptyStateAppeared ? 1 : 0)
        .scaleEffect(emptyStateAppeared ? 1 : 0.95)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                emptyStateAppeared = true
            }
        }
    }

    private var quickWorkoutSection: some View {
        Button {
            showQuickStartConfirmation = true
            startWorkoutTrigger.toggle()
        } label: {
            Label("Quick Workout", systemImage: "bolt.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .sensoryFeedback(.impact(weight: .medium), trigger: startWorkoutTrigger)
        .confirmationDialog("Start Quick Workout?", isPresented: $showQuickStartConfirmation) {
            Button("Start") { startQuickWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will start an empty workout session.")
        }
        .confirmationDialog("Start Workout?", isPresented: $showStartConfirmation) {
            Button("Start") {
                if let routine = pendingRoutine {
                    startWorkout(from: routine)
                }
            }
            Button("Cancel", role: .cancel) { pendingRoutine = nil }
        } message: {
            Text("Ready to begin \(pendingRoutine?.name ?? "this workout")?")
        }
    }

    private func startWorkout(from routine: Routine) {
        let session = SessionBuilder.createSession(from: routine, context: modelContext)
        navigateToSession = session
    }

    private func startQuickWorkout() {
        let session = SessionBuilder.createQuickSession(context: modelContext)
        navigateToSession = session
    }

    private func todaysRoutine(from plan: WorkoutPlan) -> Routine? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convert Calendar weekday (1=Sun) to our format (1=Mon)
        let adjustedDay = weekday == 1 ? 7 : weekday - 1

        guard let currentWeek = plan.currentWeek else {
            return plan.weeks.sorted(by: { $0.weekNumber < $1.weekNumber }).first?.routines.first
        }

        return currentWeek.routines.first { $0.dayOfWeek == adjustedDay }
            ?? currentWeek.sortedRoutines.first
    }
}

#Preview {
    HomeTab()
        .modelContainer(.preview)
}
