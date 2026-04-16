import SwiftUI
import SwiftData
import Charts

struct ProgressTab: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]

    @Query(filter: #Predicate<WorkoutPlan> { $0.isActive }) private var activePlans: [WorkoutPlan]

    @State private var range: ProgressTimeRange = .threeMonths
    @State private var showProfile = false

    private var activePlan: WorkoutPlan? { activePlans.first }

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    emptyState
                } else {
                    dashboard
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileTab(showDismissButton: true)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Progress Yet", systemImage: "chart.xyaxis.line")
        } description: {
            Text("Complete your first workout to see your training trends here.")
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 24) {
                rangePicker
                heroKPIs
                weeklyVolumeCard
                muscleBalanceCard
                cumulativeTonnageCard
                longestStreakTile
            }
            .padding()
        }
    }

    // MARK: - Range Picker

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(ProgressTimeRange.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Hero KPIs

    private var streakInfo: (current: Int, longest: Int) {
        ProgressCalculator.streak(plan: activePlan, sessions: completedSessions)
    }

    private var heroKPIs: some View {
        let streak = streakInfo
        let total = ProgressCalculator.totalCompletedWorkouts(completedSessions)
        let volume = ProgressCalculator.totalVolume(completedSessions)

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            KPICard(
                title: streak.current == 1 ? "Day Streak" : "Day Streak",
                value: "\(streak.current)",
                icon: "flame.fill",
                tint: LiftTheme.warning
            )
            KPICard(
                title: total == 1 ? "Workout" : "Workouts",
                value: "\(total)",
                icon: "figure.strengthtraining.traditional",
                tint: LiftTheme.accent
            )
            KPICard(
                title: "Total Volume",
                value: formatVolume(volume),
                icon: "scalemass.fill",
                tint: LiftTheme.accent
            )
        }
    }

    // MARK: - Weekly Volume

    private var weeklyVolumeCard: some View {
        let points = ProgressCalculator.weeklyVolume(completedSessions, range: range)

        return cardContainer(title: "Weekly Volume") {
            if points.allSatisfy({ $0.volume == 0 }) {
                emptyChartHint("No volume logged in this range.")
            } else {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("Week", point.weekStart, unit: .weekOfYear),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(LiftTheme.accent.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: xAxisStride(for: range))) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private func xAxisStride(for range: ProgressTimeRange) -> Calendar.Component {
        switch range {
        case .fourWeeks, .threeMonths: return .weekOfYear
        case .sixMonths, .oneYear: return .month
        }
    }

    // MARK: - Muscle Balance

    private var muscleBalanceCard: some View {
        let counts = ProgressCalculator.muscleGroupBalance(completedSessions, range: range)
        let maxCount = counts.map(\.setCount).max() ?? 1

        return cardContainer(title: "Muscle Group Balance") {
            if counts.isEmpty {
                emptyChartHint("No working sets logged in this range.")
            } else {
                VStack(spacing: 10) {
                    ForEach(counts) { entry in
                        MuscleGroupBar(entry: entry, maxCount: maxCount)
                    }
                }
            }
        }
    }

    // MARK: - Cumulative Tonnage

    private var cumulativeTonnageCard: some View {
        let points = ProgressCalculator.cumulativeTonnage(completedSessions)

        return cardContainer(title: "Cumulative Tonnage", subtitle: "All-time") {
            if points.count < 2 {
                emptyChartHint("Log more workouts to see the trend curve.")
            } else {
                Chart {
                    ForEach(points) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.cumulativeVolume)
                        )
                        .foregroundStyle(LiftTheme.accent.opacity(0.2).gradient)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.cumulativeVolume)
                        )
                        .foregroundStyle(LiftTheme.accent)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    // MARK: - Longest Streak Tile

    @ViewBuilder
    private var longestStreakTile: some View {
        let longest = streakInfo.longest
        if longest > 0 {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(LiftTheme.highlight)
                Text("Longest streak:")
                    .foregroundStyle(.secondary)
                Text("\(longest) \(longest == 1 ? "session" : "sessions")")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Spacer()
            }
            .font(.subheadline)
            .padding()
            .background(LiftTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiftTheme.cornerRadius))
        }
    }

    // MARK: - Card Container

    @ViewBuilder
    private func cardContainer<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(LiftTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LiftTheme.cornerRadius))
    }

    private func emptyChartHint(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 32)
    }

    // MARK: - Formatting

    private func formatVolume(_ v: Double) -> String {
        if v >= 1_000_000 {
            return String(format: "%.1fM", v / 1_000_000)
        }
        if v >= 1_000 {
            return String(format: "%.1fk", v / 1_000)
        }
        return String(format: "%.0f", v)
    }

    private func formatCompact(_ v: Double) -> String {
        if v >= 1_000_000 {
            return String(format: "%.1fM", v / 1_000_000)
        }
        if v >= 1_000 {
            return String(format: "%.0fk", v / 1_000)
        }
        return String(format: "%.0f", v)
    }
}

// MARK: - KPI Card

private struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(LiftTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: LiftTheme.cornerRadius))
    }
}

// MARK: - Muscle Group Bar

private struct MuscleGroupBar: View {
    let entry: MuscleGroupCount
    let maxCount: Int

    private var fraction: Double {
        guard maxCount > 0 else { return 0 }
        return Double(entry.setCount) / Double(maxCount)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.muscleGroup.symbolName)
                .foregroundStyle(LiftTheme.accent)
                .frame(width: 24)

            Text(entry.muscleGroup.displayName)
                .font(.subheadline.weight(.medium))
                .frame(width: 88, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(LiftTheme.accent.gradient)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 10)

            Text("\(entry.setCount)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProgressTab()
        .modelContainer(.preview)
}
