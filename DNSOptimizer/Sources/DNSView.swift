import SwiftUI

struct DNSView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 25) {
                        statusCard
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Chọn máy chủ DNS")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(DNSPreset.all) { preset in
                                presetRow(preset)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Chỉ dùng trên Wi-Fi", isOn: $vm.isOnDemandWiFiOnly)
                                .tint(.cyan)
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        Button {
                            vm.installDNS()
                        } label: {
                            Text("Install DNS")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.cyan)
                                .cornerRadius(20)
                                .shadow(color: .cyan.opacity(0.5), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                        
                        Text("Nếu cấu hình được lưu vào Tệp (dạng mobileconfig), hãy mở nó, sau đó vào Cài đặt > Cài đặt chung > VPN & Quản lý thiết bị để cài đặt.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Mở Cài đặt hệ thống") {
                            vm.openSettings()
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        
                        Button("Tôi đã cài (Xác nhận thủ công)") {
                            withAnimation(.spring) {
                                vm.isDNSActive = true
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.green)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("DNS")
            .onAppear {
                vm.checkDNSStatus()
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color.black, Color.blue.opacity(0.2), Color.purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    private var statusCard: some View {
        HStack(spacing: 15) {
            Image(systemName: vm.isDNSActive ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(vm.isDNSActive ? .green : .gray)
                .symbolEffect(.bounce, value: vm.isDNSActive)
            
            VStack(alignment: .leading) {
                Text(vm.isDNSActive ? "DNS đang hoạt động" : "Chưa chọn DNS")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(vm.isDNSActive ? "Máy chủ: \(vm.activePreset.name)" : "Hệ thống đang dùng DNS mặc định")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private func presetRow(_ preset: DNSPreset) -> some View {
        Button {
            withAnimation(.spring) {
                vm.activePreset = preset
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(preset.name)
                        .font(.body.bold())
                        .foregroundColor(.white)
                    Text(preset.primaryIP)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if vm.activePreset.id == preset.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cyan)
                        .font(.title2)
                        .transition(.scale)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(vm.activePreset.id == preset.id ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
    }
}
