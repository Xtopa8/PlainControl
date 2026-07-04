import Foundation

struct PlainDevice: Identifiable, Codable, Equatable {
    var id: String; var name: String; var ips: [String]
    var httpsPort: Int; var httpPort: Int
    var deviceType: String; var platform: String; var version: String
    var lastSeen: Date; var isOnline: Bool
    var isActive: Bool; var isPaired: Bool

    var primaryIP: String? { ips.first }
    var connectionURL: URL? {
        guard let ip = primaryIP else { return nil }
        let port = httpsPort > 0 ? httpsPort : httpPort
        let scheme = httpsPort > 0 ? "https" : "http"
        return URL(string: "\(scheme)://\(ip):\(port)/")
    }
    var healthURL: URL? {
        guard let ip = primaryIP else { return nil }
        let scheme = httpsPort > 0 ? "https" : "http"
        let port = httpsPort > 0 ? httpsPort : httpPort
        return URL(string: "\(scheme)://\(ip):\(port)/health")
    }

    init(id: String, name: String, ips: [String] = [], httpsPort: Int = 0, httpPort: Int = 8080,
         deviceType: String = "phone", platform: String = "android", version: String = "",
         isOnline: Bool = false, isActive: Bool = false) {
        self.id = id; self.name = name; self.ips = ips
        self.httpsPort = httpsPort; self.httpPort = httpPort
        self.deviceType = deviceType; self.platform = platform; self.version = version
        self.lastSeen = .now; self.isOnline = isOnline
        self.isActive = isActive; self.isPaired = false
    }

}
