import SwiftData
import Foundation

@Model
final class ExtraWorkout {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var workoutDescription: String
    var date: Date

    // MARK: - Parent LogEntry
    @Relationship(inverse: \LogEntry.extraWorkouts)
    var logEntry: LogEntry?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        description: String,
        date: Date = Date()
    ) {
        self.id = id
        self.workoutDescription = description
        self.date = date
    }
}
