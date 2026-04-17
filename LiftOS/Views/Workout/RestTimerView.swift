import SwiftUI
import UserNotifications
import AudioToolbox

struct RestTimerView: View {
    @Binding var seconds: Int
    let exerciseName: String
    let onDismiss: () -> Void

    @AppStorage("restTimerNotifications") private var notificationsEnabled = true
    @AppStorage("restTimerSound") private var soundEnabled = true

    @State private var timer: Timer?
    @State private var initialSeconds: Int = 0
    @State private var targetDate: Date = .distantFuture
    @State private var adjustTrigger = false
    @State private var timerCompleteTrigger = false
    @State private var appeared = false
    @State private var completionFlash = false
    @State private var hasCompleted = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rest Timer")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(exerciseName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isUrgent ? Color.orange : (completionFlash ? Color.green : Color.accentColor),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: seconds)
                        .shadow(color: (isUrgent ? Color.orange : Color.accentColor).opacity(0.4), radius: 6)

                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .scaleEffect(isUrgent ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isUrgent)
                }

                HStack(spacing: 16) {
                    Button {
                        seconds = max(0, seconds - 15)
                        targetDate = Date().addingTimeInterval(Double(seconds))
                        scheduleNotification()
                        adjustTrigger.toggle()
                    } label: {
                        Text("-15s")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 40)
                            .background(Color(.systemGray3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        seconds += 15
                        targetDate = Date().addingTimeInterval(Double(seconds))
                        if seconds > initialSeconds {
                            initialSeconds = seconds
                        }
                        scheduleNotification()
                        adjustTrigger.toggle()
                    } label: {
                        Text("+15s")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 40)
                            .background(Color(.systemGray3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button {
                    cancelNotification()
                    onDismiss()
                } label: {
                    Text("Skip")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 4)
            }
            .padding(32)
            .scaleEffect(appeared ? 1.0 : 0.95)
            .opacity(appeared ? 1.0 : 0)
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.4), trigger: adjustTrigger)
            .sensoryFeedback(.warning, trigger: timerCompleteTrigger)
        }
        .onAppear {
            initialSeconds = seconds
            startTimer()
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
        .onDisappear {
            timer?.invalidate()
            cancelNotification()
        }
    }

    private var isUrgent: Bool {
        seconds > 0 && seconds <= 5
    }

    private var progress: CGFloat {
        guard initialSeconds > 0 else { return 0 }
        return CGFloat(seconds) / CGFloat(initialSeconds)
    }

    private var formattedTime: String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startTimer() {
        targetDate = Date().addingTimeInterval(Double(seconds))
        scheduleNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                let remaining = Int(ceil(targetDate.timeIntervalSince(Date())))
                seconds = max(0, remaining)
                if seconds == 0 && !hasCompleted {
                    handleCompletion()
                }
            }
        }
    }

    private func handleCompletion() {
        hasCompleted = true
        timer?.invalidate()
        cancelNotification()
        if soundEnabled {
            AudioServicesPlaySystemSound(1007)
        }
        timerCompleteTrigger.toggle()
        withAnimation(.easeIn(duration: 0.2)) { completionFlash = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            onDismiss()
        }
    }

    private func scheduleNotification() {
        cancelNotification()
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set of \(exerciseName)"
        content.sound = .default
        let interval = targetDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }
}

#Preview {
    RestTimerView(
        seconds: .constant(90),
        exerciseName: "Bench Press",
        onDismiss: {}
    )
}
