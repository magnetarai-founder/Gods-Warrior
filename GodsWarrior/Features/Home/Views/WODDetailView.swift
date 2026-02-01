import SwiftUI

struct WODDetailView: View {
    let wod: WOD

    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showWorkoutExecution: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(wod.name)
                            .font(.largeTitle.bold())

                        HStack(spacing: 12) {
                            Text(wod.wodType.displayName)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.2))
                                .clipShape(Capsule())

                            Text("\(wod.exerciseCount) exercises")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(wod.estimatedDuration)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(wod.wodType.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.headline)

                        ForEach(Array(wod.sortedExercises.enumerated()), id: \.element.id) { index, wodExercise in
                            ExerciseRow(index: index + 1, wodExercise: wodExercise)
                        }
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            showWorkoutExecution = true
                        } label: {
                            Label("Start Workout", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if wod.isLibrary {
                            Button {
                                createCopy()
                            } label: {
                                Label("Customize", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showWorkoutExecution) {
                WorkoutExecutionView(wod: wod)
            }
        }
    }

    private func createCopy() {
        _ = wod.createUserCopy(modelContext: modelContext)
        try? modelContext.save()
        // TODO: Navigate to edit the copy
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let index: Int
    let wodExercise: WODExercise

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(wodExercise.exercise?.name ?? "Unknown Exercise")
                    .font(.body.weight(.medium))

                if let instructions = wodExercise.exercise?.instructions {
                    Text(instructions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Reps or duration
            if let reps = wodExercise.reps {
                Text("\(reps) reps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            } else if let duration = wodExercise.duration {
                Text("\(duration)s")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WODDetailView(wod: WOD(name: "Test WOD", wodType: .amrap))
}
