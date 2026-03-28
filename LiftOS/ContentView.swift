import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .today
    @State private var hasSeededData = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tabItem {
                    Label("Today", systemImage: "figure.run")
                }
                .tag(AppTab.today)

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

            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .task {
            if !hasSeededData {
                SeedDataService.seedIfNeeded(context: modelContext)
                hasSeededData = true
            }
        }
    }
}

enum AppTab: Hashable {
    case today
    case plans
    case history
    case profile
}

#Preview {
    ContentView()
        .modelContainer(.preview)
}
