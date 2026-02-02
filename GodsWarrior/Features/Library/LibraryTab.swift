import SwiftUI
import SwiftData

struct LibraryTab: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<WOD> { !$0.isLibrary }) private var userWODs: [WOD]

    var body: some View {
        @Bindable var nav = navigationStore

        NavigationStack {
            VStack(spacing: 0) {
                // Segment Picker
                Picker("Library Section", selection: $nav.librarySegment) {
                    ForEach(NavigationStore.LibrarySegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch nav.librarySegment {
                case .wod:
                    WODLibraryView(
                        curatedWODs: contentStore.wodData,
                        userWODs: userWODs
                    )
                case .breath:
                    BreathLibraryView(sessions: contentStore.breathSessionData)
                case .timer:
                    TimerLibraryView()
                }
            }
            .navigationTitle("Library")
            .toolbar {
                if nav.librarySegment == .wod {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            nav.openWODBuilder()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $nav.showWODBuilder) {
                WODBuilderView()
            }
        }
    }
}

// MARK: - WOD Library View

struct WODLibraryView: View {
    let curatedWODs: [WODData]
    let userWODs: [WOD]

    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore

    var body: some View {
        List {
            // Today's WOD pinned at top
            if let todaysWOD = contentStore.todaysWOD {
                Section("Today's Workout") {
                    WODDataListItem(wod: todaysWOD, isPinned: true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigationStore.openWODDetail(todaysWOD)
                        }
                }
            }

            // Curated WODs
            Section("Curated Workouts") {
                ForEach(curatedWODs) { wod in
                    WODDataListItem(wod: wod)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigationStore.openWODDetail(wod)
                        }
                }
            }

            // User WODs
            if !userWODs.isEmpty {
                Section("My Workouts") {
                    ForEach(userWODs) { wod in
                        WODListItem(wod: wod)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                navigationStore.openWODDetail(wod)
                            }
                    }
                }
            }
        }
    }
}

// MARK: - WOD List Item

