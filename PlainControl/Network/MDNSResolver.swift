import Foundation
import Network

/// mDNS / Bonjour resolver for PlainApp devices.
///
/// Uses NWBrowser to browse for _plain._tcp services (Bonjour).
/// Also resolves plainapp.local via CFHost.
final class MDNSResolver {
    struct ResolvedDevice: Identifiable {
        let hostname: String
        let ipAddresses: [String]
        let port: Int?
        let serviceName: String?
        var id: String { hostname }
    }

    private var browser: NWBrowser?
    var onDeviceResolved: ((ResolvedDevice) -> Void)?
    var onServiceFound: ((String) -> Void)?

    func startBrowsing() {
        let params = NWParameters()
        params.includePeerToPeer = true

        let descriptor = NWBrowser.Descriptor.bonjour(type: "_plain._tcp", domain: "local.")
        browser = NWBrowser(for: descriptor, using: params)
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            for result in results {
                if case .service(let name, let type, let domain, _) = result.endpoint {
                    let info = "\(name).\(type).\(domain)"
                    self?.onServiceFound?(info)
                    self?.resolveEndpoint(result.endpoint, name: name, domain: domain)
                }
            }
        }
        browser?.stateUpdateHandler = { state in
            if case .failed(let error) = state { print("NWBrowser failed: \(error)") }
        }
        browser?.start(queue: .main)
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil
    }

    private func resolveEndpoint(_ endpoint: NWEndpoint, name: String, domain: String) {
        let params = NWParameters.tcp
        let conn = NWConnection(to: endpoint, using: params)
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let inner = conn.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = inner {
                    let ip: String
                    switch host {
                    case .ipv4(let addr): ip = addr.debugDescription
                    case .name(let hostname, _): ip = hostname
                    default: ip = host.debugDescription
                    }
                    let dev = ResolvedDevice(hostname: "\(name).\(domain)", ipAddresses: [ip],
                                              port: Int(port.rawValue), serviceName: name)
                    DispatchQueue.main.async { self?.onDeviceResolved?(dev) }
                }
                conn.cancel()
            case .failed:
                conn.cancel()
            default: break
            }
        }
        conn.start(queue: .global(qos: .utility))
    }

    func resolvePlainLocal(timeout: TimeInterval = 3.0) async -> [String] {
        // Use CFHost for simple hostname resolution
        let host = CFHostCreateWithName(nil, "plainapp.local" as CFString).takeRetainedValue()
        var resolved = DarwinBoolean(false)
        CFHostStartInfoResolution(host, CFHostInfoType.addresses, nil)
        // Wait a bit for resolution
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))

        var ips: [String] = []
        if let addressing = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as? [Data] {
            for data in addressing {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                data.withUnsafeBytes { raw in
                    let addr = raw.bindMemory(to: sockaddr.self)
                    if let base = addr.baseAddress {
                        getnameinfo(base, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                        let ip = String(cString: hostname)
                        if !ip.isEmpty && !ips.contains(ip) { ips.append(ip) }
                    }
                }
            }
        }
        return ips
    }
}
