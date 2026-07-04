import SwiftUI
import SwiftData

/// Container for adding a new device via scan, manual entry, or QR code.
struct AddDeviceView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: AddDeviceTab = .scan

    // Scan state
    @State private var discoveredDevices: [DiscoverReply] = []
    @State private var isScanning = false
    @State private var isConnecting = false
    @State private var connectingDeviceId: String?

    // Manual entry
    @State private var manualHost = ""
    @State private var manualPort = "8443"

    // QR
    @StateObject private var scannerService = QRScannerService()

    // Common
    @State private var errorMessage: String?
    @State private var discoveryService = DiscoveryService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedTab) {
                    ForEach(AddDeviceTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented).padding()

                Group {
                    switch selectedTab {
                    case .scan: scanTab
                    case .manual: manualTab
                    case .qr: qrTab
                    }
                }
            }
            .navigationTitle("Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        discoveryService.stopScan()
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Scan Tab

    private var scanTab: some View {
        VStack {
            if isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView().scaleEffect(1.5)
                    Text("Scanning...").font(.headline)
                    Text("Searching on your local network").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Button("Stop") { stopScan() }.buttonStyle(.bordered)
                }
            } else if discoveredDevices.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "magnifying.glass").font(.system(size: 48)).foregroundStyle(.secondary)
                    Text("Tap Scan to Start").font(.title3)
                    Text("Make sure devices are on the same Wi-Fi\nand PlainApp is running.")
                        .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button { startScan() } label: {
                        Label("Start Scan", systemImage: "antenna.radiowaves.left.and.right").font(.headline)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    Spacer()
                }
            } else {
                List {
                    Section("Found \(discoveredDevices.count) Device(s)") {
                        ForEach(discoveredDevices) { device in
                            HStack(spacing: 14) {
                                DeviceIconView(deviceType: device.deviceType)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name).font(.body).fontWeight(.medium)
                                    Text("\(device.ips.first ?? "?"):\(device.port)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isConnecting && connectingDeviceId == device.id {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Button("Connect") {
                                        Task { await connectToDevice(device) }
                                    }
                                    .buttonStyle(.borderedProminent).controlSize(.small)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Manual Tab

    private var manualTab: some View {
        Form {
            Section("Device Address") {
                TextField("IP Address", text: $manualHost)
                    .textContentType(.URL).keyboardType(.URL).autocapitalization(.none)
                TextField("Port", text: $manualPort).keyboardType(.numberPad)
                Text("Example: 192.168.1.100:8443").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button {
                    Task { await addManualDevice() }
                } label: {
                    HStack {
                        Spacer()
                        if isConnecting { ProgressView().scaleEffect(0.8) }
                        else { Label("Connect", systemImage: "link") }
                        Spacer()
                    }
                }
                .disabled(manualHost.isEmpty || isConnecting)
            }
        }
    }

    // MARK: - QR Tab

    private var qrTab: some View {
        VStack {
            if scannerService.isScanning {
                ZStack {
                    QRScannerPreview(captureSession: scannerService.captureSession)
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                    VStack {
                        Text("Point at PlainApp QR code").font(.headline).foregroundStyle(.white)
                            .padding().background(.black.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                        Image(systemName: "qrcode.viewfinder").font(.system(size: 200))
                            .foregroundStyle(.white.opacity(0.5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2)
                                    .frame(width: 220, height: 220)
                            }
                        Spacer()
                        Button("Cancel") { scannerService.stopScanning() }
                            .buttonStyle(.borderedProminent).tint(.white).padding(.bottom, 40)
                    }
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "qrcode.viewfinder").font(.system(size: 64)).foregroundStyle(.secondary)
                    Text("Scan QR Code").font(.title3)
                    Text("Display the QR code from the PlainApp\nsettings on your Android device.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    if let err = scannerService.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                    Button { scannerService.startScanning() } label: {
                        Label("Start Camera", systemImage: "camera.fill").font(.headline)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    Spacer()
                }
            }
        }
        .onChange(of: scannerService.scannedValue) { value in
            if let value {
                handleQRCode(value)
            }
        }
        .onDisappear { scannerService.stopScanning() }
    }

    // MARK: - Actions

    private func startScan() {
        isScanning = true
        discoveredDevices = []
        // Poll for discovered devices
        discoveryService.onReplyReceived = { reply in
            if !discoveredDevices.contains(where: { $0.id == reply.id }) {
                discoveredDevices.append(reply)
            }
        }
        discoveryService.startScan()
        // Stop scanning after 15 seconds
        Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            stopScan()
        }
    }

    private func stopScan() {
        isScanning = false
        discoveryService.stopScan()
    }

    private func connectToDevice(_ reply: DiscoverReply) async {
        isConnecting = true
        connectingDeviceId = reply.id
        errorMessage = nil

        let repo = DeviceRepository(context: modelContext)
        let connMgr = ConnectionManager(appState: appState)

        do {
            let device = try repo.upsert(from: reply)
            try repo.setActive(device)
            try await connMgr.connect(to: device)
            appState.activeDevice = device
            stopScan()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
        connectingDeviceId = nil
    }

    private func addManualDevice() async {
        guard !manualHost.isEmpty, let port = Int(manualPort), port > 0, port <= 65535 else {
            errorMessage = "Please enter a valid IP and port."
            return
        }

        isConnecting = true
        errorMessage = nil

        let repo = DeviceRepository(context: modelContext)
        let connMgr = ConnectionManager(appState: appState)

        do {
            // Probe
            let reachable = await DeviceProber.probeDevice(ip: manualHost, port: port)
            guard reachable else {
                errorMessage = "Device is not reachable at \(manualHost):\(port)"
                isConnecting = false
                return
            }

            // Create and connect
            let deviceId = "manual-\(manualHost.replacingOccurrences(of: ".", with: "-"))"
            let device = try repo.insert(id: deviceId, name: "Device @ \(manualHost)", ips: [manualHost], httpsPort: port)
            try repo.setActive(device)
            try await connMgr.connect(to: device)
            appState.activeDevice = device
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    private func handleQRCode(_ value: String) {
        scannerService.stopScanning()
        if let url = URL(string: value), let host = url.host, let port = url.port {
            manualHost = host
            manualPort = "\(port)"
            selectedTab = .manual
        } else if value.hasPrefix("plainapp://") {
            let parts = value.replacingOccurrences(of: "plainapp://", with: "").components(separatedBy: ":")
            if parts.count == 2 {
                manualHost = parts[0]
                manualPort = parts[1]
                selectedTab = .manual
            } else {
                errorMessage = "Invalid QR code format."
            }
        } else {
            errorMessage = "Could not parse QR code as a device URL."
        }
    }
}

// MARK: - QR Preview

private struct QRScannerPreview: UIViewRepresentable {
    let captureSession: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(); view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Preview

#Preview {
    AddDeviceView().environmentObject(AppState())
}
