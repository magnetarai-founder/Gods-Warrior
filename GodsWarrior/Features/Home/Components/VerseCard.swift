import SwiftUI

struct VerseCard: View {
    let verse: Verse?
    let hasNote: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Verse of the Day", systemImage: "book.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if hasNote {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let verse = verse {
                // Verse Text
                Text(verse.text)
                    .font(.body)
                    .lineLimit(4)

                // Reference
                Text(verse.reference)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Loading verse...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        VerseCard(
            verse: nil,
            hasNote: false
        )

        VerseCard(
            verse: nil,
            hasNote: true
        )
    }
    .padding()
}
