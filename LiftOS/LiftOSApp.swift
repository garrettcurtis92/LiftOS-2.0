import SwiftUI
import SwiftData
import MetricKit

@main
struct LiftOSApp: App {
    private let container: ModelContainer
    @State private var metricsSubscriber = MetricsSubscriber()

    init() {
        container = .liftOS
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    MXMetricManager.shared.add(metricsSubscriber)
                }
        }
        .modelContainer(container)
    }
}

@Observable
final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            print("[MetricKit] Metric payload received: \(payload.dictionaryRepresentation())")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            print("[MetricKit] Diagnostic payload received: \(payload.dictionaryRepresentation())")
        }
    }
}
