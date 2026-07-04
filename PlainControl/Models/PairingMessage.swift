import Foundation

/// Pairing request sent via UDP from initiator to responder.
struct PairingRequest: Codable {
    let fromId: String
    let fromName: String
    let port: Int
    let deviceType: String
    let ecdhPublicKey: String
    let signaturePublicKey: String
    let timestamp: Int64
    let ips: [String]
    var signature: String = ""
    var fromIp: String = ""

    enum CodingKeys: String, CodingKey {
        case fromId, fromName, port, deviceType
        case ecdhPublicKey, signaturePublicKey, timestamp
        case ips, signature
    }

    func toSignatureData() -> String {
        "\(fromId)|\(fromName)|\(port)|\(deviceType)|\(ecdhPublicKey)|\(signaturePublicKey)|\(timestamp)|\(ips.joined(separator: ","))"
    }

    static func fromDatagram(_ data: Data) -> PairingRequest? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_REQUEST:") else { return nil }
        let jsonStr = String(text[range.upperBound...])
        guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingRequest.self, from: jsonData)
    }
}

struct PairingResponse: Codable {
    let fromId: String
    let toId: String
    let port: Int
    let deviceType: String
    let ecdhPublicKey: String
    let signaturePublicKey: String
    let accepted: Bool
    let timestamp: Int64
    let ips: [String]
    var signature: String = ""

    enum CodingKeys: String, CodingKey {
        case fromId, toId, port, deviceType
        case ecdhPublicKey, signaturePublicKey, accepted
        case timestamp, ips, signature
    }

    func toSignatureData() -> String {
        "\(fromId)|\(toId)|\(port)|\(deviceType)|\(ecdhPublicKey)|\(signaturePublicKey)|\(accepted)|\(timestamp)|\(ips.joined(separator: ","))"
    }

    static func fromDatagram(_ data: Data) -> PairingResponse? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_RESPONSE:") else { return nil }
        let jsonStr = String(text[range.upperBound...])
        guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingResponse.self, from: jsonData)
    }
}

struct PairingCancel: Codable {
    let fromId: String
    let toId: String

    static func fromDatagram(_ data: Data) -> PairingCancel? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_CANCEL:") else { return nil }
        let jsonStr = String(text[range.upperBound...])
        guard let jsonData = jsonStr.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingCancel.self, from: jsonData)
    }
}
