import SwiftUI

/// Displays an SF Symbol icon for a device type.
struct DeviceIconView: View {
    let deviceType: String
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size * 0.6))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }

    private var iconName: String {
        switch deviceType.lowercased() {
        case "phone": return "iphone"
        case "tablet": return "ipad"
        case "wearable": return "applewatch"
        case "laptop": return "laptopcomputer"
        case "desktop": return "desktopcomputer"
        case "tv": return "tv"
        default: return "apps.iphone"
        }
    }

    private var iconBackground: Color {
        switch deviceType.lowercased() {
        case "phone": return .blue
        case "tablet": return .indigo
        case "wearable": return .purple
        case "laptop": return .orange
        case "desktop": return .teal
        case "tv": return .pink
        default: return .gray
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        DeviceIconView(deviceType: "phone")
        DeviceIconView(deviceType: "tablet")
        DeviceIconView(deviceType: "laptop")
        DeviceIconView(deviceType: "tv")
    }
    .padding()
}
