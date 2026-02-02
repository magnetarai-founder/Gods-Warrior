import Foundation
import SwiftData
import Observation
import os

private let logger = Logger(subsystem: "com.godswarrior", category: "ContentStore")

/// Loads and serves bundled curated content
@MainActor
@Observable
final class ContentStore {

    // MARK: - Curated Content Data (from JSON)

    private(set) var verseData: [VerseData] = []
    private(set) var exerciseData: [ExerciseData] = []
    private(set) var breathSessionData: [BreathSessionData] = []
    private(set) var wodData: [WODData] = []

    // MARK: - Computed Properties

    var todaysVerse: VerseData? {
        guard !verseData.isEmpty else { return nil }
        let dayIndex = VerseRotationService.currentDayIndex
        return verseData[dayIndex % verseData.count]
    }

    var todaysWOD: WODData? {
        guard !wodData.isEmpty else { return nil }
        let dayIndex = VerseRotationService.currentDayIndex
        return wodData[dayIndex % wodData.count]
    }

    var defaultBreathSession: BreathSessionData? {
        breathSessionData.first { $0.isDefault } ?? breathSessionData.first
    }

    // MARK: - Initialization

    init() {
        loadBundledContent()
    }

    // MARK: - Loading

    private func loadBundledContent() {
        loadVerses()
        loadExercises()
        loadBreathSessions()
        loadWODs()

        logger.info("Loaded \(self.verseData.count) verses, \(self.exerciseData.count) exercises, \(self.breathSessionData.count) breath sessions, \(self.wodData.count) WODs")
    }

    private func loadVerses() {
        guard let file: VersesFile = loadJSON("verses") else { return }
        verseData = file.verses.map { json in
            VerseData(
                id: json.id,
                text: json.text,
                reference: json.reference,
                theme: json.theme,
                dayIndex: json.dayIndex
            )
        }
    }

    private func loadExercises() {
        guard let file: ExercisesFile = loadJSON("exercises") else { return }
        exerciseData = file.exercises.map { json in
            ExerciseData(
                id: json.id,
                name: json.name,
                description: json.description,
                instructions: json.instructions,
                category: json.category
            )
        }
    }

    private func loadBreathSessions() {
        guard let file: BreathSessionsFile = loadJSON("breath_sessions") else { return }
        breathSessionData = file.sessions.map { json in
            BreathSessionData(
                id: json.id,
                name: json.name,
                description: json.description,
                phases: json.phases.map { phase in
                    BreathPhaseData(type: phase.type, duration: phase.duration)
                },
                rounds: json.rounds,
                isDefault: json.isDefault ?? false
            )
        }
    }

    private func loadWODs() {
        guard let file: WODsFile = loadJSON("curated_wods") else { return }
        wodData = file.wods.map { json in
            WODData(
                id: json.id,
                name: json.name,
                description: json.description,
                type: json.type,
                timeCap: json.timeCap,
                rounds: json.rounds,
                exercises: json.exercises.map { ex in
                    WODExerciseData(
                        exerciseId: ex.exerciseId,
                        reps: ex.reps,
                        duration: ex.duration
                    )
                }
            )
        }
    }

    private func loadJSON<T: Decodable>(_ filename: String) -> T? {
        // Try multiple paths
        let paths = [
            Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Data"),
            Bundle.main.url(forResource: filename, withExtension: "json"),
            Bundle.main.resourceURL?.appendingPathComponent("Data/\(filename).json")
        ]

        for path in paths {
            if let url = path, let data = try? Data(contentsOf: url) {
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    logger.info("Loaded \(filename).json from \(url.path)")
                    return result
                } catch {
                    logger.error("Failed to decode \(filename).json: \(error.localizedDescription)")
                }
            }
        }

        logger.warning("Could not find \(filename).json in bundle")
        return nil
    }

    // MARK: - Accessors

    func exercise(byId id: String) -> ExerciseData? {
        exerciseData.first { $0.id == id }
    }

    func verse(at dayIndex: Int) -> VerseData? {
        guard !verseData.isEmpty else { return nil }
        let index = dayIndex % verseData.count
        return verseData[index]
    }
}

// MARK: - Data Transfer Objects (lightweight, non-SwiftData)

struct VerseData: Identifiable, Equatable {
    let id: String
    let text: String
    let reference: String
    let theme: String?
    let dayIndex: Int

    /// Convert from SwiftData Verse model
    init(from verse: Verse) {
        self.id = verse.id.uuidString
        self.text = verse.text
        self.reference = verse.reference
        self.theme = verse.theme
        self.dayIndex = verse.dayIndex
    }

    init(id: String, text: String, reference: String, theme: String?, dayIndex: Int) {
        self.id = id
        self.text = text
        self.reference = reference
        self.theme = theme
        self.dayIndex = dayIndex
    }
}

