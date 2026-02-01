import Foundation

/// A single phase in a breathing pattern
struct BreathPhase: Codable, Identifiable, Equatable {
    var id: UUID
    var phaseType: BreathPhaseType
    var duration: Int  // Duration in seconds

    init(id: UUID = UUID(), phaseType: BreathPhaseType, duration: Int) {
        self.id = id
        self.phaseType = phaseType
        self.duration = duration
    }
}

// MARK: - Common Patterns

extension BreathPhase {
    /// Box breathing pattern: 4-4-4-4
    static let boxBreathing: [BreathPhase] = [
        BreathPhase(phaseType: .inhale, duration: 4),
        BreathPhase(phaseType: .holdIn, duration: 4),
        BreathPhase(phaseType: .exhale, duration: 4),
        BreathPhase(phaseType: .holdOut, duration: 4)
    ]

    /// 4-7-8 relaxation pattern
    static let relaxation478: [BreathPhase] = [
        BreathPhase(phaseType: .inhale, duration: 4),
        BreathPhase(phaseType: .holdIn, duration: 7),
        BreathPhase(phaseType: .exhale, duration: 8)
    ]

    /// Simple breath pattern: inhale-exhale
    static let simple: [BreathPhase] = [
        BreathPhase(phaseType: .inhale, duration: 4),
        BreathPhase(phaseType: .exhale, duration: 4)
    ]

    /// Warrior breath: 5-5-5
    static let warrior: [BreathPhase] = [
        BreathPhase(phaseType: .inhale, duration: 5),
        BreathPhase(phaseType: .holdIn, duration: 5),
        BreathPhase(phaseType: .exhale, duration: 5)
    ]
}
