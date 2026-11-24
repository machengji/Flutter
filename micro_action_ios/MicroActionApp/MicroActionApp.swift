import SwiftUI

@main
struct MicroActionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var proStore = ProStoreService()
    @State private var showLaunchSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = AppleEcoService.shared
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()

        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithTransparentBackground()
        scrolled.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        scrolled.backgroundColor = UIColor(red: 0.94, green: 0.97, blue: 0.95, alpha: 0.42)
        scrolled.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = scrolled
        UINavigationBar.appearance().compactAppearance = scrolled
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge
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
