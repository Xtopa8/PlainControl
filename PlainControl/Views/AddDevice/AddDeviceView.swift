import SwiftUI
struct AddDeviceView: View {
    @EnvironmentObject var s: AppState; @Environment(\.dismiss) var d
    @State private var h=""; @State private var p="8443"
    var body: some View {
        NavigationStack{
            Form{
                TextField("IP",text:$h).keyboardType(.URL).autocapitalization(.none)
                TextField("Port",text:$p).keyboardType(.numberPad)
                Button("Add"){
                    if let port=Int(p),!h.isEmpty{
                        s.add(PlainDevice(id:UUID().uuidString,name:h,ip:h,port:port))
                        d()
                    }
                }.disabled(h.isEmpty)
            }
            .navigationTitle("Add Device")
            .toolbar{Button("Cancel"){d()}}
        }
    }
}
