import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: "com.godswarrior", category: "LibrarySeeder")

/// Seeds the database with curated library content on first launch
struct LibrarySeeder {
    let modelContext: ModelContext

    func seedIfNeeded() throws {
        // Check if already seeded
        let verseDescriptor = FetchDescriptor<Verse>(
            predicate: #Predicate { $0.isLibrary == true }
        )

        if try modelContext.fetchCount(verseDescriptor) > 0 {
            logger.info("Library content already seeded")
            return
        }

        logger.info("Seeding library content...")

        try seedBreathSessions()
        try seedUserSettings()

        try modelContext.save()
        logger.info("Library seeding complete")
    }

    // MARK: - Breath Sessions

    private func seedBreathSessions() throws {
        let sessions = [
            BreathSession.boxBreathing(),
            BreathSession.warriorBreath(),
            BreathSession.beforeBattle(),
            BreathSession.morningDedication()
        ]

        for session in sessions {
            modelContext.insert(session)
        }

        logger.info("Seeded \(sessions.count) breath sessions")
    }

    // MARK: - User Settings

    private func seedUserSettings() throws {
        // Find the default breath session
        let descriptor = FetchDescriptor<BreathSession>(
            predicate: #Predicate { $0.isDefault == true }
        )

        let defaultSession = try modelContext.fetch(descriptor).first

        let settings = UserSettings(
            defaultBreathSession: defaultSession,
            notificationsEnabled: true,
            appStartDate: Date()
        )

        modelContext.insert(settings)
        logger.info("Seeded user settings")
    }
}
