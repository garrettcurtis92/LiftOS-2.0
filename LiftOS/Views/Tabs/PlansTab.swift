import SwiftUI
import SwiftData

struct PlansTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @State private var showingNewPlan = false

    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: $showingNewPlan) {
                // TODO: PlanDetailView for creation
                Text("New Plan")
                    .presentationDetents([.large])
            }
        }
    }

    private var plansList: some View {
        List {
            ForEach(plans) { plan in
                NavigationLink(value: plan.id) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(plan.name)
                                    .font(.body.weight(.semibold))
                                if plan.isActive {
                                    Text("Active")
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("\(plan.numberOfWeeks) weeks · \(plan.weeks.flatMap(\.routines).count) routines")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .onDelete(perform: deletePlans)
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

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plans[index])
        }
    }
}

#Preview {
    PlansTab()
        .modelContainer(.preview)
}
