import SwiftUI
import Charts

struct ToolsView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Benchmark
                        toolSection(title: "Benchmark DNS") {
                            Button("Đo độ trễ DNS") {
                                Task { await vm.benchmarkDNS() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            
                            if vm.isBenchmarking {
                                ProgressView()
                            } else if !vm.benchmarkResults.isEmpty {
                                Chart {
                                    ForEach(vm.benchmarkResults.sorted(by: { $0.key.name < $1.key.name }), id: \.key.id) { preset, latency in
                                        BarMark(
                                            x: .value("Độ trễ", latency),
                                            y: .value("DNS", preset.name)
                                        )
                                        .foregroundStyle(latency < 50 ? Color.green : (latency < 100 ? Color.orange : Color.red))
                                        .annotation(position: .trailing) {
                                            Text(String(format: "%.0f ms", latency)).font(.caption).foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(height: 150)
                                .padding(.vertical)
                                
                                Button("Tự chọn nhanh nhất") {
                                    vm.pickFastestDNS()
                                }
                                .font(.footnote)
                                .foregroundColor(.cyan)
                            }
                        }
                        
                        // Connection
                        toolSection(title: "Kiểm tra kết nối") {
                            Button("Ping Test") {
                                Task { await vm.testConnection() }
                            }
                            .buttonStyle(.bordered)
                            
                            if !vm.connectionStatus.isEmpty {
                                Text(vm.connectionStatus)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            
                            Button("Test tốc độ mạng") {
                                Task { await vm.testNetworkSpeed() }
                            }
                            .buttonStyle(.bordered)
                            
                            if !vm.speedTestResult.isEmpty {
                                Text(vm.speedTestResult)
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        // Adblock
                        toolSection(title: "Chặn quảng cáo") {
                            Toggle("Sử dụng AdGuard DNS", isOn: Binding(
                                get: { vm.activePreset.id == DNSPreset.adguard.id },
                                set: { isOn in
                                    withAnimation(.spring()) {
                                        vm.activePreset = isOn ? .adguard : .cloudflare
                                    }
                                }
                            ))
                            .tint(.green)
                            .foregroundColor(.white)
                        }
                        
                        // Cache
                        toolSection(title: "Dọn dẹp") {
                            Button(role: .destructive) {
                                vm.clearImportedFiles()
                            } label: {
                                Label("Xóa cache file đã nhập", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // History
                        toolSection(title: "Lịch sử Activate") {
                            if vm.history.isEmpty {
                                Text("Chưa có dữ liệu")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            } else {
                                ForEach(vm.history) { item in
                                    VStack(alignment: .leading) {
                                        Text(item.message)
                                            .foregroundColor(.white)
                                            .font(.subheadline)
                                        Text(item.date, style: .time)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 4)
                                    Divider().background(Color.white.opacity(0.2))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Công cụ")
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color.black, Color.purple.opacity(0.2), Color.blue.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    private func toolSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
