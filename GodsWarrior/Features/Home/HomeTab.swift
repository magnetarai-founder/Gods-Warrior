import SwiftUI

struct HomeTab: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService
    @Environment(\.modelContext) private var modelContext

    // MARK: - Computed Properties for Card Data

    private var verseForCard: VerseData? {
        let log = dailyLogService.todayLog
        // First check for custom verse (SwiftData model)
        if let verse = log?.verse {
            return VerseData(from: verse)
        }
        // Then check for curated verse ID on log
        if let verseId = log?.curatedVerseId {
            return contentStore.verseData.first { $0.id == verseId }
        }
        // Fallback to today's verse from content store
        return contentStore.todaysVerse
    }

    private var breathSessionForCard: BreathSessionData? {
        let log = dailyLogService.todayLog
        // First check for custom session (SwiftData model)
        if let session = log?.breathSession {
            return BreathSessionData(from: session)
        }
        // Then check for curated session ID on log
        if let sessionId = log?.curatedBreathSessionId {
            return contentStore.breathSessionData.first { $0.id == sessionId }
        }
        // Fallback to default session from content store
        return contentStore.defaultBreathSession
    }

    private var wodForCard: WODData? {
        let log = dailyLogService.todayLog
        // First check for custom WOD (SwiftData model)
        if let wod = log?.wod {
            return WODData(from: wod)
        }
        // Then check for curated WOD ID on log
        if let wodId = log?.curatedWodId {
            return contentStore.wodData.first { $0.id == wodId }
        }
        // Fallback to today's WOD from content store
        return contentStore.todaysWOD
    }

    // MARK: - Navigation Helpers

    private func openBreathSession() {
        if let session = dailyLogService.todayLog?.breathSession {
            navigationStore.openBreathSession(session)
        } else if let sessionData = contentStore.defaultBreathSession {
            navigationStore.openBreathSession(sessionData)
        }
    }

    private func openWODDetail() {
        if let wod = dailyLogService.todayLog?.wod {
            navigationStore.openWODDetail(wod)
        } else if let wodData = contentStore.todaysWOD {
            navigationStore.openWODDetail(wodData)
        }
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
                        isCompleted: dailyLogService.todayLog?.breathCompleted ?? false,
                        onStart: {
                            openBreathSession()
                        }
                    )
                    .onTapGesture {
                        openBreathSession()
                    }

                    // WOD Card
                    WODCard(
                        wod: wodForCard,
                        isCompleted: dailyLogService.todayLog?.wodCompleted ?? false,
                        onStart: {
                            openWODDetail()
                        }
                    )
                    .onTapGesture {
                        openWODDetail()
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
                    BreathSessionView(session: BreathSessionData(from: session))
                } else if let sessionData = navigationStore.selectedBreathSessionData {
                    BreathSessionView(session: sessionData)
                }
            }
            .sheet(isPresented: Binding(
                get: { navigationStore.showWODDetail },
                set: { navigationStore.showWODDetail = $0 }
            )) {
                if let wod = navigationStore.selectedWOD {
                    WODDetailView(wod: WODData(from: wod))
                } else if let wodData = navigationStore.selectedWODData {
                    WODDetailView(wod: wodData)
                }
            }
            .onAppear {
                // Initialize today's log entry with curated content
                dailyLogService.initializeTodayContent(with: contentStore)
            }
        }
    }
}

#Preview {
    HomeTab()
        .environment(NavigationStore())
        .environment(ContentStore())
}
