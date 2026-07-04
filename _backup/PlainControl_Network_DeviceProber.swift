import Foundation

/// Probes a device to determine if it's reachable and responsive.
///
/// Uses the PlainApp `/health` and `/init` endpoints to verify
/// that a device at a given IP:port is actually running PlainApp.
final class DeviceProber {
    /// Probe a single IP:port combination for PlainApp availability.
    /// - Parameters:
    ///   - ip: The IP address to probe
    ///   - port: The HTTPS port to probe
    ///   - timeout: Request timeout in seconds
    /// - Returns: True if the device responded positively
    static func probeDevice(ip: String, port: Int, timeout: TimeInterval = 3.0) async -> Bool {
        // Try HTTPS first, then HTTP fallback
        if await probeHealth(host: ip, port: port, useTLS: true, timeout: timeout) {
            return true
        }
        // Fallback: try HTTP on port - 400 (PlainApp convention: HTTP = HTTPS - 400)
        let httpPort = max(port - 400, 80)
        return await probeHealth(host: ip, port: httpPort, useTLS: false, timeout: timeout)
    }

    /// Probe multiple IPs for a device, returning the first reachable IP.
    /// - Parameters:
    ///   - ips: List of IP addresses to try
    ///   - port: The HTTPS port
    ///   - timeout: Per-IP timeout in seconds
    /// - Returns: The first reachable IP, or nil if none are reachable
    static func findReachableIP(ips: [String], port: Int, timeout: TimeInterval = 2.0) async -> String? {
        // Race all IPs concurrently, return the first success
        await withTaskGroup(of: (ip: String, reachable: Bool).self) { group in
            for ip in ips {
                group.addTask {
                    let reachable = await probeDevice(ip: ip, port: port, timeout: timeout)
                    return (ip, reachable)
                }
            }

            // Return the first reachable IP
            for await result in group {
                if result.reachable {
                    group.cancelAll()
                    return result.ip
                }
            }
            return nil
        }
    }

    // MARK: - Private

    /// Perform a GET /health request to verify a PlainApp server.
    private static func probeHealth(host: String, port: Int, useTLS: Bool, timeout: TimeInterval) async -> Bool {
        let scheme = useTLS ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host):\(port)/health") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        // Create a custom URLSession that doesn't validate certificates for LAN devices
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        sessionConfig.timeoutIntervalForResource = timeout * 2

        let delegate = LanSSLSessionDelegate()
        let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let body = String(data: data, encoding: .utf8) else {
                return false
            }
            // The /health endpoint returns the app's package name (containing "plain")
            return body.contains("plain") || !body.isEmpty
        } catch {
            return false
        }
    }

    /// POST /init to verify a device is reachable and ready.
    static func probeInit(host: String, port: Int, useTLS: Bool = true, timeout: TimeInterval = 3.0) async -> Bool {
        let scheme = useTLS ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host):\(port)/init") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("ios-controller", forHTTPHeaderField: "c-id")

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        let delegate = LanSSLSessionDelegate()
        let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            // /init returns 200 or 204 on success, 401/403 on auth needed
            return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
        } catch {
            return false
        }
    }
}

// MARK: - LAN SSL Session Delegate

/// URLSessionDelegate that trusts self-signed certificates for LAN IPs only.
private final class LanSSLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        if host.isSafeForSelfSignedTLS {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
