import SwiftUI

struct WorkoutExecutionView: View {
    let wod: WODData

    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.dismiss) private var dismiss

    @State private var phase: WorkoutExecutionPhase = .idle
    @State private var currentExerciseIndex: Int = 0
    @State private var currentRound: Int = 1
    @State private var timeRemaining: Int = 0
    @State private var totalElapsed: Int = 0
    @State private var roundsCompleted: Int = 0
    @State private var timerTask: Task<Void, Never>?

    private var exercises: [WODExerciseData] {
        wod.exercises
    }

    private var currentExercise: WODExerciseData? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    private func exerciseName(for exerciseId: String) -> String {
        contentStore.exercise(byId: exerciseId)?.name ?? exerciseId.replacingOccurrences(of: "-", with: " ").capitalized
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header with close button
                HStack {
                    VStack(alignment: .leading) {
                        Text(wod.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(wod.wodType.displayName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        stopWorkout()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                // Main content based on phase
                switch phase {
                case .idle:
                    idleView
                case .countdown(let seconds):
                    countdownView(seconds)
                case .active:
                    activeView
                case .rest(let seconds):
                    restView(seconds)
                case .paused:
                    pausedView
                case .completed:
                    completedView
                }

                Spacer()

                // Bottom controls
                if case .active = phase {
                    controlsView
                }
            }
        }
    }

    // MARK: - Phase Views

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.white)

            Text("Ready to Begin")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("\(exercises.count) exercises")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))

            Button {
                startWorkout()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
            .padding(.top, 32)
        }
    }

    private func countdownView(_ seconds: Int) -> some View {
        VStack(spacing: 16) {
            Text("Get Ready")
                .font(.title)
                .foregroundStyle(.white)

            Text("\(seconds)")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    private var activeView: some View {
        VStack(spacing: 24) {
            // Timer
            Text(formatTime(wod.wodType == .amrap || wod.wodType == .timeLimited ? timeRemaining : totalElapsed))
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            // Current exercise
            if let exercise = currentExercise {
                VStack(spacing: 8) {
                    Text(exerciseName(for: exercise.exerciseId))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    if let reps = exercise.reps {
                        Text("\(reps) reps")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    } else if let duration = exercise.duration {
                        Text("\(duration)s")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Progress
            HStack(spacing: 32) {
                VStack {
                    Text("Round")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(currentRound)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack {
                    Text("Exercise")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(currentExerciseIndex + 1)/\(exercises.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func restView(_ seconds: Int) -> some View {
        VStack(spacing: 16) {
            Text("REST")
                .font(.largeTitle.bold())
                .foregroundStyle(.green)

            Text("\(seconds)")
                .font(.system(size: 100, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var pausedView: some View {
        VStack(spacing: 24) {
            Text("PAUSED")
                .font(.largeTitle.bold())
                .foregroundStyle(.yellow)

            Button {
                resumeWorkout()
            } label: {
                Label("Resume", systemImage: "play.fill")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
    }

    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("\(roundsCompleted) rounds")
                    .font(.title2)
                    .foregroundStyle(.white)

                Text(formatTime(totalElapsed))
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
            .padding(.top, 32)
        }
    }

    private var controlsView: some View {
        HStack(spacing: 48) {
            // Pause
            Button {
                pauseWorkout()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }

            // Next exercise
            Button {
                advanceToNextExercise()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(.black)
                    .frame(width: 80, height: 80)
                    .background(.white)
                    .clipShape(Circle())
            }

            // Complete round (for AMRAP)
            if wod.wodType == .amrap {
                Button {
                    completeRound()
                } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.orange)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Workout Control

    private func startWorkout() {
        phase = .countdown(secondsRemaining: 10)
        runCountdown()
    }

    private func runCountdown() {
        timerTask?.cancel()
        timerTask = Task {
            var count = 10
            while count > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))
                count -= 1
                await MainActor.run {
                    phase = .countdown(secondsRemaining: count)
                }
            }
            await MainActor.run {
                beginWorkout()
            }
        }
    }

    private func beginWorkout() {
        currentExerciseIndex = 0
        currentRound = 1
        totalElapsed = 0
        roundsCompleted = 0

        // Set up timer based on WOD type
        switch wod.wodType {
        case .amrap, .timeLimited:
            timeRemaining = wod.timeCap ?? 12 * 60
        case .rounds, .tabata:
            timeRemaining = 0
        }

        phase = .active(exerciseState: ExerciseState(
            exerciseIndex: 0,
            exerciseName: currentExercise.map { exerciseName(for: $0.exerciseId) } ?? "",
            instructions: nil,
            isTimeBased: currentExercise?.duration != nil,
            timeRemaining: currentExercise?.duration,
            currentRound: 1,
            totalRounds: wod.rounds ?? 0,
            repsCompleted: 0,
            targetReps: currentExercise?.reps,
            tabataPhase: nil
        ))

        runMainTimer()
    }

    private func runMainTimer() {
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

        switch wod.wodType {
        case .amrap, .timeLimited:
            timeRemaining -= 1
            if timeRemaining <= 0 {
                completeWorkout()
            }
        case .rounds:
            // Just track elapsed time
            break
        case .tabata:
            // Handle Tabata intervals
            break
        }
    }

    private func advanceToNextExercise() {
        currentExerciseIndex += 1

        if currentExerciseIndex >= exercises.count {
            // End of round
            roundsCompleted += 1
            currentExerciseIndex = 0

            if wod.wodType == .rounds {
                if roundsCompleted >= (wod.rounds ?? 1) {
                    completeWorkout()
                    return
                }
            }

            currentRound += 1
        }

        phase = .active(exerciseState: ExerciseState(
            exerciseIndex: currentExerciseIndex,
            exerciseName: currentExercise.map { exerciseName(for: $0.exerciseId) } ?? "",
            instructions: nil,
            isTimeBased: currentExercise?.duration != nil,
            timeRemaining: currentExercise?.duration,
            currentRound: currentRound,
            totalRounds: wod.rounds ?? 0,
            repsCompleted: 0,
            targetReps: currentExercise?.reps,
            tabataPhase: nil
        ))
    }

    private func completeRound() {
        roundsCompleted += 1
        currentExerciseIndex = 0
        currentRound += 1
    }

    private func pauseWorkout() {
        timerTask?.cancel()
        phase = .paused
    }

    private func resumeWorkout() {
        phase = .active(exerciseState: ExerciseState(
            exerciseIndex: currentExerciseIndex,
            exerciseName: currentExercise.map { exerciseName(for: $0.exerciseId) } ?? "",
            instructions: nil,
            isTimeBased: currentExercise?.duration != nil,
            timeRemaining: currentExercise?.duration,
            currentRound: currentRound,
            totalRounds: wod.rounds ?? 0,
            repsCompleted: 0,
            targetReps: currentExercise?.reps,
            tabataPhase: nil
        ))
        runMainTimer()
    }

    private func stopWorkout() {
        timerTask?.cancel()
    }

    private func completeWorkout() {
        timerTask?.cancel()
        phase = .completed

        // Auto-log
        if let log = dailyLogService.todayLog {
            let summary = WODSummary(
                totalTime: totalElapsed,
                roundsCompleted: roundsCompleted,
                repsCompleted: nil,
                notes: nil
            )
            dailyLogService.markWODCompleted(for: log, summary: summary)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Workout Execution Phase

enum WorkoutExecutionPhase: Equatable {
    case idle
    case countdown(secondsRemaining: Int)
    case active(exerciseState: ExerciseState)
    case rest(secondsRemaining: Int)
    case paused
    case completed
}

struct ExerciseState: Equatable {
    let exerciseIndex: Int
    let exerciseName: String
    let instructions: String?
    let isTimeBased: Bool
    var timeRemaining: Int?
    var currentRound: Int
    var totalRounds: Int
    var repsCompleted: Int
    var targetReps: Int?
    var tabataPhase: TabataPhase?
}

enum TabataPhase: String, Equatable {
    case work = "WORK"
    case rest = "REST"
}

#Preview {
    WorkoutExecutionView(wod: WODData(
        id: "preview",
        name: "Test AMRAP",
        description: nil,
        type: "amrap",
        timeCap: 720,
        rounds: nil,
        exercises: [
            WODExerciseData(exerciseId: "pushup-standard", reps: 10, duration: nil),
            WODExerciseData(exerciseId: "squat-air", reps: 15, duration: nil)
        ]
    ))
    .environment(ContentStore())
}
