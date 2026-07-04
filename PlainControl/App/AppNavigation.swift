import SwiftUI

/// Navigation destinations within the app.
enum AppTab: String, CaseIterable {
    case devices
    case control
    case settings

    var title: String {
        switch self {
        case .devices:
            return "Devices"
        case .control:
            return "Control"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .devices:
            return "rectangle.grid.1x2"
        case .control:
            return "display"
        case .settings:
            return "gear"
        }
    }
}

/// Sheet destinations for modal presentation.
enum AppSheet: Identifiable {
    case addDevice
    case devicePicker
    case pairingRequest(String) // deviceId

    var id: String {
        switch self {
        case .addDevice:
            return "addDevice"
        case .devicePicker:
            return "devicePicker"
        case .pairingRequest(let id):
            return "pairing-\(id)"
        }
    }
}
