import Foundation

/// Manages deterministic verse rotation based on day count since app start
struct VerseRotationService {

    private static let appStartDateKey = "godswarrior.appStartDate"

    /// Get the app start date, creating one if first launch
    static var appStartDate: Date {
        if let timestamp = UserDefaults.standard.object(forKey: appStartDateKey) as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }

        // First launch - set today as start date
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: appStartDateKey)
        return now
    }

    /// Calculate days since app start (day 0, day 1, day 2...)
    static var currentDayIndex: Int {
        let calendar = Calendar.current
        let startOfAppStart = calendar.startOfDay(for: appStartDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfAppStart, to: startOfToday)
        return max(0, components.day ?? 0)
    }

    /// Get day index for a specific date
    static func dayIndex(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfAppStart = calendar.startOfDay(for: appStartDate)
        let startOfDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfAppStart, to: startOfDate)
        return max(0, components.day ?? 0)
    }

    /// Get today's verse from a collection
    static func todaysVerse(from verses: [Verse]) -> Verse? {
        guard !verses.isEmpty else { return nil }
        let index = currentDayIndex % verses.count
        return verses[index]
    }

    /// Get verse for a specific date
    static func verse(for date: Date, from verses: [Verse]) -> Verse? {
        guard !verses.isEmpty else { return nil }
        let index = dayIndex(for: date) % verses.count
        return verses[index]
    }
}
