import SwiftUI

struct RestTimerView: View {
    @Binding var seconds: Int
    let exerciseName: String
    let onDismiss: () -> Void

    @State private var timer: Timer?
    @State private var initialSeconds: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 24) {
                Text("Rest Timer")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(exerciseName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: seconds)

                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 32) {
                    Button {
                        seconds = max(0, seconds - 15)
                    } label: {
                        Text("-15s")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Button {
                        seconds += 15
                        if seconds > initialSeconds {
                            initialSeconds = seconds
                        }
                    } label: {
                        Text("+15s")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Button("Skip") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 4)
            }
            .padding(32)
        }
        .onAppear {
            initialSeconds = seconds
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
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
            if seconds > 0 {
                seconds -= 1
            } else {
                onDismiss()
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
