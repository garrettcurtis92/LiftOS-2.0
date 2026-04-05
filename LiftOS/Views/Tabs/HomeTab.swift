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

    private var activePlan: WorkoutPlan? { activePlans.first }
    private var activeSession: WorkoutSession? { inProgressSessions.first }

    @State private var navigateToSession: WorkoutSession?
    @State private var showStartConfirmation = false
    @State private var showQuickStartConfirmation = false
    @State private var pendingRoutine: Routine?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let activeSession {
                        activeSessionCard(activeSession)
                    }

                    if let activePlan {
                        weekIndicator(activePlan)
                        todaysRoutineSection(activePlan)
                    } else {
                        noPlanEmptyState
                    }

                    quickWorkoutSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationDestination(item: $navigateToSession) { session in
                ActiveWorkoutView(session: session)
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
                } label: {
                    Label("Next Week", systemImage: "chevron.right")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button {
                    plan.currentWeekNumber = 1
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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
                        } label: {
                            Text("Start Workout")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)
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

    private var noPlanEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
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
    }

    private var quickWorkoutSection: some View {
        Button {
            showQuickStartConfirmation = true
        } label: {
            Label("Quick Workout", systemImage: "bolt.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
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
