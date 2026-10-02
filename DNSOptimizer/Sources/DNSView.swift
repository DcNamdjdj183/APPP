import SwiftUI

struct DNSView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 30) {
                        statusCard
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Máy chủ DNS")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ForEach(DNSPreset.all) { preset in
                                    presetRow(preset)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Cài đặt nâng cao")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                            
                            Toggle(isOn: $vm.isOnDemandWiFiOnly) {
                                HStack {
                                    Image(systemName: "wifi")
                                        .foregroundColor(.cyan)
                                    Text("Chỉ kích hoạt trên Wi-Fi")
                                        .font(.system(.body, design: .rounded))
                                }
                            }
                            .tint(.cyan)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        Button {
                            vm.triggerHaptic(.medium)
                            vm.installDNS()
                        } label: {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("Cài đặt cấu hình mạng")
                            }
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 8)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Nếu lưu dưới dạng mobileconfig, hãy mở nó trong ứng dụng Tệp, sau đó vào Cài đặt hệ thống để cài đặt profile.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 20) {
                                Button("Mở Cài đặt") { vm.openSettings() }
                                    .font(.system(.footnote, design: .rounded).bold())
                                    .foregroundColor(.cyan)
                                
                                Button("Tôi đã cài xong") {
                                    withAnimation(.spring()) { vm.isDNSActive = true }
                                }
                                .font(.system(.footnote, design: .rounded).bold())
                                .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Bảo vệ DNS")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { vm.checkDNSStatus() }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color(red: 0.1, green: 0.0, blue: 0.2), Color(red: 0.0, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    private var statusCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(vm.isDNSActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: vm.isDNSActive ? "checkmark.shield.fill" : "shield.slash.fill")
                    .font(.system(size: 32))
                    .foregroundColor(vm.isDNSActive ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.isDNSActive ? "Đang bảo vệ" : "Chưa kích hoạt")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(vm.isDNSActive ? .green : .white)
                Text(vm.isDNSActive ? "Đang sử dụng \(vm.activePreset.name)" : "Mạng không được mã hoá DNS")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(vm.isDNSActive ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: vm.isDNSActive ? Color.green.opacity(0.15) : .clear, radius: 20, x: 0, y: 10)
    }
    
    private func presetRow(_ preset: DNSPreset) -> some View {
        let isSelected = vm.activePreset.id == preset.id
        return Button {
            withAnimation(.spring()) {
                vm.triggerHaptic(.light)
                vm.activePreset = preset
            }
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Text(preset.primaryIP)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.cyan : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.cyan.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
