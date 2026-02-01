import SwiftData
import Foundation

@Model
final class Verse {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    var text: String
    var reference: String  // e.g., "Joshua 1:9"

    // MARK: - Metadata
    var theme: String?       // e.g., "courage", "strength", "endurance"
    var bookOrder: Int       // For sorting by biblical order
    var dayIndex: Int        // Which day this verse appears (0-based)
    var isLibrary: Bool      // true = curated, false = user-added

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        text: String,
        reference: String,
        theme: String? = nil,
        bookOrder: Int = 0,
        dayIndex: Int = 0,
        isLibrary: Bool = true
    ) {
        self.id = id
        self.text = text
        self.reference = reference
        self.theme = theme
        self.bookOrder = bookOrder
        self.dayIndex = dayIndex
        self.isLibrary = isLibrary
    }
}

// MARK: - Decodable Extension for JSON Loading

extension Verse {
    struct JSONRepresentation: Codable {
        let id: String
        let text: String
        let reference: String
        let theme: String?
        let bookOrder: Int?
        let dayIndex: Int

        func toVerse() -> Verse {
            Verse(
                id: UUID(uuidString: id) ?? UUID(),
                text: text,
                reference: reference,
                theme: theme,
                bookOrder: bookOrder ?? 0,
                dayIndex: dayIndex,
                isLibrary: true
            )
        }
    }
}
