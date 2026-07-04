import SwiftUI
@main
struct PlainControlApp: App {
    @StateObject private var state = AppState()
    var body: some Scene { WindowGroup { RootView().environmentObject(state) } }
}
