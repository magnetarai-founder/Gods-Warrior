import SwiftUI

struct WODCard: View {
    let wod: WOD?
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Workout of the Day", systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let wod = wod {
                // WOD Name
                Text(wod.name)
                    .font(.title3.weight(.semibold))

                // Type badge and exercise count
                HStack {
                    Text(wod.wodType.displayName)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundStyle(.accentColor)
                        .clipShape(Capsule())

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("\(wod.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(wod.estimatedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Exercise preview
                if !wod.sortedExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(wod.sortedExercises.prefix(3)) { exercise in
                            Text(exercise.displayString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if wod.exerciseCount > 3 {
                            Text("+ \(wod.exerciseCount - 3) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
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
                Text("No workout scheduled")
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
        WODCard(wod: nil, isCompleted: false)
        WODCard(wod: nil, isCompleted: true)
    }
    .padding()
}
