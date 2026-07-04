import Foundation
import SwiftData

/// Repository for CRUD operations on PlainDevice models.
@MainActor
final class DeviceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [PlainDevice] {
        let descriptor = FetchDescriptor<PlainDevice>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward),
                     SortDescriptor(\.lastSeen, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(by id: String) throws -> PlainDevice? {
        var descriptor = FetchDescriptor<PlainDevice>()
        descriptor.fetchLimit = 1
        let all = try context.fetch(descriptor)
        return all.first { $0.id == id }
    }

    func fetchActive() throws -> PlainDevice? {
        let all = try fetchAll()
        return all.first { $0.isActive }
    }

    func exists(id: String) throws -> Bool {
        try fetch(by: id) != nil
    }

    func count() throws -> Int {
        try context.fetchCount(FetchDescriptor<PlainDevice>())
    }

    func upsert(from reply: DiscoverReply) throws -> PlainDevice {
        if let existing = try fetch(by: reply.id) {
            existing.name = reply.name
            if !reply.ips.isEmpty { existing.setIPs(reply.ips) }
            existing.httpsPort = reply.port
            existing.httpPort = reply.port > 0 ? reply.port - 400 : existing.httpPort
            existing.deviceType = reply.deviceType
            existing.platform = reply.platform
            existing.version = reply.version
            existing.lastSeen = .now
            existing.isOnline = true
            try context.save()
            return existing
        } else {
            let device = PlainDevice(from: reply)
            context.insert(device)
            try context.save()
            return device
        }
    }

    @discardableResult
    func insert(id: String, name: String, ips: [String], httpsPort: Int, httpPort: Int = 8080,
                deviceType: String = "phone", platform: String = "android") throws -> PlainDevice {
        let device = PlainDevice(id: id, name: name, ips: ips, httpsPort: httpsPort,
                                 httpPort: httpPort, deviceType: deviceType, platform: platform)
        context.insert(device)
        try context.save()
        return device
    }

    func delete(_ device: PlainDevice) throws {
        context.delete(device)
        try context.save()
    }

    func delete(by id: String) throws {
        guard let device = try fetch(by: id) else { return }
        context.delete(device)
        try context.save()
    }

    func setActive(_ device: PlainDevice) throws {
        let all = try fetchAll()
        for d in all where d.isActive && d.id != device.id {
            d.isActive = false
        }
        device.isActive = true
        device.lastConnectedAt = .now
        try context.save()
    }

    func clearActive() throws {
        let all = try fetchAll()
        for d in all { d.isActive = false }
        try context.save()
    }

    func updateOnlineStatus(id: String, online: Bool) throws {
        guard let device = try fetch(by: id) else { return }
        device.isOnline = online
        if online { device.lastSeen = .now }
        try context.save()
    }

    func rename(_ device: PlainDevice, to newName: String) throws {
        device.name = newName
        try context.save()
    }

    func updateSortOrder(_ device: PlainDevice, order: Int) throws {
        device.sortOrder = order
        try context.save()
    }

    func markAllOffline() throws {
        let all = try fetchAll()
        for d in all { d.isOnline = false }
        try context.save()
    }

    func deleteAll() throws {
        let all = try fetchAll()
        for d in all { context.delete(d) }
        try context.save()
    }
}
