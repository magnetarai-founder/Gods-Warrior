import SwiftUI

struct MainTabView: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(ContentStore.self) private var contentStore
    @Environment(DailyLogService.self) private var dailyLogService

    var body: some View {
        @Bindable var nav = navigationStore

        TabView(selection: $nav.activeTab) {
            HomeTab()
                .tabItem {
                    Label(Tab.home.displayName,
                          systemImage: nav.activeTab == .home ? Tab.home.selectedIcon : Tab.home.icon)
                }
                .tag(Tab.home)

            CalendarTab()
                .tabItem {
                    Label(Tab.calendar.displayName,
                          systemImage: nav.activeTab == .calendar ? Tab.calendar.selectedIcon : Tab.calendar.icon)
                }
                .tag(Tab.calendar)

            LibraryTab()
                .tabItem {
                    Label(Tab.library.displayName,
                          systemImage: nav.activeTab == .library ? Tab.library.selectedIcon : Tab.library.icon)
                }
                .tag(Tab.library)

            SettingsTab()
                .tabItem {
                    Label(Tab.settings.displayName,
                          systemImage: nav.activeTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .environment(NavigationStore())
        .environment(ContentStore())
}
