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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Standalone Timer")
                .font(.headline)

            Text("Build custom workouts on the fly")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // TODO: Open timer builder
            } label: {
                Label("Start Timer", systemImage: "play.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LibraryTab()
        .environment(NavigationStore())
        .environment(ContentStore())
}
