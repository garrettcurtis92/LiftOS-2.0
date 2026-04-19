import SwiftUI

struct OnboardingView: View {
    var onBuildPlan: () -> Void
    var onQuickWorkout: () -> Void

    @State private var currentPage = 0
    @State private var buttonTrigger = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "figure.strengthtraining.traditional",
            title: "Welcome to AdaptOS",
            description: "A workout tracker built for serious lifters. Track every set, beat every session."
        ),
        OnboardingPage(
            symbol: "arrow.up.right.circle.fill",
            title: "Beat Last Week",
            description: "See your previous reps and weight inline every set. Hit your target range — AdaptOS bumps the weight automatically."
        ),
        OnboardingPage(
            symbol: "calendar.badge.checkmark",
            title: "Your Plan, Your Way",
            description: "Build multi-week programs with deload weeks, or jump straight into a quick workout."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            bottomSection
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .padding(.top, 16)
        }
        .background(Color(.systemBackground))
    }

    private var bottomSection: some View {
        VStack(spacing: 32) {
            pageIndicator

            if currentPage < pages.count - 1 {
                nextButton
            } else {
                ctaButtons
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? LiftTheme.accent : Color.secondary.opacity(0.3))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    private var nextButton: some View {
        Button {
            buttonTrigger.toggle()
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage += 1
            }
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTrigger)
    }

    private var ctaButtons: some View {
        VStack(spacing: 12) {
            Button {
                buttonTrigger.toggle()
                onBuildPlan()
            } label: {
                Text("Create My First Plan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                buttonTrigger.toggle()
                onQuickWorkout()
            } label: {
                Text("Quick Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: buttonTrigger)
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let description: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.symbol)
                .font(.title)
                .imageScale(.large)
                .foregroundStyle(LiftTheme.accent)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.6))
                .opacity(appeared ? 1.0 : 0.0)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(appeared ? 1.0 : 0.0)
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 16))

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.05)) {
                    appeared = true
                }
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview {
    OnboardingView(onBuildPlan: {}, onQuickWorkout: {})
}
