import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressView: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise

    @State private var history: [ExerciseEntry] = []
    @State private var selectedMetric: Metric = .weight
    @State private var isLoading = true

    enum Metric: String, CaseIterable {
        case weight = "Weight"
        case volume = "Volume"
        case estimated1RM = "Est. 1RM"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    loadingSkeleton
                } else if history.isEmpty {
                    noDataView
                } else {
                    personalRecords
                    chartSection
                    historyList
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadHistory() }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                ShimmerRect(width: 160, height: 18)
                HStack(spacing: 12) {
                    ShimmerRect(height: 80)
                    ShimmerRect(height: 80)
                    ShimmerRect(height: 80)
                }
            }

            ShimmerRect(height: 200)

            VStack(alignment: .leading, spacing: 12) {
                ShimmerRect(width: 80, height: 18)
                ShimmerRect(height: 72)
                ShimmerRect(height: 72)
                ShimmerRect(height: 72)
            }
        }
    }

    // MARK: - Personal Records

    private var personalRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)

            HStack(spacing: 12) {
                if let heaviest = history.map(\.topWeight).max() {
                    prCard(title: "Heaviest", value: formatWeight(heaviest), icon: "scalemass.fill")
                }
                if let bestVolume = history.map(\.totalVolume).max() {
                    prCard(title: "Best Volume", value: formatVolume(bestVolume), icon: "flame.fill")
                }
                if let best1RM = history.compactMap(\.estimated1RM).max() {
                    prCard(title: "Est. 1RM", value: formatWeight(best1RM), icon: "trophy.fill")
                }
            }
        }
    }

    private func prCard(title: String, value: String, icon: String) -> some View {
        GroupBox {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(history) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value(selectedMetric.rawValue, metricValue(for: entry))
                    )
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value(selectedMetric.rawValue, metricValue(for: entry))
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)

            ForEach(history) { entry in
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.date, format: .dateTime.month().day().year())
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(entry.setsCompleted) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(entry.sets, id: \.id) { set in
                            HStack {
                                Text("Set \(set.setNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 44, alignment: .leading)
                                Text(set.displayString)
                                    .font(.subheadline)
                                Spacer()
                                if let rir = set.rir {
                                    Text("RIR \(rir)")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - No Data

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .imageScale(.large)
                .foregroundStyle(.tertiary)
            Text("No data yet")
                .font(.title3.weight(.medium))
            Text("Complete a workout with \(exercise.name) to see progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Data Loading

    private func loadHistory() {
        let exerciseID = exercise.id
        let predicate = #Predicate<SessionExercise> {
            $0.exercise?.id == exerciseID
        }
        var descriptor = FetchDescriptor<SessionExercise>(predicate: predicate)
        descriptor.fetchLimit = 50

        guard let results = try? modelContext.fetch(descriptor) else {
            isLoading = false
            return
        }

        history = results
            .filter { $0.session?.completedAt != nil }
            .sorted { ($0.session?.completedAt ?? .distantPast) < ($1.session?.completedAt ?? .distantPast) }
            .map { se in
                let completedSets = se.sortedSets.filter { $0.isCompleted && !$0.isWarmup }
                let topSet = completedSets.max { $0.volume < $1.volume }
                return ExerciseEntry(
                    id: se.id,
                    date: se.session?.completedAt ?? Date(),
                    topWeight: topSet?.weight ?? 0,
                    totalVolume: completedSets.reduce(0) { $0 + $1.volume },
                    estimated1RM: topSet?.estimatedOneRepMax,
                    setsCompleted: completedSets.count,
                    sets: completedSets
                )
            }
        isLoading = false
    }

    private func metricValue(for entry: ExerciseEntry) -> Double {
        switch selectedMetric {
        case .weight: return entry.topWeight
        case .volume: return entry.totalVolume
        case .estimated1RM: return entry.estimated1RM ?? 0
        }
    }

    // MARK: - Formatting

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return String(format: "%.0f", v)
    }
}

struct ExerciseEntry: Identifiable {
    let id: UUID
    let date: Date
    let topWeight: Double
    let totalVolume: Double
    let estimated1RM: Double?
    let setsCompleted: Int
    let sets: [SessionSet]
}

private struct ShimmerRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 44
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: LiftTheme.smallCornerRadius)
            .fill(Color.secondary.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LiftTheme.smallCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.secondary.opacity(0.1), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * 200)
            )
            .clipShape(RoundedRectangle(cornerRadius: LiftTheme.smallCornerRadius))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

#Preview {
    NavigationStack {
        ExerciseProgressView(exercise: Exercise(name: "Bench Press", muscleGroup: .chest, equipmentType: .barbell))
    }
    .modelContainer(.preview)
}
