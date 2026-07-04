import SwiftUI
@main
struct PlainControlApp: App {
    @State private var count = 0
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 30) {
                Text("PlainControl").font(.largeTitle).fontWeight(.bold)
                Text("TrollStore Test").font(.title2).foregroundStyle(.secondary)
                Button("Tap: \(count)") { count += 1 }
                    .buttonStyle(.borderedProminent).controlSize(.large)
            }
        }
    }
}
