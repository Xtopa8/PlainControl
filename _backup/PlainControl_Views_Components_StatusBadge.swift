import SwiftUI

/// A small colored dot indicator showing device connection status.
struct StatusBadge: View {
    let status: DeviceStatus
    var showLabel: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            if showLabel {
                Text(status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .online: return .green
        case .offline: return .gray
        case .connecting: return .yellow
        case .error: return .red
        }
    }
}

/// A pill-shaped status indicator for toolbar use.
struct StatusPill: View {
    let status: DeviceStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .online: return .green
        case .offline: return .secondary
        case .connecting: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusBadge(status: .online, showLabel: true)
        StatusBadge(status: .offline, showLabel: true)
        StatusBadge(status: .connecting, showLabel: true)
        StatusBadge(status: .error, showLabel: true)

        Divider()

        StatusPill(status: .online)
        StatusPill(status: .offline)
        StatusPill(status: .connecting)
        StatusPill(status: .error)
    }
    .padding()
}
