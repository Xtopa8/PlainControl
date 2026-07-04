import Foundation

/// UDP discovery request sent by the controller to find PlainApp devices.
///
/// Mirrors `DDiscoverRequest` from `shared/src/commonMain/.../data/DNearbyDiscover.kt`
struct DiscoverRequest: Codable {
    /// Sender's own device ID (optional, empty string if not available).
    let fromId: String

    /// Target device ID for directed scan (optional, empty string for broadcast).
    let toId: String

    enum CodingKeys: String, CodingKey {
        case fromId
        case toId
    }

    /// Serialize to JSON for UDP transmission.
    func toJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

/// Response from a PlainApp device to a discovery request.
///
/// Mirrors `DDiscoverReply` from `shared/src/commonMain/.../data/DNearbyDiscover.kt`
struct DiscoverReply: Codable, Identifiable {
    /// Unique device ID.
    let id: String

    /// Human-readable device name.
    let name: String

    /// HTTPS API port.
    let port: Int

    /// Device type string: "phone", "tablet", "laptop", "desktop", "tv", "other".
    let deviceType: String

    /// PlainApp version string.
    let version: String

    /// Platform: "android", "ios", "macos", "windows", "linux".
    let platform: String

    /// All IP addresses of the device (may be empty in older versions).
    let ips: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case port
        case deviceType
        case version
        case platform
        case ips
    }

    /// Parse a DiscoverReply from UDP datagram data.
    /// Expects the format: "DISCOVER_REPLY:{json}"
    static func fromDatagram(_ data: Data) -> DiscoverReply? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }

        // Try "DISCOVER_REPLY:" prefix (the standard prefix from NearbyMessageType)
        let prefix = "DISCOVER_REPLY:"
        let jsonString: String
        if let range = text.range(of: prefix) {
            jsonString = String(text[range.upperBound...])
        } else {
            // Fallback: treat the whole message as JSON
            jsonString = text
        }

        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        do {
            return try JSONDecoder().decode(DiscoverReply.self, from: jsonData)
        } catch {
            return nil
        }
    }
}

/// Parsed UDP discovery message type.
enum DiscoverMessageType {
    case discover(DiscoverRequest)
    case discoverReply(DiscoverReply)
    case unknown(String)

    /// Parse a raw datagram into a typed message.
    static func parse(_ data: Data) -> DiscoverMessageType {
        guard let text = String(data: data, encoding: .utf8) else {
            return .unknown("Invalid UTF-8 data")
        }

        if text.hasPrefix("DISCOVER:") {
            let jsonString = String(text.dropFirst("DISCOVER:".count))
            if let jsonData = jsonString.data(using: .utf8),
               let request = try? JSONDecoder().decode(DiscoverRequest.self, from: jsonData) {
                return .discover(request)
            }
        } else if text.hasPrefix("DISCOVER_REPLY:") {
            let jsonString = String(text.dropFirst("DISCOVER_REPLY:".count))
            if let jsonData = jsonString.data(using: .utf8),
               let reply = try? JSONDecoder().decode(DiscoverReply.self, from: jsonData) {
                return .discoverReply(reply)
            }
        }

        return .unknown(text)
    }
}
