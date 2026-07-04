import SwiftUI
struct RootView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack {
            Text("PlainControl").font(.largeTitle)
            Text("\(appState.devices.count) devices saved")
        }
    }
}
