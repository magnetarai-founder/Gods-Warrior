import SwiftUI

struct CalendarTab: View {
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedMonth: Date = Date()
    @State private var monthLogs: [LogEntry] = []
    @State private var selectedDay: Date?
    @State private var refreshTrigger: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Navigation
                MonthNavigationHeader(
                    currentMonth: selectedMonth,
                    onPrevious: { moveMonth(by: -1) },
                    onNext: { moveMonth(by: 1) }
                )
                .padding()

                // Weekday Headers
                WeekdayHeaderRow()
                    .padding(.horizontal)

                // Calendar Grid
                MonthGridView(
                    month: selectedMonth,
                    logs: monthLogs,
                    selectedDay: $selectedDay
                )
                .padding()

                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadMonthLogs() }
            .onChange(of: selectedMonth) { _, _ in loadMonthLogs() }
            .onChange(of: scenePhase) { _, newPhase in
                // Refresh when app becomes active
                if newPhase == .active {
                    loadMonthLogs()
                }
            }
            .onChange(of: selectedDay) { _, newDay in
                // Refresh after viewing day details (they might have changed)
                if newDay == nil {
                    loadMonthLogs()
                }
            }
            .sheet(item: $selectedDay) { day in
                DayLogDetailSheet(date: day)
            }
        }
    }

    private func moveMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func loadMonthLogs() {
        do {
            monthLogs = try dailyLogService.entries(for: selectedMonth)
        } catch {
            monthLogs = []
        }
    }
}

// MARK: - Month Navigation Header

struct MonthNavigationHeader: View {
    let currentMonth: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2.weight(.semibold))

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Weekday Header Row

struct WeekdayHeaderRow: View {
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Month Grid View

struct MonthGridView: View {
    let month: Date
    let logs: [LogEntry]
    @Binding var selectedDay: Date?

    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DayCell(
                        date: date,
                        log: logFor(date),
                        isSelected: selectedDay == date,
                        onTap: { selectedDay = date }
                    )
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
    }

    private func logFor(_ date: Date) -> LogEntry? {
        let dateKey = LogEntry.dateKey(for: date)
        return logs.first { $0.dateKey == dateKey }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let log: LogEntry?
    let isSelected: Bool
    let onTap: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)

                // Completion indicators
                HStack(spacing: 2) {
                    Circle()
                        .fill(log?.verseNote != nil ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Circle()
                        .fill(log?.breathCompleted == true ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)

                    Circle()
                        .fill(log?.wodCompleted == true ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : (isToday ? Color.accentColor.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}

// Make Date identifiable for sheet presentation
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Day Log Detail Sheet

struct DayLogDetailSheet: View {
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var log: LogEntry?
    @State private var noteText: String = ""

    // MARK: - Computed Content Properties

    private var verseData: VerseData? {
        // Check custom verse first
        if let verse = log?.verse {
            return VerseData(from: verse)
        }
        // Then curated ID
        if let verseId = log?.curatedVerseId {
            return contentStore.verseData.first { $0.id == verseId }
        }
        return nil
    }

    private var breathSessionName: String? {
        // Check custom session first
        if let session = log?.breathSession {
            return session.name
        }
        // Then curated ID
        if let sessionId = log?.curatedBreathSessionId {
            return contentStore.breathSessionData.first { $0.id == sessionId }?.name
        }
        return nil
    }

    private var wodName: String? {
        // Check custom WOD first
        if let wod = log?.wod {
            return wod.name
        }
        // Then curated ID
        if let wodId = log?.curatedWodId {
            return contentStore.wodData.first { $0.id == wodId }?.name
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            List {
                // Date Header
                Section {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                }

                // Verse Section
                Section("Verse") {
                    if let verse = verseData {
                        Text(verse.text)
                            .font(.body)
                        Text(verse.reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No verse assigned")
                            .foregroundStyle(.secondary)
                    }

                    TextField("Your reflection...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Breath Section
                Section("Breath") {
                    HStack {
                        if let name = breathSessionName {
                            Text(name)
                        } else {
                            Text("Not started")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if log?.breathCompleted == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }

                // WOD Section
                Section("Workout") {
                    HStack {
                        if let name = wodName {
                            Text(name)
                        } else {
                            Text("Not started")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if log?.wodCompleted == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    if let summary = log?.wodSummary {
                        Text(summary.displayString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Notes Section
                Section("Notes") {
                    TextField("Additional notes...", text: Binding(
                        get: { log?.notes ?? "" },
                        set: { newValue in
                            if let log = log {
                                dailyLogService.updateNotes(newValue.isEmpty ? nil : newValue, for: log)
                            }
                        }
                    ), axis: .vertical)
                    .lineLimit(3...10)
                }
            }
            .navigationTitle("Day Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveNote()
                        dismiss()
                    }
                }
            }
            .onAppear { loadLog() }
        }
    }

    private func loadLog() {
        do {
            log = try dailyLogService.getOrCreateEntry(for: date)
            noteText = log?.verseNote ?? ""
        } catch {
            log = nil
        }
    }

    private func saveNote() {
        if let log = log {
            dailyLogService.updateVerseNote(noteText.isEmpty ? nil : noteText, for: log)
        }
    }
}

#Preview {
    CalendarTab()
}
