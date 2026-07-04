import Foundation
import SwiftData

/// SwiftData model representing a PlainApp device (被控端).
///
/// Maps to the data from `DDiscoverReply` in the shared KMP module.
/// Stores all information needed to connect to and identify a device.
@Model
final class PlainDevice {
    /// Unique device ID (from PlainApp's clientId).
    @Attribute(.unique) var id: String

    /// User-editable display name for this device.
    var name: String

    /// All known IP addresses for this device (encoded as JSON string for SQLite storage).
    private var ipsJSON: String

    /// HTTPS port for encrypted communication.
    var httpsPort: Int

    /// HTTP port (fallback).
    var httpPort: Int

    /// Device type string matching PlainApp's DeviceType enum values.
    var deviceType: String

    /// Platform: "android", "ios", etc.
    var platform: String

    /// PlainApp version string.
    var version: String

    /// Last time this device was reachable.
    var lastSeen: Date

    /// Whether this device has completed pairing with us.
    var isPaired: Bool

    /// ECDH shared key stored in Keychain (we only store a reference ID here).
    /// The actual key material is stored securely in the Keychain.
    var keychainKeyRef: String?

    /// Our Ed25519 public key for this device (Base64).
    var pairingPublicKey: String?

    /// Whether this device was recently online (updated by health checks).
    var isOnline: Bool

    /// Last time we successfully connected to this device.
    var lastConnectedAt: Date?

    /// Whether this is the currently active (selected) device.
    var isActive: Bool

    /// User-defined sort order for the device list.
    var sortOrder: Int

    /// When this device entry was created.
    var createdAt: Date

    // MARK: - Computed Properties

    /// Decoded IP addresses from the stored JSON.
    var ips: [String] {
        get {
            guard let data = ipsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                ipsJSON = json
            }
        }
    }

    /// The primary IP to use for connection (first reachable IP).
    var primaryIP: String? {
        ips.first
    }

    /// Build the connection URL for WKWebView.
    var connectionURL: URL? {
        if httpsPort > 0, let ip = primaryIP {
            return URL(string: "https://\(ip):\(httpsPort)/")
        }
        if httpPort > 0, let ip = primaryIP {
            return URL(string: "http://\(ip):\(httpPort)/")
        }
        return nil
    }

    /// Health check URL.
    var healthURL: URL? {
        if httpsPort > 0, let ip = primaryIP {
            return URL(string: "https://\(ip):\(httpsPort)/health")
        }
        if httpPort > 0, let ip = primaryIP {
            return URL(string: "http://\(ip):\(httpPort)/health")
        }
        return nil
    }

    /// Init URL for probing reachability.
    var initURL: URL? {
        if httpsPort > 0, let ip = primaryIP {
            return URL(string: "https://\(ip):\(httpsPort)/init")
        }
        if httpPort > 0, let ip = primaryIP {
            return URL(string: "http://\(ip):\(httpPort)/init")
        }
        return nil
    }

    /// Build connection URL for a specific IP.
    func connectionURL(for ip: String) -> URL? {
        if httpsPort > 0 {
            return URL(string: "https://\(ip):\(httpsPort)/")
        }
        if httpPort > 0 {
            return URL(string: "http://\(ip):\(httpPort)/")
        }
        return nil
    }

    /// Human-readable device type display.
    var deviceTypeDisplay: String {
        switch deviceType.lowercased() {
        case "phone": return "Phone"
        case "tablet": return "Tablet"
        case "wearable": return "Watch"
        case "laptop": return "Laptop"
        case "desktop": return "Desktop"
        case "tv": return "TV"
        default: return deviceType.capitalized
        }
    }

    /// SF Symbol name for this device type.
    var deviceIconName: String {
        switch deviceType.lowercased() {
        case "phone": return "iphone"
        case "tablet": return "ipad"
        case "wearable": return "applewatch"
        case "laptop": return "laptopcomputer"
        case "desktop": return "desktopcomputer"
        case "tv": return "tv"
        default: return "questionmark.circle"
        }
    }

    // MARK: - Initialization

    init(
        id: String,
        name: String,
        ips: [String] = [],
        httpsPort: Int = 0,
        httpPort: Int = 8080,
        deviceType: String = "phone",
        platform: String = "android",
        version: String = "",
        lastSeen: Date = .now,
        isPaired: Bool = false,
        keychainKeyRef: String? = nil,
        pairingPublicKey: String? = nil,
        isOnline: Bool = false,
        lastConnectedAt: Date? = nil,
        isActive: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.ipsJSON = "[]"
        self.httpsPort = httpsPort
        self.httpPort = httpPort
        self.deviceType = deviceType
        self.platform = platform
        self.version = version
        self.lastSeen = lastSeen
        self.isPaired = isPaired
        self.keychainKeyRef = keychainKeyRef
        self.pairingPublicKey = pairingPublicKey
        self.isOnline = isOnline
        self.lastConnectedAt = lastConnectedAt
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = .now
        // Set ips via computed property after init
        defer { self.ips = ips }
    }

    /// Create a PlainDevice from a discovery reply.
    convenience init(from reply: DiscoverReply) {
        self.init(
            id: reply.id,
            name: reply.name,
            ips: reply.ips,
            httpsPort: reply.port,
            httpPort: reply.port > 0 ? reply.port - 400 : 8080, // Guess HTTP port from HTTPS
            deviceType: reply.deviceType,
            platform: reply.platform,
            version: reply.version,
            lastSeen: .now,
            isOnline: true
        )
    }
}
