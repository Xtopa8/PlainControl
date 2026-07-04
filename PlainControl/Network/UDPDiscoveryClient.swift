import Foundation
import Network

/// UDP multicast client for PlainApp device discovery.
///
/// Implements the PlainApp discovery protocol:
/// - Sends `DISCOVER:{json}` to multicast group 224.0.0.100:52352
/// - Receives `DISCOVER_REPLY:{json}` from PlainApp devices on the LAN
///
/// Reference: `NearbyNetwork.kt` in the PlainApp Android source.
final class UDPDiscoveryClient {
    // MARK: - Constants

    /// Multicast group address matching PlainApp's NearbyNetwork.
    private static let multicastHost = "224.0.0.100"

    /// Discovery port matching PlainApp's NearbyNetwork.
    private static let discoveryPort: UInt16 = 52352

    /// TTL for multicast packets (local subnet only).
    private static let multicastTTL: UInt8 = 1

    // MARK: - State

    private var sendConnection: NWConnection?
    private var receiveListener: NWListener?
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.plaincontrol.udp", qos: .utility)

    /// Callback invoked when a DiscoverReply is received.
    var onReplyReceived: ((DiscoverReply) -> Void)?

    /// Callback invoked for raw message logging/debugging.
    var onRawMessage: ((String) -> Void)?

    // MARK: - Public API

    /// Start the discovery client: begin sending DISCOVER and listening for replies.
    func start() throws {
        guard !isRunning else { return }
        isRunning = true

        try startReceiving()
        try startSending()
    }

    /// Stop the discovery client.
    func stop() {
        isRunning = false
        sendConnection?.cancel()
        sendConnection = nil
        receiveListener?.cancel()
        receiveListener = nil
    }

    /// Send a single DISCOVER broadcast request.
    func sendDiscoveryRequest(fromId: String = "", toId: String = "") {
        let request = DiscoverRequest(fromId: fromId, toId: toId)
        guard let jsonData = try? JSONEncoder().encode(request),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let message = "DISCOVER:\(jsonStr)"
        sendMulticast(message: message)
    }

    // MARK: - Multicast Send

    private func startSending() throws {
        let host = NWEndpoint.Host(Self.multicastHost)
        let port = NWEndpoint.Port(rawValue: Self.discoveryPort)!

        // Create a UDP connection for sending
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .wifi  // Prefer WiFi for LAN discovery

        sendConnection = NWConnection(host: host, port: port, using: params)
        sendConnection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.onRawMessage?("UDP send ready")
                // Send initial discovery request
                self?.sendDiscoveryRequest()
            case .failed(let error):
                self?.onRawMessage?("UDP send failed: \(error)")
            default:
                break
            }
        }
        sendConnection?.start(queue: queue)
    }

    private func sendMulticast(message: String) {
        guard let data = message.data(using: .utf8) else { return }
        sendConnection?.send(content: data, completion: .contentProcessed({ [weak self] error in
            if let error = error {
                self?.onRawMessage?("UDP send error: \(error)")
            }
        }))
    }

    // MARK: - Unicast Receive

    private func startReceiving() throws {
        let port = NWEndpoint.Port(rawValue: Self.discoveryPort)!

        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .wifi

        receiveListener = try NWListener(using: params, on: port)
        receiveListener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.onRawMessage?("UDP listener ready on port \(Self.discoveryPort)")
            case .failed(let error):
                self?.onRawMessage?("UDP listener failed: \(error)")
            default:
                break
            }
        }

        receiveListener?.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .main)
            self?.receive(on: connection)
        }

        receiveListener?.start(queue: queue)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] data, _, _, error in
            if let error = error {
                self?.onRawMessage?("Receive error: \(error)")
                return
            }

            if let data = data, let reply = DiscoverReply.fromDatagram(data) {
                DispatchQueue.main.async {
                    self?.onReplyReceived?(reply)
                }
            } else if let data = data, let text = String(data: data, encoding: .utf8) {
                self?.onRawMessage?("Raw datagram: \(text.prefix(200))")
            }

            // Continue receiving on this connection
            if self?.isRunning == true {
                self?.receive(on: connection)
            }
        }
    }
}
