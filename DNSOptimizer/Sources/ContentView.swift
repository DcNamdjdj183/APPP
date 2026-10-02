import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SharedViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        TabView {
            HomeView(vm: vm)
                .tabItem { Label("Trang chủ", systemImage: "house.fill") }
            DNSView(vm: vm)
                .tabItem { Label("DNS", systemImage: "network") }
            ToolsView(vm: vm)
                .tabItem { Label("Công cụ", systemImage: "wrench.and.screwdriver.fill") }
        }
        .tint(.cyan)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                vm.checkDNSStatus()
            }
        }
    }
}
