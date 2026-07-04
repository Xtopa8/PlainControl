import SwiftUI

struct DevicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlainDevice.lastSeen, order: .reverse) private var devices: [PlainDevice]

    var body: some View {
        NavigationStack {
            List(devices, id: \.id) { device in
                Button {
                    appState.activeDevice = device
                    dismiss()
                } label: {
                    HStack {
                        DeviceIconView(deviceType: device.deviceType, size: 36)
                        VStack(alignment: .leading) {
                            Text(device.name).foregroundStyle(.primary)
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
