import Foundation

/// Pairing request sent via UDP from initiator to responder.
///
/// Mirrors `DPairingRequest` from `shared/src/commonMain/.../data/DPairingMessages.kt`
struct PairingRequest: Codable {
    let fromId: String
    let fromName: String
    let port: Int
    let deviceType: String
    let ecdhPublicKey: String       // ECDH public key (Base64)
    let signaturePublicKey: String  // Ed25519 public key (Base64)
    let timestamp: Int64            // Unix timestamp for replay protection
    let ips: [String]
    var signature: String           // Ed25519 signature of content (Base64)
    var fromIp: String              // Set by receiver, not serialized by sender

    enum CodingKeys: String, CodingKey {
        case fromId
        case fromName
        case port
        case deviceType
        case ecdhPublicKey
        case signaturePublicKey
        case timestamp
        case ips
        case signature
        // fromIp is not in the wire format
    }

    /// Build the signature data string as defined in the PlainApp protocol.
    func toSignatureData() -> String {
        return "\(fromId)|\(fromName)|\(port)|\(deviceType)|\(ecdhPublicKey)|\(signaturePublicKey)|\(timestamp)|\(ips.joined(separator: ","))"
    }

    /// Parse from UDP datagram with "PAIR_REQUEST:" prefix.
    static func fromDatagram(_ data: Data) -> PairingRequest? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_REQUEST:") else { return nil }
        let jsonString = String(text[range.upperBound...])
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingRequest.self, from: jsonData)
    }
}

/// Pairing response sent via UDP from responder to initiator.
///
/// Mirrors `DPairingResponse` from `shared/src/commonMain/.../data/DPairingMessages.kt`
struct PairingResponse: Codable {
    let fromId: String
    let toId: String
    let port: Int
    let deviceType: String
    let ecdhPublicKey: String       // ECDH public key (Base64)
    let signaturePublicKey: String  // Ed25519 public key (Base64)
    let accepted: Bool
    let timestamp: Int64            // Unix timestamp for replay protection
    let ips: [String]
    var signature: String           // Ed25519 signature (Base64)

    enum CodingKeys: String, CodingKey {
        case fromId
        case toId
        case port
        case deviceType
        case ecdhPublicKey
        case signaturePublicKey
        case accepted
        case timestamp
        case ips
        case signature
    }

    func toSignatureData() -> String {
        return "\(fromId)|\(toId)|\(port)|\(deviceType)|\(ecdhPublicKey)|\(signaturePublicKey)|\(accepted)|\(timestamp)|\(ips.joined(separator: ","))"
    }

    /// Parse from UDP datagram with "PAIR_RESPONSE:" prefix.
    static func fromDatagram(_ data: Data) -> PairingResponse? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_RESPONSE:") else { return nil }
        let jsonString = String(text[range.upperBound...])
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingResponse.self, from: jsonData)
    }
}

/// Pairing cancel message.
///
/// Mirrors `DPairingCancel` from `shared/src/commonMain/.../data/DPairingMessages.kt`
struct PairingCancel: Codable {
    let fromId: String
    let toId: String

    /// Parse from UDP datagram with "PAIR_CANCEL:" prefix.
    static func fromDatagram(_ data: Data) -> PairingCancel? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: "PAIR_CANCEL:") else { return nil }
        let jsonString = String(text[range.upperBound...])
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PairingCancel.self, from: jsonData)
    }
}
