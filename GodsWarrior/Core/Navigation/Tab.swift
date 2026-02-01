import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home
    case calendar
    case library
    case settings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .calendar: return "calendar"
        case .library: return "books.vertical"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .library: return "books.vertical.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
