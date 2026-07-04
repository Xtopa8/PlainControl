import SwiftUI
import SwiftData

struct DevicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Query(sort: \PlainDevice.lastSeen, order: .reverse) private var devices: [PlainDevice]

    var body: some View {
        NavigationStack {
            List(devices) { device in
                Button {
                    appState.activeDevice = device
                    dismiss()
                } label: {
                    HStack {
                        DeviceIconView(deviceType: device.deviceType, size: 36)
                        VStack(alignment: .leading) {
                            Text(device.name)
                            Text(device.primaryIP ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if device.id == appState.activeDevice?.id {
                            Image(systemName: "checkmark").foregroundStyle(.accent)
                        }
                    }
                }
            }
            .navigationTitle("Switch Device")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
