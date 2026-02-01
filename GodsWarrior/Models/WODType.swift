import Foundation

enum WODType: String, Codable, CaseIterable {
    case amrap      // As Many Rounds As Possible
    case tabata     // 20s work / 10s rest intervals
    case rounds     // Fixed rounds, user-paced
    case timeLimited // Complete circuit within time limit

    var displayName: String {
        switch self {
        case .amrap: return "AMRAP"
        case .tabata: return "Tabata"
        case .rounds: return "For Rounds"
        case .timeLimited: return "For Time"
        }
    }

    var description: String {
        switch self {
        case .amrap:
            return "Complete as many rounds as possible within the time limit"
        case .tabata:
            return "20 seconds work, 10 seconds rest per exercise"
        case .rounds:
            return "Complete the prescribed number of rounds at your own pace"
        case .timeLimited:
            return "Complete the circuit as fast as possible within the time cap"
        }
    }

    var icon: String {
        switch self {
        case .amrap: return "repeat"
        case .tabata: return "timer"
        case .rounds: return "arrow.clockwise"
        case .timeLimited: return "stopwatch"
        }
    }
}
