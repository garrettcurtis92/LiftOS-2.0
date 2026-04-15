import SwiftUI

struct CalendarHeatmapView: View {
    let sessions: [WorkoutSession]
    let onSelectSession: (UUID) -> Void

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var popoverDate: Date?
    @State private var monthChangeTrigger = false
    @State private var tapTrigger = false

    private var calendar: Calendar { Calendar.current }

    private var sessionDays: Set<Date> {
        Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
    }

    var body: some View {
        VStack(spacing: 20) {
            monthHeader
            weekdayHeader
            dayGrid
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: monthChangeTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: tapTrigger)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LiftTheme.accent)

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: displayedMonth)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(isAtCurrentMonth ? Color.secondary.opacity(0.4) : LiftTheme.accent)
            .disabled(isAtCurrentMonth)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(daysToDisplay, id: \.self) { date in
                dayCell(for: date)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 50 {
                        changeMonth(by: -1)
                    } else if value.translation.width < -50 && !isAtCurrentMonth {
                        changeMonth(by: 1)
                    }
                }
        )
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let hasWorkout = sessionDays.contains(calendar.startOfDay(for: date))

        DayCell(
            date: date,
            isInMonth: inMonth,
            isToday: isToday,
            hasWorkout: hasWorkout
        )
        .onTapGesture {
            guard hasWorkout else { return }
            tapTrigger.toggle()
            popoverDate = calendar.startOfDay(for: date)
        }
        .popover(isPresented: popoverBinding(for: date)) {
            DayPreviewCard(
                sessions: sessions(on: date),
                onSelectSession: { id in
                    popoverDate = nil
                    onSelectSession(id)
                }
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Helpers

    private func popoverBinding(for date: Date) -> Binding<Bool> {
        Binding(
            get: {
                guard let popoverDate else { return false }
                return calendar.isDate(popoverDate, inSameDayAs: date)
            },
            set: { isShowing in
                if !isShowing { popoverDate = nil }
            }
        )
    }

    private func changeMonth(by delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        if delta > 0 && calendar.compare(next, to: Date(), toGranularity: .month) == .orderedDescending {
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            displayedMonth = calendar.startOfMonth(for: next)
        }
        monthChangeTrigger.toggle()
    }

    private func sessions(on date: Date) -> [WorkoutSession] {
        let day = calendar.startOfDay(for: date)
        return sessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .sorted { $0.startedAt < $1.startedAt }
    }

    private var isAtCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    private var daysToDisplay: [Date] {
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let firstWeekday = calendar.firstWeekday
        let monthStartWeekday = calendar.component(.weekday, from: monthStart)
        let leadingSpillover = (monthStartWeekday - firstWeekday + 7) % 7

        guard let gridStart = calendar.date(byAdding: .day, value: -leadingSpillover, to: monthStart),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let daysInMonth = range.count
        let totalCells = leadingSpillover + daysInMonth
        let weeks = Int((Double(totalCells) / 7.0).rounded(.up))

        return (0..<(weeks * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isInMonth: Bool
    let isToday: Bool
    let hasWorkout: Bool

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LiftTheme.smallCornerRadius)
                .fill(fillColor)

            RoundedRectangle(cornerRadius: LiftTheme.smallCornerRadius)
                .stroke(LiftTheme.accent, lineWidth: isToday ? 2 : 0)

            Text("\(dayNumber)")
                .font(.subheadline.weight(hasWorkout ? .semibold : .regular))
                .monospacedDigit()
                .foregroundStyle(textColor)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var fillColor: Color {
        guard isInMonth else { return .clear }
        return hasWorkout ? LiftTheme.accent : Color.clear
    }

    private var textColor: Color {
        if !isInMonth { return Color.secondary.opacity(0.4) }
        if hasWorkout { return .white }
        return .primary
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let base = formatter.string(from: date)
        if hasWorkout { return "\(base), workout logged" }
        if isToday { return "\(base), today" }
        return base
    }
}

// MARK: - DayPreviewCard

private struct DayPreviewCard: View {
    let sessions: [WorkoutSession]
    let onSelectSession: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    if index > 0 {
                        Divider().padding(.vertical, 12)
                    }
                    sessionCard(session)
                }
            }
            .padding(16)
        }
        .frame(width: 280)
        .frame(minHeight: 180, maxHeight: 420)
    }

    @ViewBuilder
    private func sessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(sessionTitle(session))
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let duration = session.durationFormatted {
                    Text(duration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Text(session.startedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text("\(session.exercises.count) ex")
                Text("·").foregroundStyle(.tertiary)
                Text("\(session.totalSets) sets")
                Text("·").foregroundStyle(.tertiary)
                Text(formatVolume(session.totalVolume))
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .monospacedDigit()

            if let topSet = topSet(in: session) {
                Label {
                    Text("Top: \(topSet.displayString)")
                        .font(.footnote.weight(.medium))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "star.fill")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }

            Button {
                onSelectSession(session.id)
            } label: {
                Text("View Details")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
        }
    }

    private func sessionTitle(_ session: WorkoutSession) -> String {
        if session.isQuickWorkout { return "Quick Workout" }
        return session.routine?.name ?? "Workout"
    }

    private func topSet(in session: WorkoutSession) -> SessionSet? {
        session.exercises
            .compactMap { $0.topSet }
            .max { $0.volume < $1.volume }
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk vol", v / 1000)
        }
        return String(format: "%.0f vol", v)
    }
}

// MARK: - Calendar extension

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}

#Preview {
    NavigationStack {
        CalendarHeatmapView(sessions: [], onSelectSession: { _ in })
            .navigationTitle("History")
    }
    .modelContainer(.preview)
}
