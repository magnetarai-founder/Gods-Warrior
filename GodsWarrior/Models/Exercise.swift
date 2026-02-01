import SwiftData
import Foundation

@Model
final class Exercise {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var name: String
    var exerciseDescription: String  // 'description' is a reserved keyword
    var instructions: String?
    var category: ExerciseCategory

    // MARK: - Library Metadata
    var isLibrary: Bool

    // MARK: - Inverse Relationship
    @Relationship(inverse: \WODExercise.exercise)
    var wodExercises: [WODExercise]?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        instructions: String? = nil,
        category: ExerciseCategory,
        isLibrary: Bool = true
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.instructions = instructions
        self.category = category
        self.isLibrary = isLibrary
    }
}

// MARK: - Decodable Extension for JSON Loading

extension Exercise {
    struct JSONRepresentation: Codable {
        let id: String
        let name: String
        let description: String
        let instructions: String?
        let category: String
        let muscleGroups: [String]?

        func toExercise() -> Exercise {
            let cat = ExerciseCategory(rawValue: category) ?? .fullBody
            return Exercise(
                id: UUID(uuidString: id) ?? UUID(),
                name: name,
                description: description,
                instructions: instructions,
                category: cat,
                isLibrary: true
            )
        }
    }
}
