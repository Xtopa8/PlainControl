import Foundation
import Combine

/// Orchestrates device discovery across multiple mechanisms:
/// 1. UDP multicast (primary) — broadcasts DISCOVER, receives DISCOVER_REPLY
/// 2. mDNS A-record resolution (secondary) — resolves plainapp.local
/// 3. Bonjour browsing (future-proof) — browses _plain._tcp
/// 4. Manual entry — user-provided IP:port
@MainActor
final class DiscoveryService: ObservableObject {
    // MARK: - Published State

    /// Currently discovered devices during an active scan.
    @Published var discoveredDevices: [DiscoverReply] = []

    /// Whether a scan is currently running.
    @Published var isScanning: Bool = false

    /// Error message if discovery fails.
    @Published var errorMessage: String?

    /// Debug log of raw discovery events.
    @Published var debugLog: [String] = []

    // MARK: - Private

    private let udpClient = UDPDiscoveryClient()
    private let mDNSResolver = MDNSResolver()
    private var scanTimer: Timer?
    private var scanStartTime: Date?

    /// How often to re-send DISCOVER during active scan (matches Android's 5s interval).
    private static let scanInterval: TimeInterval = 5.0

    /// Maximum scan duration before auto-stop.
    private static let maxScanDuration: TimeInterval = 15.0

    /// Callback when user wants to add a discovered device.
    var onDeviceSelected: ((DiscoverReply) -> Void)?

    // MARK: - Public API

    /// Start a discovery scan.
    /// Sends periodic DISCOVER broadcasts and listens for replies.
    func startScan() {
        guard !isScanning else { return }

        isScanning = true
        discoveredDevices.removeAll()
        errorMessage = nil
        scanStartTime = Date()

        // Configure UDP client callbacks
        udpClient.onReplyReceived = { [weak self] reply in
            Task { @MainActor in
                self?.addDiscoveredDevice(reply)
            }
        }
        udpClient.onRawMessage = { [weak self] msg in
            Task { @MainActor in
                self?.debugLog.append("[UDP] \(msg)")
            }
        }

        // Start UDP discovery
        do {
            try udpClient.start()
            logDebug("UDP discovery started on 224.0.0.100:52352")
        } catch {
            errorMessage = "Failed to start UDP discovery: \(error.localizedDescription)"
            logDebug("UDP start error: \(error)")
            isScanning = false
            return
        }

        // Start mDNS resolution in parallel
        mDNSResolver.startBrowsing()
        mDNSResolver.onDeviceResolved = { [weak self] device in
            Task { @MainActor in
                // Convert ResolvedDevice to DiscoverReply
                if let firstIP = device.ipAddresses.first {
                    let reply = DiscoverReply(
                        id: "mdns-\(device.hostname)",
                        name: device.serviceName ?? device.hostname,
                        port: device.port ?? 8080,
                        deviceType: "phone",
                        version: "",
                        platform: "android",
                        ips: device.ipAddresses
                    )
                    self?.addDiscoveredDevice(reply)
                }
            }
        }

        // Start periodic re-scan timer
        scanTimer = Timer.scheduledTimer(withTimeInterval: Self.scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.udpClient.sendDiscoveryRequest()
                self?.logDebug("Re-broadcasting DISCOVER...")
            }
        }

        // Auto-stop after max duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.maxScanDuration * 1_000_000_000))
            if isScanning {
                stopScan()
                logDebug("Scan auto-stopped after \(Int(Self.maxScanDuration))s")
            }
        }
    }

    /// Stop the discovery scan.
    func stopScan() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        udpClient.stop()
        mDNSResolver.stopBrowsing()
        logDebug("Discovery scan stopped. Found \(discoveredDevices.count) devices.")
    }

    /// Add a device from manual IP:port entry.
    /// Validates reachability before returning the reply.
    func addManualDevice(ip: String, port: Int) async throws -> DiscoverReply {
        logDebug("Probing \(ip):\(port)...")

        let reachable = await DeviceProber.probeDevice(ip: ip, port: port)
        guard reachable else {
            throw ConnectionError.unreachable
        }

        let reply = DiscoverReply(
            id: "manual-\(ip.replacingOccurrences(of: ".", with: "-"))",
            name: "Device @ \(ip)",
            port: port,
            deviceType: "phone",
            version: "",
            platform: "android",
            ips: [ip]
        )
        addDiscoveredDevice(reply)
        return reply
    }

    /// Resolve PlainApp devices via mDNS A-record (plainapp.local).
    func resolveViaMDNS() async {
        logDebug("Resolving plainapp.local...")
        let ips = await mDNSResolver.resolvePlainLocal(timeout: 3.0)
        for ip in ips {
            if await DeviceProber.probeDevice(ip: ip, port: 8443) {
                let reply = DiscoverReply(
                    id: "mdns-\(ip.replacingOccurrences(of: ".", with: "-"))",
                    name: "PlainApp (\(ip))",
                    port: 8443,
                    deviceType: "phone",
                    version: "",
                    platform: "android",
                    ips: [ip]
                )
                addDiscoveredDevice(reply)
            }
        }
        logDebug("mDNS resolution found \(ips.count) IPs")
    }

    // MARK: - Private

    private func addDiscoveredDevice(_ reply: DiscoverReply) {
        // Avoid duplicates by device ID
        if !discoveredDevices.contains(where: { $0.id == reply.id }) {
            discoveredDevices.append(reply)
            logDebug("Found: \(reply.name) @ \(reply.ips.first ?? "?") port \(reply.port)")
        }
    }

    private func logDebug(_ message: String) {
        debugLog.append("[\(Date().formatted(.iso8601))] \(message)")
        // Keep log at reasonable size
        if debugLog.count > 100 {
            debugLog.removeFirst(debugLog.count - 100)
        }
    }
}
