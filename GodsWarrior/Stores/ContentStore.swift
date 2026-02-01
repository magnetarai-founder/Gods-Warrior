import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.godswarrior", category: "ContentStore")

/// Loads and serves bundled curated content (read-only)
@MainActor
@Observable
final class ContentStore {

    // MARK: - Curated Content (Immutable)

    private(set) var verses: [Verse] = []
    private(set) var exercises: [Exercise] = []
    private(set) var breathSessions: [BreathSession] = []
    private(set) var curatedWODs: [WOD] = []

    // MARK: - Indexed Access

    private var exerciseIndex: [UUID: Exercise] = [:]
    private var versesByDayIndex: [Int: Verse] = [:]

    // MARK: - Computed Properties

    var todaysVerse: Verse? {
        VerseRotationService.todaysVerse(from: verses)
    }

    var todaysWOD: WOD? {
        guard !curatedWODs.isEmpty else { return nil }
        let dayIndex = VerseRotationService.currentDayIndex
        return curatedWODs[dayIndex % curatedWODs.count]
    }

    var defaultBreathSession: BreathSession? {
        breathSessions.first { $0.isDefault } ?? breathSessions.first
    }

    // MARK: - Initialization

    init() {
        loadBundledContent()
    }

    // MARK: - Loading

    private func loadBundledContent() {
        // Load verses from JSON if available
        if let versesFile = loadJSON("verses", type: VersesFile.self) {
            // Note: Verses would be Verse.JSONRepresentation, convert to SwiftData models elsewhere
            logger.info("Loaded verses file with \(versesFile.verses.count) verses")
        }

        // Load exercises from JSON if available
        if let exercisesFile = loadJSON("exercises", type: ExercisesFile.self) {
            logger.info("Loaded exercises file with \(exercisesFile.exercises.count) exercises")
        }

        // Load breath sessions from JSON if available
        if let breathFile = loadJSON("breath_sessions", type: BreathSessionsFile.self) {
            logger.info("Loaded breath sessions file with \(breathFile.sessions.count) sessions")
        }

        // Load WODs from JSON if available
        if let wodsFile = loadJSON("curated_wods", type: WODsFile.self) {
            logger.info("Loaded WODs file with \(wodsFile.wods.count) WODs")
        }

        logger.info("Content loading complete")
    }

    private func loadJSON<T: Decodable>(_ filename: String, type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Data") else {
            logger.warning("Could not find \(filename).json in bundle")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to load \(filename).json")
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("Failed to decode \(filename).json: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Accessors

    func exercise(by id: UUID) -> Exercise? {
        exerciseIndex[id]
    }

    func verse(at dayIndex: Int) -> Verse? {
        guard !verses.isEmpty else { return nil }
        let index = dayIndex % verses.count
        return verses[index]
    }

    func verse(for date: Date) -> Verse? {
        VerseRotationService.verse(for: date, from: verses)
    }
}

// MARK: - File Wrapper Types

private struct VersesFile: Decodable {
    let version: String
    let verses: [Verse.JSONRepresentation]
}

private struct ExercisesFile: Decodable {
    let version: String
    let exercises: [Exercise.JSONRepresentation]
}

private struct BreathSessionsFile: Decodable {
    let version: String
    let sessions: [BreathSessionJSON]
}

private struct WODsFile: Decodable {
    let version: String
    let wods: [WODJSON]
}

// MARK: - JSON Representation Types

private struct BreathSessionJSON: Codable {
    let id: String
    let name: String
    let description: String?
    let phases: [BreathPhaseJSON]
    let rounds: Int
}

private struct BreathPhaseJSON: Codable {
    let type: String
    let duration: Int
}

private struct WODJSON: Codable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let timeCap: Int?
    let rounds: Int?
    let exercises: [WODExerciseJSON]
}

private struct WODExerciseJSON: Codable {
    let exerciseId: String
    let reps: Int?
    let duration: Int?
}
