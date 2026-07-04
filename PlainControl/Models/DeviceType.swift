import Foundation

/// Device type matching PlainApp's `DeviceType` enum values.
enum PlainDeviceType: String, Codable, CaseIterable {
    case phone = "phone"
    case tablet = "tablet"
    case wearable = "wearable"
    case laptop = "laptop"
    case desktop = "desktop"
    case tv = "tv"
    case other = "other"

    var displayName: String {
        switch self {
        case .phone: return "Phone"
        case .tablet: return "Tablet"
        case .wearable: return "Wearable"
        case .laptop: return "Laptop"
        case .desktop: return "Desktop"
        case .tv: return "TV"
        case .other: return "Device"
        }
    }

    var iconName: String {
        switch self {
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .wearable: return "applewatch"
        case .laptop: return "laptopcomputer"
        case .desktop: return "desktopcomputer"
        case .tv: return "tv"
        case .other: return "questionmark.circle"
        }
    }
}

/// Device platform enum matching PlainApp's `DevicePlatform`.
enum PlainDevicePlatform: String, Codable {
    case android = "android"
    case ios = "ios"
    case macos = "macos"
    case windows = "windows"
    case linux = "linux"

    var displayName: String {
        switch self {
        case .android: return "Android"
        case .ios: return "iOS"
        case .macos: return "macOS"
        case .windows: return "Windows"
        case .linux: return "Linux"
        }
    }
}

/// Screen mirror control action matching `ScreenMirrorControlAction` enum.
enum ScreenMirrorAction: String, Codable {
    case tap = "TAP"
    case longPress = "LONG_PRESS"
    case swipe = "SWIPE"
    case scroll = "SCROLL"
    case back = "BACK"
    case home = "HOME"
    case recents = "RECENTS"
    case lockScreen = "LOCK_SCREEN"
    case key = "KEY"
}

/// Screen mirror control input matching `ScreenMirrorControlInput` data class.
struct ScreenMirrorInput: Codable {
    let action: ScreenMirrorAction
    let x: Float?
    let y: Float?
    let endX: Float?
    let endY: Float?
    let duration: Int64?
    let deltaX: Float?
    let deltaY: Float?
    let key: String?
}
