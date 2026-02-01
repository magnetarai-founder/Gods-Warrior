import SwiftUI

enum BreathPhaseType: String, Codable, CaseIterable {
    case inhale
    case holdIn      // Hold after inhale
    case exhale
    case holdOut     // Hold after exhale

    var displayName: String {
        switch self {
        case .inhale: return "Breathe In"
        case .holdIn: return "Hold"
        case .exhale: return "Breathe Out"
        case .holdOut: return "Hold"
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "INHALE"
        case .holdIn: return "HOLD"
        case .exhale: return "EXHALE"
        case .holdOut: return "HOLD"
        }
    }

    var icon: String {
        switch self {
        case .inhale: return "arrow.up.circle.fill"
        case .holdIn: return "pause.circle.fill"
        case .exhale: return "arrow.down.circle.fill"
        case .holdOut: return "pause.circle"
        }
    }

    var color: Color {
        switch self {
        case .inhale: return .blue
        case .holdIn: return .orange
        case .exhale: return .green
        case .holdOut: return .orange.opacity(0.7)
        }
    }
}
