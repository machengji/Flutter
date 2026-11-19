import SwiftUI

@main
struct MicroActionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var proStore = ProStoreService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(proStore)
                .preferredColorScheme(.light)
        }
    }
}
