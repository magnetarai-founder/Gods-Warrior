import SwiftUI

struct HomeTab: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Verse Card
                    VerseCard(
                        verse: dailyLogService.todayLog?.verse ?? contentStore.todaysVerse,
                        hasNote: dailyLogService.todayLog?.verseNote != nil
                    )
                    .onTapGesture {
                        navigationStore.openVerseDetail()
                    }

                    // Breath Card
                    BreathCard(
                        session: dailyLogService.todayLog?.breathSession ?? contentStore.defaultBreathSession,
                        isCompleted: dailyLogService.todayLog?.breathCompleted ?? false
                    )
                    .onTapGesture {
                        if let session = dailyLogService.todayLog?.breathSession ?? contentStore.defaultBreathSession {
                            navigationStore.openBreathSession(session)
                        }
                    }

                    // WOD Card
                    WODCard(
                        wod: dailyLogService.todayLog?.wod ?? contentStore.todaysWOD,
                        isCompleted: dailyLogService.todayLog?.wodCompleted ?? false
                    )
                    .onTapGesture {
                        if let wod = dailyLogService.todayLog?.wod ?? contentStore.todaysWOD {
                            navigationStore.openWODDetail(wod)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("God's Warrior")
            .sheet(isPresented: Binding(
                get: { navigationStore.showVerseDetail },
                set: { navigationStore.showVerseDetail = $0 }
            )) {
                VerseDetailView()
            }
            .fullScreenCover(isPresented: Binding(
                get: { navigationStore.showBreathSession },
                set: { navigationStore.showBreathSession = $0 }
            )) {
                if let session = navigationStore.selectedBreathSession {
                    BreathSessionView(session: session)
                }
            }
            .sheet(isPresented: Binding(
                get: { navigationStore.showWODDetail },
                set: { navigationStore.showWODDetail = $0 }
            )) {
                if let wod = navigationStore.selectedWOD {
                    WODDetailView(wod: wod)
                }
            }
        }
    }
}

#Preview {
    HomeTab()
        .environment(NavigationStore())
        .environment(ContentStore())
}
