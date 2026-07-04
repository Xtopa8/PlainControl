import Foundation

// MARK: - IP Address & URL Validation

extension String {
    /// Check if the string is a valid IPv4 address.
    var isValidIPv4: Bool {
        let parts = split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part),
                  num >= 0 && num <= 255,
                  part == String(num)  // No leading zeros
            else { return false }
            return true
        }
    }

    /// Check if the string is a private/RFC1918 IP address.
    var isPrivateIP: Bool {
        guard isValidIPv4 else { return false }
        let parts = split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }

        // 10.0.0.0/8
        if parts[0] == 10 { return true }
        // 172.16.0.0/12
        if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
        // 192.168.0.0/16
        if parts[0] == 192 && parts[1] == 168 { return true }
        // 127.0.0.0/8 (loopback)
        if parts[0] == 127 { return true }

        return false
    }

    /// Check if the string is a local hostname (.local domain).
    var isLocalDomain: Bool {
        hasSuffix(".local") || hasSuffix(".lan") || hasSuffix(".home")
    }

    /// Check if the host is safe for self-signed certificate trust.
    var isSafeForSelfSignedTLS: Bool {
        isPrivateIP || isLocalDomain || self == "localhost"
    }

    /// Validate as a host:port string. Returns (host, port) tuple if valid.
    var parsedHostPort: (host: String, port: Int)? {
        let parts = split(separator: ":")
        if parts.count == 2, let port = Int(parts[1]), port > 0, port <= 65535 {
            return (String(parts[0]), port)
        }
        // Try without port — default to 8080
        if !contains(":"), isValidIPv4 || isLocalDomain {
            return (self, 8080)
        }
        return nil
    }

    /// Validate as a PlainApp device URL.
    var isValidDeviceURL: Bool {
        guard let url = URL(string: self) else { return false }
        guard let host = url.host else { return false }
        guard let port = url.port, port > 0, port <= 65535 else { return false }
        return host.isValidIPv4 || host.isLocalDomain || host == "localhost"
    }
}
