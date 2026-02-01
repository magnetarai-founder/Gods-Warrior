import SwiftData
import Foundation

@Model
final class BreathSession {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var name: String
    var sessionDescription: String?

    // MARK: - Pattern Configuration (stored as JSON)
    var phasesData: Data?
    var rounds: Int

    // MARK: - Library Metadata
    var isDefault: Bool    // Is this the system default session?
    var isLibrary: Bool    // Curated vs user-created

    // MARK: - Computed Phases

    var phases: [BreathPhase] {
        get {
            guard let data = phasesData else { return [] }
            return (try? JSONDecoder().decode([BreathPhase].self, from: data)) ?? []
        }
        set {
            phasesData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Computed Properties

    var totalDurationPerRound: Int {
        phases.reduce(0) { $0 + $1.duration }
    }

    var totalDuration: Int {
        totalDurationPerRound * rounds
    }

    var patternString: String {
        phases.map { "\($0.duration)s" }.joined(separator: " / ")
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        phases: [BreathPhase] = [],
        rounds: Int = 1,
        isDefault: Bool = false,
        isLibrary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sessionDescription = description
        self.phasesData = try? JSONEncoder().encode(phases)
        self.rounds = rounds
        self.isDefault = isDefault
        self.isLibrary = isLibrary
    }

    // MARK: - Default Sessions

    static func boxBreathing() -> BreathSession {
        BreathSession(
            name: "Box Breathing",
            description: "4-4-4-4 tactical breathing for calm and focus",
            phases: BreathPhase.boxBreathing,
            rounds: 5,
            isDefault: true,
            isLibrary: true
        )
    }

    static func warriorBreath() -> BreathSession {
        BreathSession(
            name: "Warrior Breath",
            description: "5-5-5 breathing for strength and endurance",
            phases: BreathPhase.warrior,
            rounds: 7,
            isLibrary: true
        )
    }

    static func beforeBattle() -> BreathSession {
        BreathSession(
            name: "Before Battle",
            description: "4-7-8 calming pattern to prepare for challenges",
            phases: BreathPhase.relaxation478,
            rounds: 4,
            isLibrary: true
        )
    }

    static func morningDedication() -> BreathSession {
        BreathSession(
            name: "Morning Dedication",
            description: "Simple breath focus for morning prayer",
            phases: BreathPhase.simple,
            rounds: 10,
            isLibrary: true
        )
    }
}
