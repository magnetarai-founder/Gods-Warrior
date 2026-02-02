import SwiftUI

struct VerseDetailView: View {
    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.dismiss) private var dismiss

    @State private var noteText: String = ""

    private var verse: VerseData? {
        if let logVerse = dailyLogService.todayLog?.verse {
            return VerseData(from: logVerse)
        }
        return contentStore.todaysVerse
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Verse Display
                    if let verse = verse {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(verse.text)
                                .font(.title3)
                                .lineSpacing(8)

                            Text(verse.reference)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if let theme = verse.theme {
                                Text(theme.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Reflection Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Reflection")
                            .font(.headline)

                        TextEditor(text: $noteText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("What does this verse speak to you today?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Verse of the Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                }
            }
            .onAppear {
                noteText = dailyLogService.todayLog?.verseNote ?? ""
            }
        }
    }

    private func saveNote() {
        if let log = dailyLogService.todayLog {
            dailyLogService.updateVerseNote(noteText.isEmpty ? nil : noteText, for: log)
        }
    }
}

#Preview {
    VerseDetailView()
        .environment(ContentStore())
}
