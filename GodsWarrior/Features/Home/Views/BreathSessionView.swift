import SwiftUI

struct BreathSessionView: View {
    let session: BreathSession

    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathExecutionPhase = .idle
    @State private var currentPhaseIndex: Int = 0
    @State private var currentRound: Int = 1
    @State private var timeRemaining: Int = 0
    @State private var totalElapsed: Int = 0
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Background gradient based on phase
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        stopSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                // Phase indicator
                if case .active = phase {
                    Text(currentPhaseType.instruction)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)

                    // Timer
                    Text("\(timeRemaining)")
                        .font(.system(size: 120, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    // Progress ring
                    ProgressRing(progress: progress)
                        .frame(width: 200, height: 200)

                    // Round indicator
                    Text("Round \(currentRound) of \(session.rounds)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                if case .countdown(let seconds) = phase {
                    Text("Get Ready")
                        .font(.title)
                        .foregroundStyle(.white)

                    Text("\(seconds)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundStyle(.white)
                }

                if case .idle = phase {
                    VStack(spacing: 16) {
                        Text(session.name)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text(session.patternString)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))

                        Text("\(session.rounds) rounds • \(session.totalDuration / 60) minutes")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.6))

                        Button {
                            startSession()
                        } label: {
                            Label("Begin", systemImage: "play.fill")
                                .font(.title2.bold())
                                .padding(.horizontal, 48)
                                .padding(.vertical, 16)
                                .background(.white)
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 32)
                    }
                }

                if case .completed = phase {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)

                        Text("Session Complete")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("\(session.rounds) rounds completed")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))

                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.title2.bold())
                                .padding(.horizontal, 48)
                                .padding(.vertical, 16)
                                .background(.white)
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 32)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Computed Properties

    private var currentPhaseType: BreathPhaseType {
        guard currentPhaseIndex < session.phases.count else { return .inhale }
        return session.phases[currentPhaseIndex].phaseType
    }

    private var progress: Double {
        let totalDuration = session.totalDuration
        guard totalDuration > 0 else { return 0 }
        return Double(totalElapsed) / Double(totalDuration)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [currentPhaseType.color, currentPhaseType.color.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.5), value: currentPhaseType)
    }

    // MARK: - Session Control

    private func startSession() {
        phase = .countdown(secondsRemaining: 5)
        runCountdown()
    }

    private func runCountdown() {
        timerTask?.cancel()
        timerTask = Task {
            var count = 5
            while count > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))
                count -= 1
                await MainActor.run {
                    phase = .countdown(secondsRemaining: count)
                }
            }
            await MainActor.run {
                beginBreathing()
            }
        }
    }

    private func beginBreathing() {
        currentPhaseIndex = 0
        currentRound = 1
        totalElapsed = 0

        guard !session.phases.isEmpty else {
            phase = .completed
            return
        }

        timeRemaining = session.phases[0].duration
        phase = .active(breathState: BreathState(
            phase: session.phases[0].phaseType,
            timeRemaining: timeRemaining,
            currentRound: currentRound,
            totalRounds: session.rounds,
            totalElapsedSeconds: 0,
            totalSessionSeconds: session.totalDuration
        ))

        runBreathTimer()
    }

    private func runBreathTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while true {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))

                await MainActor.run {
                    tickTimer()
                }

                if case .completed = phase {
                    return
                }
            }
        }
    }

    private func tickTimer() {
        totalElapsed += 1
        timeRemaining -= 1

        if timeRemaining <= 0 {
            advancePhase()
        } else {
            updateActiveState()
        }
    }

    private func advancePhase() {
        currentPhaseIndex += 1

        if currentPhaseIndex >= session.phases.count {
            // End of round
            currentRound += 1
            if currentRound > session.rounds {
                // Session complete
                completeSession()
                return
            }
            currentPhaseIndex = 0
        }

        timeRemaining = session.phases[currentPhaseIndex].duration
        updateActiveState()
    }

    private func updateActiveState() {
        phase = .active(breathState: BreathState(
            phase: session.phases[currentPhaseIndex].phaseType,
            timeRemaining: timeRemaining,
            currentRound: currentRound,
            totalRounds: session.rounds,
            totalElapsedSeconds: totalElapsed,
            totalSessionSeconds: session.totalDuration
        ))
    }

    private func completeSession() {
        timerTask?.cancel()
        phase = .completed

        // Auto-log completion
        if let log = dailyLogService.todayLog {
            dailyLogService.markBreathCompleted(for: log)
        }
    }

    private func stopSession() {
        timerTask?.cancel()
        phase = .idle
    }
}

// MARK: - Breath Execution Phase

enum BreathExecutionPhase: Equatable {
    case idle
    case countdown(secondsRemaining: Int)
    case active(breathState: BreathState)
    case paused
    case completed
}

struct BreathState: Equatable {
    var phase: BreathPhaseType
    var timeRemaining: Int
    var currentRound: Int
    var totalRounds: Int
    var totalElapsedSeconds: Int
    var totalSessionSeconds: Int

    var progress: Double {
        guard totalSessionSeconds > 0 else { return 0 }
        return Double(totalElapsedSeconds) / Double(totalSessionSeconds)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .foregroundStyle(.white.opacity(0.3))

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

#Preview {
    BreathSessionView(session: BreathSession.boxBreathing())
}
