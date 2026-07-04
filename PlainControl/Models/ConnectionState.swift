import Foundation

/// Connection state for a device.
enum ConnectionState: Equatable {
    /// No active connection, nothing in progress.
    case disconnected

    /// Attempting to connect (probing IPs, establishing session).
    case connecting

    /// Successfully connected and authenticated.
    case connected

    /// Connection failed with an error.
    case error(ConnectionError)

    // MARK: - Equatable

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.error(let lErr), .error(let rErr)): return lErr == rErr
        default: return false
        }
    }
}

/// Specific connection error types.
enum ConnectionError: Error, LocalizedError, Equatable {
    /// No IP address is reachable for this device.
    case unreachable

    /// SSL/TLS verification failed (for non-private IPs).
    case sslVerificationFailed(host: String)

    /// Authentication failed (wrong password, token expired).
    case authenticationFailed(reason: String)

    /// Server returned an unexpected response.
    case serverError(statusCode: Int)

    /// Network timeout.
    case timeout

    /// Unknown error with description.
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unreachable:
            return "Device is unreachable. Check that it's on the same network."
        case .sslVerificationFailed(let host):
            return "SSL verification failed for \(host)."
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .serverError(let code):
            return "Server error (HTTP \(code))."
        case .timeout:
            return "Connection timed out."
        case .unknown(let msg):
            return msg
        }
    }
}

/// The status badge state for a device in the UI.
enum DeviceStatus: Equatable {
    case online
    case offline
    case connecting
    case error

    var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "gray"
        case .connecting: return "yellow"
        case .error: return "red"
        }
    }

    var icon: String {
        switch self {
        case .online: return "circle.fill"
        case .offline: return "circle"
        case .connecting: return "circle.dotted"
        case .error: return "exclamationmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        case .connecting: return "Connecting..."
        case .error: return "Error"
        }
    }
}
