import Foundation
enum ConnectionState: Equatable { case disconnected, connecting, connected, error(ConnectionError) }
enum ConnectionError: Error, Equatable, LocalizedError {
    case unreachable, authFailed(String), timeout, unknown(String)
    var errorDescription: String? {
        switch self { case .unreachable: "Device unreachable"
        case .authFailed(let r): "Auth failed: \(r)"
        case .timeout: "Timeout"; case .unknown(let m): m }
    }
}
enum DeviceStatus: Equatable { case online, offline, connecting, error }
