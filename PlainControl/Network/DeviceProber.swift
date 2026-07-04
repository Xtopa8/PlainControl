import Foundation
final class DeviceProber {
    static func findReachableIP(ips: [String], port: Int, timeout: TimeInterval = 2.0) async -> String? {
        for ip in ips {
            if await probe(ip: ip, port: port, timeout: timeout) { return ip }
        }
        return nil
    }
    static func probeDevice(ip: String, port: Int, timeout: TimeInterval = 3.0) async -> Bool {
        await probe(ip: ip, port: port, timeout: timeout)
    }
    static func probeInit(host: String, port: Int, useTLS: Bool = true, timeout: TimeInterval = 3.0) async -> Bool {
        let scheme = useTLS ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(host):\(port)/init") else { return false }
        var r = URLRequest(url: url); r.httpMethod = "POST"; r.timeoutInterval = timeout
        r.setValue("ios", forHTTPHeaderField: "c-id")
        let s = URLSession(configuration: .ephemeral, delegate: SSLDelegate(), delegateQueue: nil)
        do {
            let (_, resp) = try await s.data(for: r)
            return (resp as? HTTPURLResponse)?.statusCode == 200 || (resp as? HTTPURLResponse)?.statusCode == 204
        } catch { return false }
    }
    private static func probe(ip: String, port: Int, timeout: TimeInterval) async -> Bool {
        guard let url = URL(string: "https://\(ip):\(port)/health") else { return false }
        var r = URLRequest(url: url); r.timeoutInterval = timeout
        let s = URLSession(configuration: .ephemeral, delegate: SSLDelegate(), delegateQueue: nil)
        do {
            let (_, resp) = try await s.data(for: r)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }
}
private final class SSLDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ s: URLSession, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let t = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
        completion(.useCredential, URLCredential(trust: t))
    }
}
