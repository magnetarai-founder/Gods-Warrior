import Foundation
import SwiftData
import Observation
import os

private let logger = Logger(subsystem: "com.godswarrior", category: "DailyLogService")

/// Manages LogEntry operations as the single source of truth
@MainActor
@Observable
final class DailyLogService {
    private let modelContext: ModelContext

    // MARK: - Published State

    private(set) var todayLog: LogEntry?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodayLog()
    }

    // MARK: - Fetch or Create Today's Entry

    private func loadTodayLog() {
        do {
            todayLog = try getOrCreateEntry(for: Date())
        } catch {
            logger.error("Failed to load today's log: \(error.localizedDescription)")
        }
    }

    func getOrCreateEntry(for date: Date = Date()) throws -> LogEntry {
        let dateKey = LogEntry.dateKey(for: date)

        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.dateKey == dateKey }
        )

        let entries = try modelContext.fetch(descriptor)

        if let existing = entries.first {
            return existing
        }

        // Create new entry
        let entry = LogEntry(date: date)
        modelContext.insert(entry)
        try modelContext.save()

        logger.info("Created new LogEntry for \(dateKey)")
        return entry
    }

    // MARK: - Verse Operations

    func setVerse(_ verse: Verse, for entry: LogEntry) {
        entry.verse = verse
        entry.touch()
        saveContext()
    }

    func updateVerseNote(_ note: String?, for entry: LogEntry) {
        entry.verseNote = note
        entry.touch()
        saveContext()
    }

    // MARK: - Breath Operations

    func setBreathSession(_ session: BreathSession, for entry: LogEntry) {
        entry.breathSession = session
        entry.touch()
        saveContext()
    }

    func markBreathCompleted(for entry: LogEntry) {
        entry.breathCompleted = true
        entry.breathCompletedAt = Date()
        entry.touch()
        saveContext()
        logger.info("Marked breath completed for \(entry.dateKey)")
    }

    // MARK: - WOD Operations

    func setWOD(_ wod: WOD, for entry: LogEntry) {
        entry.wod = wod
        entry.touch()
        saveContext()
    }

    func markWODCompleted(for entry: LogEntry, summary: WODSummary) {
        entry.wodCompleted = true
        entry.wodCompletedAt = Date()
        entry.wodSummary = summary
        entry.touch()
        saveContext()
        logger.info("Marked WOD completed for \(entry.dateKey): \(summary.displayString)")
    }

    // MARK: - Extra Workouts

    func addExtraWorkout(to entry: LogEntry, description: String) {
        let workout = ExtraWorkout(description: description, date: entry.date)
        workout.logEntry = entry
        modelContext.insert(workout)
        entry.touch()
        saveContext()
    }

    func removeExtraWorkout(_ workout: ExtraWorkout, from entry: LogEntry) {
        modelContext.delete(workout)
        entry.touch()
        saveContext()
    }

    // MARK: - Notes

    func updateNotes(_ notes: String?, for entry: LogEntry) {
        entry.notes = notes
        entry.touch()
        saveContext()
    }

    // MARK: - Calendar Queries

    func entries(for month: Date) throws -> [LogEntry] {
        let calendar = Calendar.current
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return []
        }

        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor)
    }

    func currentStreak() throws -> Int {
        let descriptor = FetchDescriptor<LogEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let entries = try modelContext.fetch(descriptor)
        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for entry in entries {
            if entry.date == expectedDate && entry.isFullyCompleted {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if entry.date < expectedDate {
                break
            }
        }

        return streak
    }

    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
