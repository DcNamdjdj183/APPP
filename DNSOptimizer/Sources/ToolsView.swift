import SwiftUI
import Charts

struct ToolsView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Benchmark
                        toolSection(title: "Tối ưu tốc độ", icon: "bolt.horizontal.fill") {
                            VStack(spacing: 16) {
                                Button {
                                    vm.triggerHaptic(.medium)
                                    Task { await vm.benchmarkDNS() }
                                } label: {
                                    HStack {
                                        Image(systemName: "timer")
                                        Text("Đo độ trễ DNS")
                                    }
                                    .font(.system(.body, design: .rounded).bold())
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(ModernButtonStyle(color: .indigo))
                                
                                if vm.isBenchmarking {
                                    ProgressView().tint(.white)
                                } else if !vm.benchmarkResults.isEmpty {
                                    Chart {
                                        ForEach(vm.benchmarkResults.sorted(by: { $0.key.name < $1.key.name }), id: \.key.id) { preset, latency in
                                            BarMark(
                                                x: .value("Độ trễ", latency),
                                                y: .value("DNS", preset.name)
                                            )
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: latency < 50 ? [.green, .mint] : (latency < 100 ? [.orange, .yellow] : [.red, .pink]),
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(4)
                                            .annotation(position: .trailing) {
                                                Text(String(format: "%.0f ms", latency)).font(.caption2).foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .frame(height: 140)
                                    .chartXAxis(.hidden)
                                    
                                    Button("Tự chọn DNS nhanh nhất") {
                                        vm.pickFastestDNS()
                                    }
                                    .font(.system(.footnote, design: .rounded).bold())
                                    .foregroundColor(.cyan)
                                }
                            }
                        }
                        
                        // Connection
                        toolSection(title: "Kiểm tra mạng", icon: "network") {
                            HStack(spacing: 12) {
                                Button { Task { await vm.testConnection() } } label: {
                                    Text("Ping").font(.system(.body, design: .rounded).bold()).frame(maxWidth: .infinity)
                                }
                                .buttonStyle(ModernButtonStyle(color: .blue))
                                
                                Button { Task { await vm.testNetworkSpeed() } } label: {
                                    Text("Speed Test").font(.system(.body, design: .rounded).bold()).frame(maxWidth: .infinity)
                                }
                                .buttonStyle(ModernButtonStyle(color: .cyan))
                            }
                            
                            if !vm.connectionStatus.isEmpty || !vm.speedTestResult.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    if !vm.connectionStatus.isEmpty {
                                        Text(vm.connectionStatus).font(.system(.subheadline, design: .rounded)).foregroundColor(.white)
                                    }
                                    if !vm.speedTestResult.isEmpty {
                                        Text(vm.speedTestResult).font(.system(.subheadline, design: .rounded)).foregroundColor(.cyan)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Adblock
                        toolSection(title: "Chặn quảng cáo", icon: "hand.raised.slash.fill") {
                            Toggle(isOn: Binding(
                                get: { vm.activePreset.id == DNSPreset.adguard.id },
                                set: { isOn in
                                    withAnimation(.spring()) {
                                        vm.triggerHaptic(.light)
                                        vm.activePreset = isOn ? .adguard : .cloudflare
                                    }
                                }
                            )) {
                                Text("Sử dụng AdGuard DNS")
                                    .font(.system(.body, design: .rounded))
                            }
                            .tint(.green)
                        }
                        
                        // Cache & History
                        toolSection(title: "Hệ thống", icon: "gearshape.fill") {
                            Button(role: .destructive) {
                                vm.clearImportedFiles()
                            } label: {
                                Label("Xóa cache file đã dán/nhập", systemImage: "trash")
                                    .font(.system(.body, design: .rounded).bold())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ModernButtonStyle(color: .red, isDestructive: true))
                            
                            if !vm.history.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Lịch sử hoạt động")
                                        .font(.system(.subheadline, design: .rounded).bold())
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 8)
                                    
                                    ForEach(vm.history) { item in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.message)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.white)
                                            Text(item.date, style: .time)
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 8)
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Công cụ")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color(red: 0.0, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.15)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    private func toolSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(.white)
            }
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct ModernButtonStyle: ButtonStyle {
    var color: Color
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                isDestructive ? Color.red.opacity(0.2) : color.opacity(0.2)
            )
            .foregroundColor(isDestructive ? .red : color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDestructive ? Color.red.opacity(0.5) : color.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
