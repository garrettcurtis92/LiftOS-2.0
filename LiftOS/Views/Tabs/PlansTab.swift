import SwiftUI
import SwiftData

enum PlanNavDestination: Hashable {
    case plan(UUID)
    case routine(UUID, planID: UUID)
}

struct PlansTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @State private var showingNewPlan = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if plans.isEmpty {
                    emptyState
                } else {
                    plansList
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewPlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: PlanNavDestination.self) { destination in
                switch destination {
                case .plan(let planID):
                    if let plan = plans.first(where: { $0.id == planID }) {
                        PlanDetailView(plan: plan)
                    }
                case .routine(let routineID, let planID):
                    if let plan = plans.first(where: { $0.id == planID }) {
                        routineDestination(id: routineID, plan: plan)
                    }
                }
            }
            .sheet(isPresented: $showingNewPlan) {
                NewPlanSheet()
                    .presentationDetents([.large])
            }
        }
    }

    private var plansList: some View {
        List {
            ForEach(plans) { plan in
                NavigationLink(value: PlanNavDestination.plan(plan.id)) {
                    PlanListRow(plan: plan)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(plan)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        setActive(plan)
                    } label: {
                        Label(plan.isActive ? "Deactivate" : "Set Active", systemImage: "play.fill")
                    }
                    .tint(plan.isActive ? .gray : .green)
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Plans", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Create a workout plan to organize your training week by week.")
        } actions: {
            Button("Create Plan") {
                showingNewPlan = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func routineDestination(id: UUID, plan: WorkoutPlan) -> some View {
        let allRoutines = plan.weeks.flatMap(\.routines)
        if let routine = allRoutines.first(where: { $0.id == id }) {
            RoutineEditorView(routine: routine)
        }
    }

    private func setActive(_ plan: WorkoutPlan) {
        let descriptor = FetchDescriptor<WorkoutPlan>(predicate: #Predicate { $0.isActive })
        let active = (try? modelContext.fetch(descriptor)) ?? []
        active.forEach { $0.isActive = false }
        plan.isActive = true
    }
}

struct PlanListRow: View {
    let plan: WorkoutPlan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(plan.name)
                        .font(.body.weight(.semibold))
                    if plan.isActive {
                        Text("Active")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 8) {
                    Label("\(plan.numberOfWeeks)w", systemImage: "calendar")
                    let routineCount = plan.weeks.flatMap(\.routines).count
                    Label("\(routineCount) routines", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PlansTab()
        .modelContainer(.preview)
}
