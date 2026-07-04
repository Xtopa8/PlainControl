import Foundation
import SwiftData

/// Repository for CRUD operations on PlainDevice SwiftData models.
///
/// Provides async-safe access to the device store with
/// automatic main-actor dispatching for SwiftUI observation.
@MainActor
final class DeviceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Queries

    /// Fetch all devices, sorted by sort order then last seen.
    func fetchAll() throws -> [PlainDevice] {
        let descriptor = FetchDescriptor<PlainDevice>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.lastSeen, order: .reverse),
            ]
        )
        return try context.fetch(descriptor)
    }

    /// Fetch a device by its unique ID.
    func fetch(by id: String) throws -> PlainDevice? {
        let predicate = #Predicate<PlainDevice> { device in
            device.id == id
        }
        let descriptor = FetchDescriptor<PlainDevice>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Fetch the currently active device (if any).
    func fetchActive() throws -> PlainDevice? {
        let predicate = #Predicate<PlainDevice> { device in
            device.isActive == true
        }
        let descriptor = FetchDescriptor<PlainDevice>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Check if a device with the given ID already exists.
    func exists(id: String) throws -> Bool {
        try fetch(by: id) != nil
    }

    /// Get the count of saved devices.
    func count() throws -> Int {
        try context.fetchCount(FetchDescriptor<PlainDevice>())
    }

    // MARK: - Mutations

    /// Insert or update a device from a discovery reply.
    /// If the device already exists, updates its IPs, port, lastSeen, and online status.
    /// Returns the upserted device.
    func upsert(from reply: DiscoverReply) throws -> PlainDevice {
        if let existing = try fetch(by: reply.id) {
            // Update existing
            existing.name = reply.name
            existing.ips = reply.ips.isEmpty ? existing.ips : reply.ips
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
            // Create new
            let device = PlainDevice(from: reply)
            context.insert(device)
            try context.save()
            return device
        }
    }

    /// Insert a new device manually (e.g., from manual IP entry).
    @discardableResult
    func insert(
        id: String,
        name: String,
        ips: [String],
        httpsPort: Int,
        httpPort: Int = 8080,
        deviceType: String = "phone",
        platform: String = "android"
    ) throws -> PlainDevice {
        let device = PlainDevice(
            id: id,
            name: name,
            ips: ips,
            httpsPort: httpsPort,
            httpPort: httpPort,
            deviceType: deviceType,
            platform: platform
        )
        context.insert(device)
        try context.save()
        return device
    }

    /// Delete a device.
    func delete(_ device: PlainDevice) throws {
        context.delete(device)
        try context.save()
    }

    /// Delete a device by ID.
    func delete(by id: String) throws {
        guard let device = try fetch(by: id) else { return }
        context.delete(device)
        try context.save()
    }

    /// Set a device as the active (selected) device.
    /// Deactivates all other devices first.
    func setActive(_ device: PlainDevice) throws {
        // Deactivate current active device
        if let current = try fetchActive(), current.id != device.id {
            current.isActive = false
        }
        device.isActive = true
        device.lastConnectedAt = .now
        try context.save()
    }

    /// Clear the active device (deselect all).
    func clearActive() throws {
        if let current = try fetchActive() {
            current.isActive = false
            try context.save()
        }
    }

    /// Update the online status for a device by ID.
    func updateOnlineStatus(id: String, online: Bool) throws {
        guard let device = try fetch(by: id) else { return }
        device.isOnline = online
        if online {
            device.lastSeen = .now
        }
        try context.save()
    }

    /// Rename a device.
    func rename(_ device: PlainDevice, to newName: String) throws {
        device.name = newName
        try context.save()
    }

    /// Update the sort order for a device.
    func updateSortOrder(_ device: PlainDevice, order: Int) throws {
        device.sortOrder = order
        try context.save()
    }

    /// Mark all devices as offline (e.g., on network change).
    func markAllOffline() throws {
        let all = try fetchAll()
        for device in all {
            device.isOnline = false
        }
        try context.save()
    }

    /// Delete all devices.
    func deleteAll() throws {
        let all = try fetchAll()
        for device in all {
            context.delete(device)
        }
        try context.save()
    }
}
