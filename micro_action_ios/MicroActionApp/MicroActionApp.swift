import SwiftUI

@main
struct MicroActionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var proStore = ProStoreService()
    @State private var showLaunchSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = AppleEcoService.shared
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(hex: 0xEFF8F2)
                    .ignoresSafeArea()

                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(proStore)

                if showLaunchSplash {
                    LaunchSplashOverlay {
                        showLaunchSplash = false
                    }
                    .zIndex(1000)
                }
            }
            .preferredColorScheme(.light)
            .onOpenURL { url in
                showLaunchSplash = false
                appState.handleWidgetDeepLink(url)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active || newPhase == .inactive || newPhase == .background {
                    appState.syncWidgetSnapshot()
                }
            }
        }
    }
}
