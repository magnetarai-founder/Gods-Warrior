import Foundation

/// Configuration for WOD parameters - stored as JSON in WOD model
struct WODConfig: Codable, Equatable {
    var timeCap: Int?            // Time cap in seconds (for AMRAP, TimeLimited)
    var rounds: Int?             // Number of rounds (for Rounds type)
    var restBetweenRounds: Int?  // Rest in seconds between rounds
    var workInterval: Int?       // Work interval in seconds (for Tabata)
    var restInterval: Int?       // Rest interval in seconds (for Tabata)

    static let `default` = WODConfig()

    // MARK: - Convenience Initializers

    static func amrap(timeCap: Int) -> WODConfig {
        WODConfig(timeCap: timeCap)
    }

    static func tabata(workInterval: Int = 20, restInterval: Int = 10) -> WODConfig {
        WODConfig(workInterval: workInterval, restInterval: restInterval)
    }

    static func rounds(_ count: Int, restBetween: Int? = nil) -> WODConfig {
        WODConfig(rounds: count, restBetweenRounds: restBetween)
    }

    static func forTime(timeCap: Int) -> WODConfig {
        WODConfig(timeCap: timeCap)
    }
}

/// Summary of completed WOD performance
struct WODSummary: Codable, Equatable {
    var totalTime: Int?         // Total time in seconds
    var roundsCompleted: Int?   // For AMRAP
    var repsCompleted: Int?     // Additional reps in partial round
    var notes: String?          // Performance notes

    var displayString: String {
        var parts: [String] = []

        if let rounds = roundsCompleted {
            if let reps = repsCompleted, reps > 0 {
                parts.append("\(rounds)+\(reps) rounds")
            } else {
                parts.append("\(rounds) rounds")
            }
        }

        if let time = totalTime {
            let minutes = time / 60
            let seconds = time % 60
            parts.append(String(format: "%d:%02d", minutes, seconds))
        }

        return parts.isEmpty ? "Completed" : parts.joined(separator: " in ")
    }
}
