import Foundation
struct PlainDevice: Identifiable, Codable, Equatable {
    var id: String; var name: String; var ip: String; var port: Int
    var isOnline: Bool; var isActive: Bool
    init(id:String="",name:String="",ip:String="",port:Int=8080,isOnline:Bool=false,isActive:Bool=false){
        self.id=id;self.name=name;self.ip=ip;self.port=port;self.isOnline=isOnline;self.isActive=isActive
    }
}
