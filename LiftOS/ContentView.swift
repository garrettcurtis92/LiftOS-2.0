import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .today
    @State private var hasSeededData = false
    @State private var showOnboarding = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tabItem {
                    Label("Today", systemImage: "figure.run")
                }
                .tag(AppTab.today)
            
            ProgressTab()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(AppTab.progress)

            PlansTab()
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.clipboard")
                }
                .tag(AppTab.plans)

            HistoryTab()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)
        }
        .task {
            if !hasSeededData {
                SeedDataService.seedIfNeeded(context: modelContext)
                hasSeededData = true
            }
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                onBuildPlan: {
                    hasCompletedOnboarding = true
                    selectedTab = .plans
                    showOnboarding = false
                },
                onQuickWorkout: {
                    hasCompletedOnboarding = true
                    selectedTab = .today
                    showOnboarding = false
                }
            )
            .interactiveDismissDisabled()
        }
    }
}

enum AppTab: Hashable {
    case progress
    case today
    case plans
    case history
}

#Preview {
    ContentView()
        .modelContainer(.preview)
}
