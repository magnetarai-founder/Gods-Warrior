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
    var verse: Verse?
    var verseNote: String?

    // MARK: - Breath Section
    var breathSession: BreathSession?
    var breathCompleted: Bool
    var breathCompletedAt: Date?

    // MARK: - WOD Section
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

    var completionPercentage: Double {
        var completed = 0
        var total = 0

        if breathSession != nil {
            total += 1
            if breathCompleted { completed += 1 }
        }

        if wod != nil {
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
        verse: Verse? = nil,
        verseNote: String? = nil,
        breathSession: BreathSession? = nil,
        breathCompleted: Bool = false,
        wod: WOD? = nil,
        wodCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.dateKey = Self.dateKeyFormatter.string(from: date)
        self.verse = verse
        self.verseNote = verseNote
        self.breathSession = breathSession
        self.breathCompleted = breathCompleted
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
