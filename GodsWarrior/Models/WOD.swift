import SwiftData
import Foundation

@Model
final class WOD {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var name: String
    var wodType: WODType

    // MARK: - Configuration (stored as JSON)
    var configData: Data?

    // MARK: - Library & Copy Tracking
    var isLibrary: Bool           // true = curated template
    var sourceLibraryId: UUID?    // If copied from library, references original
    var createdDate: Date

    // MARK: - Exercises
    @Relationship(deleteRule: .cascade)
    var exercises: [WODExercise] = []

    // MARK: - Computed Config

    var config: WODConfig {
        get {
            guard let data = configData else { return .default }
            return (try? JSONDecoder().decode(WODConfig.self, from: data)) ?? .default
        }
        set {
            configData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        wodType: WODType,
        config: WODConfig = .default,
        isLibrary: Bool = false,
        sourceLibraryId: UUID? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.wodType = wodType
        self.configData = try? JSONEncoder().encode(config)
        self.isLibrary = isLibrary
        self.sourceLibraryId = sourceLibraryId
        self.createdDate = createdDate
    }

    // MARK: - Copy-on-Edit

    /// Creates a user-editable copy of a library WOD
    func createUserCopy(modelContext: ModelContext) -> WOD {
        let copy = WOD(
            name: self.name,
            wodType: self.wodType,
            config: self.config,
            isLibrary: false,
            sourceLibraryId: self.isLibrary ? self.id : self.sourceLibraryId,
            createdDate: Date()
        )

        modelContext.insert(copy)

        // Deep copy exercises
        for wodExercise in exercises.sorted(by: { $0.order < $1.order }) {
            let exerciseCopy = WODExercise(
                exercise: wodExercise.exercise,  // Reference same exercise
                reps: wodExercise.reps,
                duration: wodExercise.duration,
                order: wodExercise.order
            )
            exerciseCopy.wod = copy
            modelContext.insert(exerciseCopy)
        }

        return copy
    }

    // MARK: - Computed Properties

    var sortedExercises: [WODExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var exerciseCount: Int {
        exercises.count
    }

    var estimatedDuration: String {
        switch wodType {
        case .amrap, .timeLimited:
            if let timeCap = config.timeCap {
                return "\(timeCap / 60) min"
            }
            return "Variable"
        case .tabata:
            let workTime = (config.workInterval ?? 20) * exercises.count * 8
            let restTime = (config.restInterval ?? 10) * exercises.count * 8
            let total = (workTime + restTime) / 60
            return "\(total) min"
        case .rounds:
            return "\(config.rounds ?? 1) rounds"
        }
    }
}
