import SwiftUI

struct BreathCard: View {
    let session: BreathSession?
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Breath & Prayer", systemImage: "wind")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let session = session {
                // Session Name
                Text(session.name)
                    .font(.title3.weight(.semibold))

                // Pattern and duration
                HStack {
                    Text(session.patternString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("\(session.rounds) rounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("\(session.totalDuration / 60) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Action button
                if !isCompleted {
                    HStack {
                        Spacer()
                        Label("Start", systemImage: "play.fill")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text("No session selected")
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
        BreathCard(session: nil, isCompleted: false)
        BreathCard(session: nil, isCompleted: true)
    }
    .padding()
}
