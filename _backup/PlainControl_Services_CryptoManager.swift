import Foundation
import CryptoKit
import Security

/// Manages cryptographic operations for device pairing and secure communication.
///
/// Implements the PlainApp pairing protocol:
/// - ECDH P-256 key agreement
/// - Ed25519 digital signatures
/// - XChaCha20-Poly1305 encryption (via CryptoSwift for v2, or delegated to JS in v1)
/// - Secure key storage in the iOS Keychain
///
/// Reference: `CryptoHelper.kt` and `PairingSecurity.kt` in PlainApp Android source.
@MainActor
final class CryptoManager {
    // MARK: - Keychain Keys

    private static let keychainService = "com.plaincontrol.keys"
    private static let keychainAccountPrefix = "plainapp_device_"

    // MARK: - ECDH Key Agreement (P-256)

    /// Generate a new ECDH P-256 key pair for device pairing.
    /// Uses secp256r1 (P-256), matching PlainApp's ECDH implementation.
    func generateECDHKeyPair() -> P256.KeyAgreement.PrivateKey {
        P256.KeyAgreement.PrivateKey()
    }

    /// Export the public key as raw x963 data (uncompressed point, 65 bytes).
    func exportPublicKey(_ privateKey: P256.KeyAgreement.PrivateKey) -> Data {
        privateKey.publicKey.x963Representation
    }

    /// Export the public key as Base64 string (matching PlainApp's wire format).
    func exportPublicKeyBase64(_ privateKey: P256.KeyAgreement.PrivateKey) -> String {
        exportPublicKey(privateKey).base64EncodedString()
    }

    /// Import a peer's public key from Base64-encoded x963 data.
    func importPublicKey(base64: String) throws -> P256.KeyAgreement.PublicKey {
        guard let data = Data(base64Encoded: base64) else {
            throw CryptoError.invalidKeyData
        }
        return try P256.KeyAgreement.PublicKey(x963Representation: data)
    }

    /// Compute the shared secret using ECDH.
    /// - Parameters:
    ///   - myPrivateKey: Our ECDH private key
    ///   - peerPublicKeyData: Peer's public key as x963 data (Base64 decoded)
    /// - Returns: The shared secret as a SymmetricKey (SHA-256 of the ECDH output)
    func computeSharedSecret(
        myPrivateKey: P256.KeyAgreement.PrivateKey,
        peerPublicKeyBase64: String
    ) throws -> SymmetricKey {
        let peerPublicKey = try importPublicKey(base64: peerPublicKeyBase64)
        let sharedSecret = try myPrivateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        // Hash the shared secret to get a 256-bit key
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: "PlainApp-ECDH-v1".data(using: .utf8)!,
            outputByteCount: 32
        )
    }

    // MARK: - Ed25519 Signatures

    /// Generate a new Ed25519 signing key pair.
    func generateEd25519KeyPair() -> Curve25519.Signing.PrivateKey {
        Curve25519.Signing.PrivateKey()
    }

    /// Export the Ed25519 public key as raw 32-byte data (Base64 encoded for wire).
    func exportEd25519PublicKey(_ privateKey: Curve25519.Signing.PrivateKey) -> String {
        privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    /// Sign data with an Ed25519 private key.
    func sign(data: Data, with privateKey: Curve25519.Signing.PrivateKey) throws -> Data {
        try privateKey.signature(for: data)
    }

    /// Verify an Ed25519 signature.
    func verify(
        signature: Data,
        data: Data,
        publicKeyData: Data
    ) throws -> Bool {
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        return publicKey.isValidSignature(signature, for: data)
    }

    /// Verify a pairing request signature (matching `PairingSecurity.verifySignature`).
    func verifyPairingSignature(
        signatureBase64: String,
        signatureData: String,
        publicKeyBase64: String
    ) throws -> Bool {
        guard let signature = Data(base64Encoded: signatureBase64),
              let publicKeyData = Data(base64Encoded: publicKeyBase64),
              let data = signatureData.data(using: .utf8) else {
            throw CryptoError.invalidSignatureData
        }
        return try verify(signature: signature, data: data, publicKeyData: publicKeyData)
    }

    // MARK: - Keychain Storage

    /// Store a symmetric key in the Keychain for a specific device.
    func storeKey(_ key: SymmetricKey, for deviceId: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let account = Self.keychainAccountPrefix + deviceId

        // Build query
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        // Delete any existing key for this device
        SecItemDelete(addQuery as CFDictionary)

        // Add new key
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status: status)
        }
    }

    /// Retrieve a symmetric key from the Keychain for a device.
    func retrieveKey(for deviceId: String) throws -> SymmetricKey? {
        let account = Self.keychainAccountPrefix + deviceId

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw CryptoError.keychainError(status: status)
        }

        return SymmetricKey(data: data)
    }

    /// Delete a key from the Keychain.
    func deleteKey(for deviceId: String) {
        let account = Self.keychainAccountPrefix + deviceId
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - SHA-512 (for password hashing, matching PlainApp)

    /// Compute SHA-512 hash of data, returning first 32 bytes (matching PlainApp's token derivation).
    func sha512First32Bytes(of input: String) -> Data {
        let hash = SHA512.hash(data: input.data(using: .utf8)!)
        return Data(hash.prefix(32))
    }

    /// Compute SHA-256 hash.
    func sha256(_ input: String) -> Data {
        let hash = SHA256.hash(data: input.data(using: .utf8)!)
        return Data(hash)
    }
}

// MARK: - Crypto Errors

enum CryptoError: LocalizedError {
    case invalidKeyData
    case invalidSignatureData
    case keychainError(status: OSStatus)
    case signatureVerificationFailed
    case timestampExpired

    var errorDescription: String? {
        switch self {
        case .invalidKeyData:
            return "Invalid key data format."
        case .invalidSignatureData:
            return "Invalid signature data."
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .signatureVerificationFailed:
            return "Signature verification failed."
        case .timestampExpired:
            return "Pairing timestamp expired (replay protection)."
        }
    }
}
