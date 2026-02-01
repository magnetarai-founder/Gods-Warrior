import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.godswarrior", category: "NavigationStore")

@MainActor
@Observable
final class NavigationStore {
    private static let tabKey = "godswarrior.lastActiveTab"
    private static let librarySegmentKey = "godswarrior.librarySegment"

    // MARK: - Tab Navigation

    var activeTab: Tab {
        didSet { saveTabState() }
    }

    // MARK: - Library Segment State

    var librarySegment: LibrarySegment {
        didSet { saveLibrarySegment() }
    }

    enum LibrarySegment: String, CaseIterable {
        case wod = "WOD"
        case breath = "Breath"
        case timer = "Timer"
    }

    // MARK: - Sheet Presentation

    var showVerseDetail: Bool = false
    var showBreathSession: Bool = false
    var showWODDetail: Bool = false
    var showWODBuilder: Bool = false
    var selectedWOD: WOD?
    var selectedBreathSession: BreathSession?

    // MARK: - Init

    init() {
        // Restore last active tab
        if let savedTab = UserDefaults.standard.string(forKey: Self.tabKey),
           let tab = Tab(rawValue: savedTab) {
            self.activeTab = tab
        } else {
            self.activeTab = .home
        }

        // Restore library segment
        if let savedSegment = UserDefaults.standard.string(forKey: Self.librarySegmentKey),
           let segment = LibrarySegment(rawValue: savedSegment) {
            self.librarySegment = segment
        } else {
            self.librarySegment = .wod
        }
    }

    // MARK: - Navigation Actions

    func navigate(to tab: Tab) {
        activeTab = tab
    }

    func openWODBuilder() {
        showWODBuilder = true
    }

    func openVerseDetail() {
        showVerseDetail = true
    }

    func openWODDetail(_ wod: WOD) {
        selectedWOD = wod
        showWODDetail = true
    }

    func openBreathSession(_ session: BreathSession) {
        selectedBreathSession = session
        showBreathSession = true
    }

    // MARK: - Persistence

    private func saveTabState() {
        UserDefaults.standard.set(activeTab.rawValue, forKey: Self.tabKey)
    }

    private func saveLibrarySegment() {
        UserDefaults.standard.set(librarySegment.rawValue, forKey: Self.librarySegmentKey)
    }
}
