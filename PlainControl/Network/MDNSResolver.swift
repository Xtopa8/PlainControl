import Foundation
import Network
import dnssd

/// mDNS / Bonjour resolver for PlainApp devices.
///
/// Two modes of operation:
/// 1. Browse for `_plain._tcp` services via Bonjour (NWBrowser) — future-proof
/// 2. Resolve `plainapp.local` A records — works with current Android implementation
///
/// The Android PlainApp uses an mDNS responder (MdnsHostResponder) that
/// answers A-record queries for `plainapp.local` but does NOT publish
/// full mDNS-SD PTR/SRV/TXT records yet.
final class MDNSResolver {
    // MARK: - Types

    /// Result from mDNS resolution.
    struct ResolvedDevice: Identifiable {
        let hostname: String
        let ipAddresses: [String]
        let port: Int?
        let serviceName: String?

        var id: String { hostname }
    }

    // MARK: - Properties

    private var browser: NWBrowser?
    private var sdRef: DNSServiceRef?
    private var isRunning = false

    var onDeviceResolved: ((ResolvedDevice) -> Void)?
    var onServiceFound: ((String) -> Void)?

    // MARK: - Bonjour Browser (for _plain._tcp)

    /// Start browsing for `_plain._tcp` Bonjour services.
    /// This is forward-compatible for when Android adds full mDNS-SD support.
    func startBrowsing() {
        let params = NWParameters()
        params.includePeerToPeer = true

        let descriptor = NWBrowser.Descriptor.bonjour(
            type: "_plain._tcp",
            domain: "local."
        )

        browser = NWBrowser(for: descriptor, using: params)
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            for result in results {
                switch result.endpoint {
                case .service(let name, let type, let domain, let interface):
                    let serviceInfo = "\(name).\(type).\(domain)"
                    self?.onServiceFound?(serviceInfo)

                    // Resolve the service to get IP and port
                    self?.resolveService(
                        name: name,
                        type: type,
                        domain: domain,
                        interface: interface
                    )
                default:
                    break
                }
            }
        }

        browser?.stateUpdateHandler = { state in
            switch state {
            case .failed(let error):
                print("NWBrowser failed: \(error)")
            default:
                break
            }
        }

        browser?.start(queue: .main)
        isRunning = true
    }

    /// Stop browsing.
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        isRunning = false
    }

    /// Resolve a Bonjour service to its IP addresses and port.
    private func resolveService(
        name: String,
        type: String,
        domain: String,
        interface: NWInterface?
    ) {
        let endpoint = NWEndpoint.service(
            name: name,
            type: type,
            domain: domain,
            interface: interface
        )

        let params = NWParameters.tcp
        let connection = NWConnection(to: endpoint, using: params)

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint {
                    switch innerEndpoint {
                    case .hostPort(let host, let port):
                        let ip: String
                        switch host {
                        case .ipv4(let addr): ip = addr.debugDescription
                        case .ipv6(let addr): ip = addr.debugDescription
                        case .name(let hostname, _): ip = hostname
                        @unknown default: ip = host.debugDescription
                        }
                        let device = ResolvedDevice(
                            hostname: "\(name).\(domain)",
                            ipAddresses: [ip],
                            port: Int(port.rawValue),
                            serviceName: name
                        )
                        DispatchQueue.main.async {
                            self?.onDeviceResolved?(device)
                        }
                    default:
                        break
                    }
                }
                connection.cancel()
            case .failed:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .utility))
    }

    // MARK: - A-Record Resolution (plainapp.local)

    /// Resolve `plainapp.local` to IP addresses using DNS-SD.
    /// This is the primary method for current Android PlainApp releases.
    func resolvePlainLocal(timeout: TimeInterval = 3.0) async -> [String] {
        await withCheckedContinuation { continuation in
            var ips: [String] = []
            let hostname = "plainapp.local"
            var sdRef: DNSServiceRef?

            // Callback for DNSServiceQueryRecord
            let callback: DNSServiceQueryRecordReply = { _, flags, _, err, _, _, rrtype, _, rdlen, rdata, _, context in
                guard err == kDNSServiceErr_NoError,
                      rrtype == UInt16(kDNSServiceType_A),
                      rdlen >= 4,
                      let rdata = rdata else {
                    return
                }

                var addr = sockaddr_in()
                rdata.withMemoryRebound(to: UInt32.self, capacity: 1) { ptr in
                    addr.sin_addr.s_addr = ptr.pointee
                }
                var addrStr = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                var addrCopy = addr.sin_addr
                inet_ntop(AF_INET, &addrCopy, &addrStr, socklen_t(INET_ADDRSTRLEN))
                let ip = String(cString: addrStr)
                if !ips.contains(ip) {
                    ips.append(ip)
                }
            }

            let result = withUnsafeMutablePointer(to: &sdRef) { ptr in
                DNSServiceQueryRecord(
                    ptr,
                    0,                    // flags
                    0,                    // interfaceIndex (all)
                    hostname,
                    UInt16(kDNSServiceType_A),
                    UInt16(kDNSServiceClass_IN),
                    callback,
                    nil                   // context
                )
            }

            if result == kDNSServiceErr_NoError, let ref = sdRef {
                // Set up a timer for timeout
                let deadline = DispatchTime.now() + timeout
                let fd = DNSServiceRefSockFD(ref)

                // Poll with timeout
                DispatchQueue.global(qos: .utility).async {
                    // Process events for timeout duration
                    var remaining = timeout
                    while remaining > 0 && ips.isEmpty {
                        DNSServiceProcessResult(ref)
                        Thread.sleep(forTimeInterval: 0.5)
                        remaining -= 0.5
                    }
                    DNSServiceRefDeallocate(ref)
                    continuation.resume(returning: ips)
                }
            } else {
                continuation.resume(returning: [])
            }
        }
    }
}
