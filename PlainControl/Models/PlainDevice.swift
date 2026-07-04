import Foundation

struct PlainDevice: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var ips: [String]
    var httpsPort: Int
    var httpPort: Int
    var deviceType: String
    var platform: String
    var version: String
    var lastSeen: Date
    var isPaired: Bool
    var keychainKeyRef: String?
    var pairingPublicKey: String?
    var isOnline: Bool
    var lastConnectedAt: Date?
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date

    var primaryIP: String? { ips.first }

    var connectionURL: URL? {
        guard let ip = primaryIP else { return nil }
        if httpsPort > 0 { return URL(string: "https://\(ip):\(httpsPort)/") }
        if httpPort > 0 { return URL(string: "http://\(ip):\(httpPort)/") }
        return nil
    }

    var healthURL: URL? {
        guard let ip = primaryIP else { return nil }
        if httpsPort > 0 { return URL(string: "https://\(ip):\(httpsPort)/health") }
        return URL(string: "http://\(ip):\(httpPort)/health")
    }

    init(id: String, name: String, ips: [String] = [], httpsPort: Int = 0, httpPort: Int = 8080,
         deviceType: String = "phone", platform: String = "android", version: String = "",
         lastSeen: Date = .now, isPaired: Bool = false, keychainKeyRef: String? = nil,
         pairingPublicKey: String? = nil, isOnline: Bool = false, lastConnectedAt: Date? = nil,
         isActive: Bool = false, sortOrder: Int = 0) {
        self.id = id; self.name = name; self.ips = ips
        self.httpsPort = httpsPort; self.httpPort = httpPort
        self.deviceType = deviceType; self.platform = platform; self.version = version
        self.lastSeen = lastSeen; self.isPaired = isPaired
        self.keychainKeyRef = keychainKeyRef; self.pairingPublicKey = pairingPublicKey
        self.isOnline = isOnline; self.lastConnectedAt = lastConnectedAt
        self.isActive = isActive; self.sortOrder = sortOrder; self.createdAt = .now
    }

    init(from reply: DiscoverReply) {
        self.init(id: reply.id, name: reply.name, ips: reply.ips, httpsPort: reply.port,
                  httpPort: reply.port > 0 ? reply.port - 400 : 8080,
                  deviceType: reply.deviceType, platform: reply.platform, version: reply.version,
                  lastSeen: .now, isOnline: true)
    }
}
