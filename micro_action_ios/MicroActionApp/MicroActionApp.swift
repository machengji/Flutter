import SwiftUI

@main
struct MicroActionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var proStore = ProStoreService()
    @State private var showLaunchSplash: Bool = true

    init() {
        _ = AppleEcoService.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
        }
    }
}
