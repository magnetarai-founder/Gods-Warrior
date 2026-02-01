import SwiftData
import Foundation

@Model
final class UserSettings {
    // MARK: - Identity (Singleton pattern - only one instance)
    @Attribute(.unique) var id: UUID

    // MARK: - Default Selections
    var defaultBreathSession: BreathSession?

    // MARK: - Notifications
    var notificationsEnabled: Bool
    var dailyReminderTime: Date?  // Time component only

    // MARK: - App State
    var appStartDate: Date  // First launch date, used for verse rotation

    // MARK: - Preferences
    var hapticFeedbackEnabled: Bool
    var soundEffectsEnabled: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        defaultBreathSession: BreathSession? = nil,
        notificationsEnabled: Bool = true,
        dailyReminderTime: Date? = nil,
        appStartDate: Date = Date(),
        hapticFeedbackEnabled: Bool = true,
        soundEffectsEnabled: Bool = true
    ) {
        self.id = id
        self.defaultBreathSession = defaultBreathSession
        self.notificationsEnabled = notificationsEnabled
        self.dailyReminderTime = dailyReminderTime
        self.appStartDate = appStartDate
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.soundEffectsEnabled = soundEffectsEnabled
    }
}
