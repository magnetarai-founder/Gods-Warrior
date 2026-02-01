import SwiftData
import Foundation

@Model
final class WODExercise {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID

    // MARK: - Relationship to Exercise
    var exercise: Exercise?

    // MARK: - Configuration
    var reps: Int?           // Number of reps (nil if duration-based)
    var duration: Int?       // Duration in seconds (nil if rep-based)
    var order: Int           // Position in WOD sequence

    // MARK: - Parent WOD
    @Relationship(inverse: \WOD.exercises)
    var wod: WOD?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        reps: Int? = nil,
        duration: Int? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.exercise = exercise
        self.reps = reps
        self.duration = duration
        self.order = order
    }

    // MARK: - Computed Properties

    var isTimeBased: Bool {
        duration != nil
    }

    var displayString: String {
        guard let exercise = exercise else { return "Unknown" }

        if let reps = reps {
            return "\(reps) \(exercise.name)"
        } else if let duration = duration {
            return "\(duration)s \(exercise.name)"
        } else {
            return exercise.name
        }
    }
}
