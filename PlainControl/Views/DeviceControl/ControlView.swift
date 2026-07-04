import SwiftUI
struct ControlView: View {
    @EnvironmentObject var s: AppState
    var body: some View {
        VStack(spacing:20){
            if let d=s.activeDevice{
                Image(systemName:"display").font(.system(size:48))
                Text(d.name).font(.title2)
                Text("\(d.ip):\(d.port)").font(.caption).foregroundStyle(.secondary)
                Button("Disconnect"){s.activeDevice=nil}
            }else{
                Image(systemName:"display").font(.system(size:48)).foregroundStyle(.secondary)
                Text("No Device").font(.title2)
            }
        }
    }
}