struct ExerciseData: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let instructions: String?
    let category: String

    /// Convert to SwiftData Exercise model (for saving to database)
    func toExercise() -> Exercise {
        let cat = ExerciseCategory(rawValue: category) ?? .fullBody
        return Exercise(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            description: description,
            instructions: instructions,
            category: cat,
            isLibrary: false  // User-created exercises
        )
    }
}

struct BreathSessionData: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let phases: [BreathPhaseData]
    let rounds: Int
    let isDefault: Bool

    var patternString: String {
        phases.map { "\($0.duration)s" }.joined(separator: " / ")
    }

    var totalDuration: Int {
        phases.reduce(0) { $0 + $1.duration } * rounds
    }

    /// Convert from SwiftData BreathSession model
    init(from session: BreathSession) {
        self.id = session.id.uuidString
        self.name = session.name
        self.description = session.sessionDescription
        self.phases = session.phases.map { BreathPhaseData(from: $0) }
        self.rounds = session.rounds
        self.isDefault = session.isDefault
    }

    init(id: String, name: String, description: String?, phases: [BreathPhaseData], rounds: Int, isDefault: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.phases = phases
        self.rounds = rounds
        self.isDefault = isDefault
    }
}

struct BreathPhaseData: Identifiable, Equatable {
    let id: UUID
    let type: String
    let duration: Int

    var phaseType: BreathPhaseType {
        switch type {
        case "inhale": return .inhale
        case "holdIn": return .holdIn
        case "exhale": return .exhale
        case "holdOut": return .holdOut
        default: return .inhale
        }
    }

    /// Convert from SwiftData BreathPhase model
    init(from phase: BreathPhase) {
        self.id = UUID()
        self.type = phase.phaseType.rawValue
        self.duration = phase.duration
    }

    init(type: String, duration: Int) {
        self.id = UUID()
        self.type = type
        self.duration = duration
    }
}

struct WODData: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let timeCap: Int?
    let rounds: Int?
    let exercises: [WODExerciseData]

    var wodType: WODType {
        switch type {
        case "amrap": return .amrap
        case "tabata": return .tabata
        case "rounds": return .rounds
        case "timeLimited": return .timeLimited
        default: return .rounds
        }
    }

    var exerciseCount: Int { exercises.count }

    var estimatedDuration: String {
        if let timeCap = timeCap {
            return "\(timeCap / 60) min"
        } else if let rounds = rounds {
            return "\(rounds) rounds"
        }
        return "Variable"
    }

    /// Convert from SwiftData WOD model
    init(from wod: WOD) {
        self.id = wod.id.uuidString
        self.name = wod.name
        self.description = nil
        self.type = wod.wodType.rawValue
        self.timeCap = wod.config.timeCap
        self.rounds = wod.config.rounds
        self.exercises = wod.sortedExercises.map { WODExerciseData(from: $0) }
    }

    init(id: String, name: String, description: String?, type: String, timeCap: Int?, rounds: Int?, exercises: [WODExerciseData]) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
    }
}

struct WODExerciseData: Identifiable, Equatable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String?
    let reps: Int?
    let duration: Int?

    var displayString: String {
        let name = exerciseName ?? exerciseId
        if let reps = reps {
            return "\(reps) × \(name)"
        } else if let duration = duration {
            return "\(duration)s \(name)"
        }
        return name
    }

    /// Convert from SwiftData WODExercise model
    init(from wodExercise: WODExercise) {
        self.id = UUID()
        self.exerciseId = wodExercise.exercise?.id.uuidString ?? ""
        self.exerciseName = wodExercise.exercise?.name
        self.reps = wodExercise.reps
        self.duration = wodExercise.duration
    }

    init(exerciseId: String, reps: Int?, duration: Int?) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = nil
        self.reps = reps
        self.duration = duration
    }
}

// MARK: - JSON File Structures

private struct VersesFile: Decodable {
    let version: String
    let verses: [VerseJSON]
}

private struct VerseJSON: Decodable {
    let id: String
    let text: String
    let reference: String
    let theme: String?
    let bookOrder: Int?
    let dayIndex: Int
}

private struct ExercisesFile: Decodable {
    let version: String
    let exercises: [ExerciseJSON]
}

private struct ExerciseJSON: Decodable {
    let id: String
    let name: String
    let description: String
    let instructions: String?
    let category: String
    let muscleGroups: [String]?
}

private struct BreathSessionsFile: Decodable {
    let version: String
    let sessions: [BreathSessionJSON]
}

private struct BreathSessionJSON: Decodable {
    let id: String
    let name: String
    let description: String?
    let phases: [BreathPhaseJSON]
    let rounds: Int
    let isDefault: Bool?
}

private struct BreathPhaseJSON: Decodable {
    let type: String
    let duration: Int
}

private struct WODsFile: Decodable {
    let version: String
    let wods: [WODJSON]
}

private struct WODJSON: Decodable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let timeCap: Int?
    let rounds: Int?
    let exercises: [WODExerciseJSON]
}

private struct WODExerciseJSON: Decodable {
    let exerciseId: String
    let reps: Int?
    let duration: Int?
}
