import SwiftUI

struct WODDetailView: View {
    let wod: WODData

    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
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

                        ForEach(Array(wod.exercises.enumerated()), id: \.element.id) { index, wodExercise in
                            ExerciseDataRow(
                                index: index + 1,
                                wodExercise: wodExercise,
                                exerciseName: exerciseName(for: wodExercise.exerciseId)
                            )
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

    private func exerciseName(for exerciseId: String) -> String {
        contentStore.exercise(byId: exerciseId)?.name ?? exerciseId.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

// MARK: - Exercise Data Row

struct ExerciseDataRow: View {
    let index: Int
    let wodExercise: WODExerciseData
    let exerciseName: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.body.weight(.medium))
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
    WODDetailView(wod: WODData(
        id: "preview",
        name: "Test WOD",
        description: "A test workout",
        type: "amrap",
        timeCap: 600,
        rounds: nil,
        exercises: [
            WODExerciseData(exerciseId: "pushup-standard", reps: 10, duration: nil),
            WODExerciseData(exerciseId: "squat-air", reps: 15, duration: nil)
        ]
    ))
    .environment(ContentStore())
}