struct WODListItem: View {
    let wod: WOD
    var isPinned: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(wod.name)
                        .font(.body.weight(.medium))
                }

                HStack(spacing: 8) {
                    Text(wod.wodType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())

                    Text("\(wod.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(wod.estimatedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - WOD Data List Item (for curated WODs)

struct WODDataListItem: View {
    let wod: WODData
    var isPinned: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(wod.name)
                        .font(.body.weight(.medium))
                }

                HStack(spacing: 8) {
                    Text(wod.wodType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())

                    Text("\(wod.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(wod.estimatedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Breath Library View

struct BreathLibraryView: View {
    let sessions: [BreathSessionData]
    @Environment(NavigationStore.self) private var navigationStore

    var body: some View {
        List {
            ForEach(sessions) { session in
                BreathDataListItem(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigationStore.openBreathSession(session)
                    }
            }
        }
    }
}

struct BreathDataListItem: View {
    let session: BreathSessionData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.name)
                        .font(.body.weight(.medium))

                    if session.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                Text(session.patternString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(session.rounds) rounds • \(session.totalDuration / 60) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
    }
}

// Keep the original for SwiftData models (user WODs)
struct BreathListItem: View {
    let session: BreathSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.name)
                        .font(.body.weight(.medium))

                    if session.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                Text(session.patternString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(session.rounds) rounds • \(session.totalDuration / 60) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Timer Library View

struct TimerLibraryView: View {
    @State private var showStandaloneTimer: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Timer Section
                VStack(spacing: 16) {
                    Image(systemName: "timer")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)

                    Text("Standalone Timer")
                        .font(.headline)

                    Text("Quick timers for your workouts")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Timer Presets
                VStack(spacing: 12) {
                    Text("Quick Start")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TimerPresetButton(
                        title: "AMRAP 12 min",
                        subtitle: "As many rounds as possible",
                        duration: 12 * 60,
                        showTimer: $showStandaloneTimer
                    )

                    TimerPresetButton(
                        title: "EMOM 10 min",
                        subtitle: "Every minute on the minute",
                        duration: 10 * 60,
                        showTimer: $showStandaloneTimer
                    )

                    TimerPresetButton(
                        title: "Tabata 4 min",
                        subtitle: "20s work / 10s rest × 8",
                        duration: 4 * 60,
                        showTimer: $showStandaloneTimer
                    )

                    TimerPresetButton(
                        title: "Custom Timer",
                        subtitle: "Set your own duration",
                        duration: nil,
                        showTimer: $showStandaloneTimer
                    )
                }
                .padding(.horizontal)
            }
        }
        .fullScreenCover(isPresented: $showStandaloneTimer) {
            StandaloneTimerView()
        }
    }
}

struct TimerPresetButton: View {
    let title: String
    let subtitle: String
    let duration: Int?
    @Binding var showTimer: Bool

    @AppStorage("standaloneTimerDuration") private var savedDuration: Int = 720

    var body: some View {
        Button {
            if let duration = duration {
                savedDuration = duration
            }
            showTimer = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Standalone Timer View

struct StandaloneTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("standaloneTimerDuration") private var initialDuration: Int = 720

    @State private var phase: StandaloneTimerPhase = .setup
    @State private var totalSeconds: Int = 720
    @State private var timeRemaining: Int = 720
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Timer")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                switch phase {
                case .setup:
                    setupView
                case .countdown(let seconds):
                    countdownView(seconds)
                case .running:
                    runningView
                case .paused:
                    pausedView
                case .completed:
                    completedView
                }

                Spacer()
            }
        }
        .onAppear {
            totalSeconds = initialDuration
            timeRemaining = initialDuration
        }
    }

    // MARK: - Phase Views

    private var setupView: some View {
        VStack(spacing: 32) {
            Text("Set Duration")
                .font(.title2)
                .foregroundStyle(.white)

            // Time picker
            HStack(spacing: 16) {
                TimePickerColumn(value: Binding(
                    get: { totalSeconds / 60 },
                    set: { totalSeconds = $0 * 60 + (totalSeconds % 60) }
                ), range: 0...60, label: "min")

                Text(":")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.white)

                TimePickerColumn(value: Binding(
                    get: { totalSeconds % 60 },
                    set: { totalSeconds = (totalSeconds / 60) * 60 + $0 }
                ), range: 0...59, label: "sec")
            }

            Button {
                timeRemaining = totalSeconds
                startCountdown()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
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

    private var runningView: some View {
        VStack(spacing: 32) {
            // Timer display
            Text(formatTime(timeRemaining))
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundStyle(.white.opacity(0.3))

                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalSeconds))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
            }
            .frame(width: 200, height: 200)

            // Controls
            HStack(spacing: 48) {
                Button {
                    pauseTimer()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .frame(width: 70, height: 70)
                        .background(.white)
                        .clipShape(Circle())
                }

                Button {
                    stopTimer()
                    phase = .setup
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var pausedView: some View {
        VStack(spacing: 32) {
            Text("PAUSED")
                .font(.largeTitle.bold())
                .foregroundStyle(.yellow)

            Text(formatTime(timeRemaining))
                .font(.system(size: 60, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            HStack(spacing: 32) {
                Button {
                    resumeTimer()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.title2.bold())
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }

                Button {
                    stopTimer()
                    phase = .setup
                } label: {
                    Text("Reset")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Time's Up!")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text(formatTime(totalSeconds))
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))

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

    // MARK: - Timer Control

    private func startCountdown() {
        phase = .countdown(seconds: 3)
        timerTask?.cancel()
        timerTask = Task {
            var count = 3
            while count > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))
                count -= 1
                await MainActor.run {
                    phase = .countdown(seconds: count)
                }
            }
            await MainActor.run {
                startTimer()
            }
        }
    }

    private func startTimer() {
        phase = .running
        timerTask?.cancel()
        timerTask = Task {
            while timeRemaining > 0 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    timeRemaining -= 1
                    if timeRemaining <= 0 {
                        phase = .completed
                    }
                }
            }
        }
    }

    private func pauseTimer() {
        timerTask?.cancel()
        phase = .paused
    }

    private func resumeTimer() {
        phase = .running
        startTimer()
    }

    private func stopTimer() {
        timerTask?.cancel()
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

enum StandaloneTimerPhase: Equatable {
    case setup
    case countdown(seconds: Int)
    case running
    case paused
    case completed
}

struct TimePickerColumn: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Picker(label, selection: $value) {
                ForEach(range, id: \.self) { num in
                    Text(String(format: "%02d", num))
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .tag(num)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 150)
            .clipped()

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

#Preview {
    LibraryTab()
        .environment(NavigationStore())
        .environment(ContentStore())
}
