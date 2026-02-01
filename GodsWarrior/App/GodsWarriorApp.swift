import SwiftUI
import SwiftData

@main
struct GodsWarriorApp: App {
    let modelContainer: ModelContainer

    @State private var navigationStore = NavigationStore()
    @State private var contentStore = ContentStore()

    init() {
        do {
            let schema = Schema([
                Verse.self,
                Exercise.self,
                WODExercise.self,
                WOD.self,
                BreathSession.self,
                ExtraWorkout.self,
                LogEntry.self,
                UserSettings.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Seed library content on first launch
            let context = modelContainer.mainContext
            let seeder = LibrarySeeder(modelContext: context)
            try seeder.seedIfNeeded()

        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(navigationStore)
                .environment(contentStore)
        }
        .modelContainer(modelContainer)
    }
}
