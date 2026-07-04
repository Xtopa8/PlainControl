import SwiftUI
import SwiftData

/// PlainControl — iOS controller app for PlainApp devices.
///
/// Discovers PlainApp devices on the local network, manages connections,
/// and provides a WKWebView-based control interface for each device.
/// Supports switching between multiple controlled devices seamlessly.
@main
struct PlainControlApp: App {
    @StateObject private var appState = AppState()

    var modelContainer: ModelContainer = {
        let schema = Schema([
            PlainDevice.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(modelContainer)
    }
}
