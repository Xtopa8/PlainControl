import Foundation
struct DiscoverRequest: Codable { let fromId: String; let toId: String }
struct DiscoverReply: Codable, Identifiable {
    let id: String; let name: String; let port: Int
    let deviceType: String; let version: String; let platform: String; let ips: [String]
    static func fromDatagram(_ data: Data) -> DiscoverReply? {
        guard let t = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "DISCOVER_REPLY:", with: ""),
              let d = t.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DiscoverReply.self, from: d)
    }
}
