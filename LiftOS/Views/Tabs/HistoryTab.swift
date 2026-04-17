import SwiftUI
import SwiftData

enum HistoryViewMode: String, CaseIterable {
    case list, calendar
}

struct HistoryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    @Query(filter: #Predicate<WorkoutPlan> { $0.isActive }) private var activePlans: [WorkoutPlan]

    @State private var viewMode: HistoryViewMode = .list
    @State private var path: [UUID] = []
    @State private var sessionToDelete: WorkoutSession?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    switch viewMode {
                    case .list:
                        sessionsList
                    case .calendar:
                        CalendarHeatmapView(sessions: sessions) { sessionID in
                            path.append(sessionID)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Picker("View", selection: $viewMode) {
                            Image(systemName: "list.bullet").tag(HistoryViewMode.list)
                            Image(systemName: "calendar").tag(HistoryViewMode.calendar)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { sessionID in
                if let session = sessions.first(where: { $0.id == sessionID }) {
                    WorkoutDetailView(session: session)
                }
            }
        }
    }

    private var sessionsList: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink(value: session.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if session.isQuickWorkout {
                                Text("Quick Workout")
                                    .font(.body.weight(.semibold))
                            } else if let routine = session.routine {
                                Text(routine.name)
                                    .font(.body.weight(.semibold))
                            } else {
                                Text("Workout")
                                    .font(.body.weight(.semibold))
                            }
                            Spacer()
                            if let durationFormatted = session.durationFormatted {
                                Text(durationFormatted)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 12) {
                            Text(session.startedAt, format: .dateTime.month().day().year())
                            Text("·")
                            Text("\(session.exercises.count) exercises")
                            Text("·")
                            Text("\(session.totalSets) sets")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        sessionToDelete = session
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Workout?",
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    modelContext.delete(session)
                    sessionToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { sessionToDelete = nil }
        } message: {
            Text("This will permanently delete this workout and all its data.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Workouts Yet", systemImage: "clock.arrow.circlepath")
        } description: {
            if activePlans.first != nil {
                Text("Start today's workout from the Today tab to build your history.")
            } else {
                Text("Create a plan or try a quick workout from the Today tab to get started.")
            }
        }
    }
}

#Preview {
    HistoryTab()
        .modelContainer(.preview)
}
