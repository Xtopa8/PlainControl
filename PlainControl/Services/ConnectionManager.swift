import Foundation
import Network
import SwiftUI

/// Manages the lifecycle of device connections.
///
/// Responsibilities:
/// - Active device selection and connection
/// - Periodic health checks to determine online/offline status
/// - Automatic reconnection on network changes
/// - IP reachability probing and failover
@MainActor
final class ConnectionManager: ObservableObject {
    // MARK: - Published

    /// The currently active (connected) device.
    @Published var activeDevice: PlainDevice?

    /// Current connection state.
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Private

    private let appState: AppState
    private var healthCheckTimer: Timer?
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.plaincontrol.network")

    /// Health check interval in seconds.
    private static let healthCheckInterval: TimeInterval = 10.0

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
        setupNetworkMonitoring()
    }

    deinit {
        healthCheckTimer?.invalidate()
        pathMonitor?.cancel()
    }

    // MARK: - Public API

    /// Connect to a device and set it as active.
    func connect(to device: PlainDevice) async throws {
        connectionState = .connecting

        // Find a reachable IP
        guard let reachableIP = await DeviceProber.findReachableIP(
            ips: device.getIPs(),
            port: device.httpsPort,
            timeout: 2.0
        ) else {
            // Try HTTP port as fallback
            if device.httpsPort > 0 {
                let httpPort = device.httpsPort - 400
                let reachableHTTP = await DeviceProber.findReachableIP(
                    ips: device.getIPs(),
                    port: httpPort,
                    timeout: 2.0
                )
                if reachableHTTP == nil {
                    connectionState = .error(.unreachable)
                    throw ConnectionError.unreachable
                }
            } else {
                connectionState = .error(.unreachable)
                throw ConnectionError.unreachable
            }
        }

        // Verify /init endpoint responds
        let initOK = await DeviceProber.probeInit(
            host: reachableIP,
            port: device.httpsPort,
            timeout: 3.0
        )

        if !initOK {
            // Try HTTP fallback
            let httpPort = max(device.httpsPort - 400, 80)
            let httpInitOK = await DeviceProber.probeInit(
                host: reachableIP ?? "",
                port: httpPort,
                useTLS: false,
                timeout: 3.0
            )
            if !httpInitOK {
                connectionState = .error(.authenticationFailed(reason: "Device not responding to /init"))
                throw ConnectionError.authenticationFailed(reason: "Device not responding")
            }
        }

        // Success — update state
        activeDevice = device
        connectionState = .connected
        device.isOnline = true
        device.lastSeen = .now
        device.lastConnectedAt = .now

        appState.activeDevice = device
        appState.connectionState = .connected
        appState.setDeviceOnline(device.id, online: true)

        // Start periodic health checks
        startHealthChecks()
    }

    /// Disconnect from the active device.
    func disconnect() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil

        if let device = activeDevice {
            device.isActive = false
        }
        activeDevice = nil
        connectionState = .disconnected

        appState.activeDevice = nil
        appState.connectionState = .disconnected
    }

    /// Perform a health check on the active device.
    func checkHealth() async {
        guard let device = activeDevice,
              let healthURL = device.healthURL else {
            return
        }

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        let delegate = ConnectionHealthDelegate()
        let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                device.isOnline = true
                device.lastSeen = .now
                appState.setDeviceOnline(device.id, online: true)
                if connectionState == .disconnected {
                    connectionState = .connected
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            device.isOnline = false
            appState.setDeviceOnline(device.id, online: false)
            connectionState = .error(.unreachable)
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied {
                    // Network recovered — try to reconnect if we have an active device
                    if let device = self?.activeDevice,
                       self?.connectionState == .error(.unreachable) {
                        try? await self?.connect(to: device)
                    }
                } else {
                    // Network lost — mark all as potentially offline
                    self?.connectionState = .error(.unreachable)
                }
            }
        }
        pathMonitor?.start(queue: monitorQueue)
    }

    // MARK: - Health Checks

    private func startHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(
            withTimeInterval: Self.healthCheckInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkHealth()
            }
        }
    }
}

// MARK: - Basic URLSession Delegate for Health Checks

private final class ConnectionHealthDelegate: NSObject, Foundation.URLSessionDelegate {}
