import SwiftUI

enum ExerciseCategory: String, Codable, CaseIterable {
    case upperBody
    case lowerBody
    case fullBody
    case core
    case cardio

    var displayName: String {
        switch self {
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .fullBody: return "Full Body"
        case .core: return "Core"
        case .cardio: return "Cardio"
        }
    }

    var icon: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.walk"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .upperBody: return .blue
        case .lowerBody: return .green
        case .fullBody: return .orange
        case .core: return .purple
        case .cardio: return .red
        }
    }
}
