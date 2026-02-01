import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore

    @State private var dailyLogService: DailyLogService?
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(dailyLogService)
            } else {
                OnboardingView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    hasCompletedOnboarding = true
                })
            }
        }
        .onAppear {
            dailyLogService = DailyLogService(modelContext: modelContext)
        }
    }
}

// MARK: - Onboarding View (Placeholder)

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 12) {
                Text("God's Warrior")
                    .font(.largeTitle.bold())

                Text("Physical fitness as spiritual discipline")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onComplete) {
                Text("Begin Your Journey")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    RootView()
        .environment(NavigationStore())
        .environment(ContentStore())
}
