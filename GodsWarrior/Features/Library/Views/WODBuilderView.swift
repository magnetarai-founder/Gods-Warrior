import SwiftUI
import SwiftData

struct WODBuilderView: View {
    @Environment(ContentStore.self) private var contentStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var wodName: String = ""
    @State private var selectedType: WODType = .amrap
    @State private var timeCap: Int = 12  // minutes
    @State private var rounds: Int = 4
    @State private var selectedExercises: [WODExerciseBuilder] = []
    @State private var showExercisePicker: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Workout Info") {
                    TextField("Workout Name", text: $wodName)

                    Picker("Type", selection: $selectedType) {
                        ForEach(WODType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                // Type-specific configuration
                Section("Configuration") {
                    switch selectedType {
                    case .amrap, .timeLimited:
                        Stepper("Time Cap: \(timeCap) min", value: $timeCap, in: 5...60, step: 1)
                    case .rounds:
                        Stepper("Rounds: \(rounds)", value: $rounds, in: 1...20)
                    case .tabata:
                        Text("20s work / 10s rest × 8 rounds per exercise")
                            .foregroundStyle(.secondary)
                    }
                }

                // Exercises
                Section {
                    ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, builder in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(builder.exercise.name)
                                    .font(.body.weight(.medium))

                                if let reps = builder.reps {
                                    Text("\(reps) reps")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let duration = builder.duration {
                                    Text("\(duration)s")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // Quick adjust
                            Menu {
                                Button("Set Reps") {
                                    selectedExercises[index].duration = nil
                                    selectedExercises[index].reps = 10
                                }
                                Button("Set Duration") {
                                    selectedExercises[index].reps = nil
                                    selectedExercises[index].duration = 30
                                }
                                Button("Remove", role: .destructive) {
                                    selectedExercises.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                    .onMove { from, to in
                        selectedExercises.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if selectedExercises.isEmpty {
                        Text("Add at least one exercise to create a workout.")
                    }
                }
            }
            .navigationTitle("Build Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWOD()
                    }
                    .disabled(wodName.isEmpty || selectedExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(exercises: contentStore.exercises) { exercise in
                    selectedExercises.append(WODExerciseBuilder(exercise: exercise, reps: 10))
                }
            }
        }
    }

    private func saveWOD() {
        var config: WODConfig = .default

        switch selectedType {
        case .amrap, .timeLimited:
            config = .amrap(timeCap: timeCap * 60)
        case .rounds:
            config = .rounds(rounds)
        case .tabata:
            config = .tabata()
        }

        let wod = WOD(
            name: wodName,
            wodType: selectedType,
            config: config,
            isLibrary: false
        )

        modelContext.insert(wod)

        for (index, builder) in selectedExercises.enumerated() {
            let wodExercise = WODExercise(
                exercise: builder.exercise,
                reps: builder.reps,
                duration: builder.duration,
                order: index
            )
            wodExercise.wod = wod
            modelContext.insert(wodExercise)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - WOD Exercise Builder

struct WODExerciseBuilder: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var reps: Int?
    var duration: Int?
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseCategory?

    var filteredExercises: [Exercise] {
        var result = exercises

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            List {
                // Category filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Exercise list
                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)

                                Text(exercise.category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    WODBuilderView()
        .environment(ContentStore())
}
