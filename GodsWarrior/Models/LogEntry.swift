import SwiftData
import Foundation

/// Single Source of Truth for daily activity tracking.
/// One LogEntry exists per day. Home, Calendar, and all detail views read/write to this model.
@Model
final class LogEntry {
    // MARK: - Identity (Date as Key)
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var dateKey: String  // "YYYY-MM-DD" format for uniqueness
    var date: Date  // Normalized to midnight

    // MARK: - Verse Section
    /// Curated verse ID (from bundled JSON)
    var curatedVerseId: String?
    /// User-created verse (SwiftData model)
    var verse: Verse?
    var verseNote: String?

    // MARK: - Breath Section
    /// Curated breath session ID (from bundled JSON)
    var curatedBreathSessionId: String?
    /// User-created breath session (SwiftData model)
    var breathSession: BreathSession?
    var breathCompleted: Bool
    var breathCompletedAt: Date?

    // MARK: - WOD Section
    /// Curated WOD ID (from bundled JSON)
    var curatedWodId: String?
    /// User-created WOD (SwiftData model)
    var wod: WOD?
    var wodCompleted: Bool
    var wodCompletedAt: Date?
    var wodSummaryData: Data?  // Encoded WODSummary

    // MARK: - Extra Workouts
    @Relationship(deleteRule: .cascade)
    var extraWorkouts: [ExtraWorkout] = []

    // MARK: - General Notes
    var notes: String?

    // MARK: - Metadata
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed WOD Summary

    var wodSummary: WODSummary? {
        get {
            guard let data = wodSummaryData else { return nil }
            return try? JSONDecoder().decode(WODSummary.self, from: data)
        }
        set {
            wodSummaryData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Computed Completion Status

    var isFullyCompleted: Bool {
        breathCompleted && wodCompleted
    }

    /// Whether this entry has a verse (curated or custom)
    var hasVerse: Bool {
        curatedVerseId != nil || verse != nil
    }

    /// Whether this entry has a breath session (curated or custom)
    var hasBreathSession: Bool {
        curatedBreathSessionId != nil || breathSession != nil
    }

    /// Whether this entry has a WOD (curated or custom)
    var hasWOD: Bool {
        curatedWodId != nil || wod != nil
    }

    var completionPercentage: Double {
        var completed = 0
        var total = 0

        if hasBreathSession {
            total += 1
            if breathCompleted { completed += 1 }
        }

        if hasWOD {
            total += 1
            if wodCompleted { completed += 1 }
        }

        return total > 0 ? Double(completed) / Double(total) : 0
    }

    var hasAnyActivity: Bool {
        breathCompleted || wodCompleted || verseNote != nil || !extraWorkouts.isEmpty
    }

    // MARK: - Initialization

    init(
        date: Date,
        curatedVerseId: String? = nil,
        verse: Verse? = nil,
        verseNote: String? = nil,
        curatedBreathSessionId: String? = nil,
        breathSession: BreathSession? = nil,
        breathCompleted: Bool = false,
        curatedWodId: String? = nil,
        wod: WOD? = nil,
        wodCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.dateKey = Self.dateKeyFormatter.string(from: date)
        self.curatedVerseId = curatedVerseId
        self.verse = verse
        self.verseNote = verseNote
        self.curatedBreathSessionId = curatedBreathSessionId
        self.breathSession = breathSession
        self.breathCompleted = breathCompleted
        self.curatedWodId = curatedWodId
        self.wod = wod
        self.wodCompleted = wodCompleted
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Date Key Management

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static func dateKey(for date: Date) -> String {
        dateKeyFormatter.string(from: date)
    }

    // MARK: - Touch (Update Timestamp)

    func touch() {
        updatedAt = Date()
    }
}
