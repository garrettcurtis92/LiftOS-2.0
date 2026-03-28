import SwiftUI
import SwiftData

@main
struct LiftOSApp: App {
    private let container: ModelContainer

    init() {
        container = .liftOS
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
