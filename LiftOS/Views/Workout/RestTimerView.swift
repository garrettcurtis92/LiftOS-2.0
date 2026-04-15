import SwiftUI

struct RestTimerView: View {
    @Binding var seconds: Int
    let exerciseName: String
    let onDismiss: () -> Void

    @State private var timer: Timer?
    @State private var initialSeconds: Int = 0
    @State private var adjustTrigger = false
    @State private var timerCompleteTrigger = false
    @State private var appeared = false
    @State private var completionFlash = false

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
                        .animation(.linear(duration: 1), value: seconds)
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
                        if seconds > initialSeconds {
                            initialSeconds = seconds
                        }
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if seconds > 0 {
                    seconds -= 1
                    if seconds == 0 {
                        timerCompleteTrigger.toggle()
                        withAnimation(.easeIn(duration: 0.2)) { completionFlash = true }
                        // Brief delay before auto-dismiss so haptic + flash are visible
                        try? await Task.sleep(for: .milliseconds(800))
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RestTimerView(
        seconds: .constant(90),
        exerciseName: "Bench Press",
        onDismiss: {}
    )
}
