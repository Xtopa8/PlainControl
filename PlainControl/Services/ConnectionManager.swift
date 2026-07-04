import Foundation
import Network
@MainActor
final class ConnectionManager {
    private let appState: AppState
    init(appState: AppState) { self.appState = appState }
    func connect(to device: PlainDevice) async throws {
        appState.connectionState = .connecting
        guard let ip = await DeviceProber.findReachableIP(ips: device.ips, port: device.httpsPort > 0 ? device.httpsPort : device.httpPort, timeout: 2.0) else {
            appState.connectionState = .error(.unreachable); throw ConnectionError.unreachable
        }
        var d = device; d.ips = [ip]; d.isOnline = true; appState.activeDevice = d; appState.connectionState = .connected
    }
    func disconnect() { appState.activeDevice = nil; appState.connectionState = .disconnected }
}
