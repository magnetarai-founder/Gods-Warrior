import SwiftUI

struct HomeTab: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.modelContext) private var modelContext

    // MARK: - Computed Properties for Card Data

    private var verseForCard: VerseData? {
        if let verse = dailyLogService.todayLog?.verse {
            return VerseData(from: verse)
        }
        return contentStore.todaysVerse
    }

    private var breathSessionForCard: BreathSessionData? {
        if let session = dailyLogService.todayLog?.breathSession {
            return BreathSessionData(from: session)
        }
        return contentStore.defaultBreathSession
    }

    private var wodForCard: WODData? {
        if let wod = dailyLogService.todayLog?.wod {
            return WODData(from: wod)
        }
        return contentStore.todaysWOD
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Verse Card
                    VerseCard(
                        verse: verseForCard,
                        hasNote: dailyLogService.todayLog?.verseNote != nil
                    )
                    .onTapGesture {
                        navigationStore.openVerseDetail()
                    }

                    // Breath Card
                    BreathCard(
                        session: breathSessionForCard,
                        isCompleted: dailyLogService.todayLog?.breathCompleted ?? false
                    )
                    .onTapGesture {
                        if let session = dailyLogService.todayLog?.breathSession {
                            navigationStore.openBreathSession(session)
                        }
                    }

                    // WOD Card
                    WODCard(
                        wod: wodForCard,
                        isCompleted: dailyLogService.todayLog?.wodCompleted ?? false
                    )
                    .onTapGesture {
                        if let wod = dailyLogService.todayLog?.wod {
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
