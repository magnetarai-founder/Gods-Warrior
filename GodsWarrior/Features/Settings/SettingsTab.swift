import SwiftUI
import SwiftData

struct SettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var notificationsEnabled: Bool = true
    @State private var reminderTime: Date = Date()
    @State private var hapticEnabled: Bool = true
    @State private var soundEnabled: Bool = true
    @State private var showResetConfirmation: Bool = false

    private var userSettings: UserSettings? {
        settings.first
    }

    private var dayCount: Int {
        VerseRotationService.currentDayIndex + 1  // 1-based display
    }

    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                Section("Notifications") {
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            updateSetting { $0.notificationsEnabled = newValue }
                        }

                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newValue in
                                updateSetting { $0.dailyReminderTime = newValue }
                            }
                    }
                }

                // Feedback Section
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticEnabled)
                        .onChange(of: hapticEnabled) { _, newValue in
                            updateSetting { $0.hapticFeedbackEnabled = newValue }
                        }

                    Toggle("Sound Effects", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _, newValue in
                            updateSetting { $0.soundEffectsEnabled = newValue }
                        }
                }

                // Progress Section
                Section("Progress") {
                    HStack {
                        Text("Day")
                        Spacer()
                        Text("\(dayCount)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                    }

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset Progress")
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Theology Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Physical fitness is not vanity — it is an overflow of spiritual fitness.")
                            .font(.body.italic())

                        Text("\"Bodily exercise is profitable for a little.\" — 1 Timothy 4:8 (ASV)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .onAppear { loadSettings() }
            .confirmationDialog("Reset Progress?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your day counter and clear all progress. This cannot be undone.")
            }
        }
    }

    private func loadSettings() {
        if let settings = userSettings {
            notificationsEnabled = settings.notificationsEnabled
            reminderTime = settings.dailyReminderTime ?? Date()
            hapticEnabled = settings.hapticFeedbackEnabled
            soundEnabled = settings.soundEffectsEnabled
        }
    }

    private func updateSetting(_ update: (inout UserSettings) -> Void) {
        if var settingsToUpdate = settings.first {
            update(&settingsToUpdate)
            try? modelContext.save()
        }
    }

    private func resetProgress() {
        // Reset app start date to today
        UserDefaults.standard.removeObject(forKey: "godswarrior.appStartDate")

        // Update settings
        if var settings = settings.first {
            settings.appStartDate = Date()
            try? modelContext.save()
        }
    }
}

#Preview {
    SettingsTab()
}
