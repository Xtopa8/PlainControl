import Foundation
import Network

/// Manages the lifecycle of device connections.
@MainActor
final class ConnectionManager {
    private let appState: AppState
    private var healthCheckTimer: Timer?
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.plaincontrol.network")
    private static let healthCheckInterval: TimeInterval = 10.0

    init(appState: AppState) {
        self.appState = appState
        setupNetworkMonitoring()
    }

    deinit {
        healthCheckTimer?.invalidate()
        pathMonitor?.cancel()
    }

    /// Connect to a device and set it as active.
    func connect(to device: PlainDevice) async throws {
        appState.connectionState = .connecting

        guard let reachableIP = await DeviceProber.findReachableIP(
            ips: device.ips, port: device.httpsPort, timeout: 2.0
        ) else {
            if device.httpsPort > 0 {
                let httpPort = device.httpsPort - 400
                let _ = await DeviceProber.findReachableIP(
                    ips: device.ips, port: httpPort, timeout: 2.0
                )
            }
            appState.connectionState = .error(.unreachable)
            throw ConnectionError.unreachable
        }

        let initOK = await DeviceProber.probeInit(host: reachableIP, port: device.httpsPort, timeout: 3.0)
        if !initOK {
            let httpPort = max(device.httpsPort - 400, 80)
            let httpInitOK = await DeviceProber.probeInit(host: reachableIP, port: httpPort, useTLS: false, timeout: 3.0)
            if !httpInitOK {
                appState.connectionState = .error(.authenticationFailed(reason: "Device not responding"))
                throw ConnectionError.authenticationFailed(reason: "Device not responding")
            }
        }

        device.isOnline = true
        device.lastSeen = .now
        device.lastConnectedAt = .now
        appState.activeDevice = device
        appState.connectionState = .connected
        appState.setDeviceOnline(device.id, online: true)
        startHealthChecks()
    }

    func disconnect() {
        healthCheckTimer?.invalidate(); healthCheckTimer = nil
        if let device = appState.activeDevice { device.isActive = false }
        appState.activeDevice = nil
        appState.connectionState = .disconnected
    }

    func checkHealth() async {
        guard let device = appState.activeDevice,
              let healthURL = device.healthURL else { return }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5.0
        let delegate = ConnHealthSessionDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                device.isOnline = true; device.lastSeen = .now
                appState.setDeviceOnline(device.id, online: true)
                if case .disconnected = appState.connectionState { appState.connectionState = .connected }
            } else { throw URLError(.badServerResponse) }
        } catch {
            device.isOnline = false
            appState.setDeviceOnline(device.id, online: false)
            appState.connectionState = .error(.unreachable)
        }
    }

    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied, let device = self?.appState.activeDevice,
                   case .error = self?.appState.connectionState {
                    try? await self?.connect(to: device)
                } else if path.status != .satisfied {
                    self?.appState.connectionState = .error(.unreachable)
                }
            }
        }
        pathMonitor?.start(queue: monitorQueue)
    }

    private func startHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Self.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.checkHealth() }
        }
    }
}

private final class ConnHealthSessionDelegate: NSObject, URLSessionDelegate {}
