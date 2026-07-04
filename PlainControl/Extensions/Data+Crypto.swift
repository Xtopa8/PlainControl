import Foundation

// MARK: - Data Extensions for Cryptographic Operations

extension Data {
    /// Convert Data to a hex-encoded string.
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    /// Initialize Data from a hex string.
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex

        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }

    /// Encode data to a Base64 string.
    var base64Encoded: String {
        base64EncodedString()
    }

    /// URL-safe Base64 encoding (no padding).
    var base64URLSafe: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - String Extensions

extension String {
    /// Decode a Base64 string to Data.
    var base64Decoded: Data? {
        Data(base64Encoded: self)
    }

    /// Decode a URL-safe Base64 string to Data.
    var base64URLSafeDecoded: Data? {
        var str = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Restore padding
        let remainder = str.count % 4
        if remainder > 0 {
            str += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: str)
    }
}
