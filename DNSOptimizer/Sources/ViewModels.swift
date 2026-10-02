import Foundation
import NetworkExtension
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
class SharedViewModel: ObservableObject {
    @Published var importedFiles: [ImportedFile] = []
    @Published var showFileImporter = false
    @Published var showActivateDialog = false
    @Published var isActivating = false
    @Published var activationToast: String?
    @Published var showIPSResult = false
    @Published var ipsSummary: String = ""
    @Published var pastedCode: String = ""
    
    @Published var activePreset: DNSPreset = .cloudflare
    @Published var isDNSActive = false
    @Published var showDNSStatus = false
    @Published var isCheckingDNS = false
    @Published var isOnDemandWiFiOnly = false
    
    @Published var benchmarkResults: [DNSPreset: Double] = [:]
    @Published var isBenchmarking = false
    @Published var connectionStatus: String = ""
    @Published var speedTestResult: String = ""
    
    @AppStorage("activationHistory") var historyData: Data = Data()
    var history: [HistoryItem] {
        get { (try? JSONDecoder().decode([HistoryItem].self, from: historyData)) ?? [] }
        set { if let encoded = try? JSONEncoder().encode(Array(newValue.prefix(20))) { historyData = encoded } }
    }
    
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func addFiles(urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let ext = url.pathExtension.lowercased()
            let type: ImportedFile.FileType = ext == "cfg" ? .cfg : (ext == "ips" ? .ips : .unknown)
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = attrs?[.size] as? Int64 ?? 0
            
            let fileDir = getDocumentsDirectory().appendingPathComponent("ImportedFiles", isDirectory: true)
            try? FileManager.default.createDirectory(at: fileDir, withIntermediateDirectories: true)
            let destURL = fileDir.appendingPathComponent(url.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: destURL.path) { try? FileManager.default.removeItem(at: destURL) }
            
            do {
                try FileManager.default.copyItem(at: url, to: destURL)
                importedFiles.append(ImportedFile(url: destURL, type: type, name: url.lastPathComponent, size: size))
            } catch { print("Error: \(error)") }
        }
    }
    
    func getDocumentsDirectory() -> URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    
    func deleteFile(at offsets: IndexSet) {
        for index in offsets { try? FileManager.default.removeItem(at: importedFiles[index].url) }
        importedFiles.remove(atOffsets: offsets)
        triggerHaptic(.light)
    }
    
    func activateFiles() async {
        isActivating = true
        var successCount = 0
        var failCount = 0
        var currentIPSSummary = ""
        
        for file in importedFiles {
            do {
                let data = try Data(contentsOf: file.url)
                if file.type == .cfg {
                    if let content = String(data: data, encoding: .utf8) {
                        parseConfig(content: content)
                        successCount += 1
                    } else { failCount += 1 }
                } else if file.type == .ips {
                    let summary = parseIPS(data: data)
                    currentIPSSummary += summary + "\n\n"
                    successCount += 1
                }
            } catch { failCount += 1 }
        }
        
        let code = pastedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty {
            if code.hasPrefix("{") {
                if let data = code.data(using: .utf8) {
                    let summary = parseIPS(data: data)
                    currentIPSSummary += "Mã dán (IPS):\n" + summary + "\n\n"
                    successCount += 1
                } else { failCount += 1 }
            } else {
                parseConfig(content: code)
                successCount += 1
            }
        }
        
        if !currentIPSSummary.isEmpty {
            ipsSummary = currentIPSSummary
            showIPSResult = true
        }
        
        activationToast = "Đã kích hoạt: \(successCount) thành công, \(failCount) thất bại"
        addHistory("Kích hoạt \(successCount) mục thành công")
        triggerHaptic(.success)
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isActivating = false
        activationToast = nil
    }
    
    private func parseConfig(content: String) {
        let lines = content.components(separatedBy: .newlines)
        var newPreset = DNSPreset(name: "Custom", dohURL: "", primaryIP: "", secondaryIP: "")
        var custom = false
        for line in lines {
            let parts = line.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if parts[0] == "doh_url" { newPreset = DNSPreset(name: newPreset.name, dohURL: parts[1], primaryIP: newPreset.primaryIP, secondaryIP: newPreset.secondaryIP); custom = true }
                if parts[0] == "dns_primary" { newPreset = DNSPreset(name: newPreset.name, dohURL: newPreset.dohURL, primaryIP: parts[1], secondaryIP: newPreset.secondaryIP); custom = true }
                if parts[0] == "dns_secondary" { newPreset = DNSPreset(name: newPreset.name, dohURL: newPreset.dohURL, primaryIP: newPreset.primaryIP, secondaryIP: parts[1]); custom = true }
                if parts[0] == "dot_host" { custom = true }
                if parts[0] == "adblock" && parts[1] == "true" { activePreset = .adguard; return }
            }
        }
        if custom { activePreset = newPreset }
    }
    
    private func parseIPS(data: Data) -> String {
        if let report = try? JSONDecoder().decode(IPSReport.self, from: data) {
            return "Crash Report:\n- Process: \(report.processName ?? "Unknown")\n- Time: \(report.timestamp ?? "Unknown")\n- Exception: \(report.exception?.type ?? "Unknown")\n- Crashed Thread: \(report.threads?.first(where: { $0.crashed == true })?.id ?? -1)"
        }
        return String(data: data, encoding: .utf8)?.prefix(200).appending("...") ?? "Không thể đọc file IPS"
    }
    
    func checkDNSStatus() {
        isCheckingDNS = true
        NEDNSSettingsManager.shared().loadFromPreferences { [weak self] error in
            DispatchQueue.main.async {
                self?.isCheckingDNS = false
                if error != nil { self?.isDNSActive = false; return }
                self?.isDNSActive = NEDNSSettingsManager.shared().isEnabled
                self?.showDNSStatus = true
            }
        }
    }
    
    func installDNS() {
        let manager = NEDNSSettingsManager.shared()
        manager.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if error != nil { self.fallbackToMobileConfig(); return }
            
            let settings = NEDNSOverHTTPSSettings(servers: [self.activePreset.primaryIP, self.activePreset.secondaryIP])
            settings.serverURL = URL(string: self.activePreset.dohURL)
            manager.dnsSettings = settings
            
            var rules: [NEOnDemandRule] = []
            if self.isOnDemandWiFiOnly {
                let wifiRule = NEOnDemandRuleConnect()
                wifiRule.interfaceMatch = .wiFi
                rules.append(wifiRule)
                let disconnectRule = NEOnDemandRuleDisconnect()
                disconnectRule.interfaceMatch = .cellular
                rules.append(disconnectRule)
            } else {
                rules.append(NEOnDemandRuleConnect())
            }
            manager.onDemandRules = rules
            manager.localizedDescription = "DNSOptimizer"
            manager.isEnabled = true
            
            manager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if saveError != nil {
                        self.fallbackToMobileConfig()
                    } else {
                        self.addHistory("Cài đặt cấu hình DNS (\(self.activePreset.name)) thành công")
                        self.checkDNSStatus()
                        self.triggerHaptic(.success)
                        self.openSettings()
                    }
                }
            }
        }
    }
    
    private func fallbackToMobileConfig() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>PayloadContent</key>
            <array>
                <dict>
                    <key>DNSSettings</key>
                    <dict>
                        <key>DNSProtocol</key>
                        <string>HTTPS</string>
                        <key>ServerAddresses</key>
                        <array>
                            <string>\(activePreset.primaryIP)</string>
                            <string>\(activePreset.secondaryIP)</string>
                        </array>
                        <key>ServerURL</key>
                        <string>\(activePreset.dohURL)</string>
                    </dict>
                    <key>PayloadDescription</key>
                    <string>Cấu hình DNS bằng DNSOptimizer</string>
                    <key>PayloadDisplayName</key>
                    <string>DNSOptimizer - \(activePreset.name)</string>
                    <key>PayloadIdentifier</key>
                    <string>com.example.dnsoptimizer.dns</string>
                    <key>PayloadType</key>
                    <string>com.apple.dnsSettings.managed</string>
                    <key>PayloadUUID</key>
                    <string>\(UUID().uuidString)</string>
                    <key>PayloadVersion</key>
                    <integer>1</integer>
                </dict>
            </array>
            <key>PayloadDisplayName</key>
            <string>DNSOptimizer Cấu hình</string>
            <key>PayloadIdentifier</key>
            <string>com.example.dnsoptimizer.profile</string>
            <key>PayloadType</key>
            <string>Configuration</string>
            <key>PayloadUUID</key>
            <string>\(UUID().uuidString)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
        </plist>
        """
        
        let url = getDocumentsDirectory().appendingPathComponent("DNSOptimizer.mobileconfig")
        do {
            try xml.write(to: url, atomically: true, encoding: .utf8)
            shareFile(url: url)
            addHistory("Tạo mobileconfig (\(activePreset.name))")
            triggerHaptic(.success)
        } catch { print("Lỗi tạo mobileconfig: \(error)") }
    }
    
    private func shareFile(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
    
    func benchmarkDNS() async {
        isBenchmarking = true
        var results: [DNSPreset: Double] = [:]
        for preset in DNSPreset.all {
            var totalTime = 0.0
            var successRuns = 0
            for _ in 0..<5 {
                guard let url = URL(string: "\(preset.dohURL)?dns=q80BAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/dns-message", forHTTPHeaderField: "Accept")
                let start = Date()
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        totalTime += Date().timeIntervalSince(start) * 1000
                        successRuns += 1
                    }
                } catch {}
            }
            results[preset] = successRuns > 0 ? totalTime / Double(successRuns) : 9999.0
        }
        benchmarkResults = results
        isBenchmarking = false
        triggerHaptic(.success)
    }
    
    func pickFastestDNS() {
        if let fastest = benchmarkResults.min(by: { $0.value < $1.value })?.key {
            activePreset = fastest
            addHistory("Tự động chọn DNS nhanh nhất: \(fastest.name)")
            triggerHaptic(.success)
        }
    }
    
    func testConnection() async {
        connectionStatus = "Đang kiểm tra..."
        let urls = ["https://apple.com", "https://google.com"]
        var avgLatency = 0.0
        var successes = 0
        for urlStr in urls {
            guard let url = URL(string: urlStr) else { continue }
            let start = Date()
            do {
                _ = try await URLSession.shared.data(from: url)
                avgLatency += Date().timeIntervalSince(start) * 1000
                successes += 1
            } catch {}
        }
        connectionStatus = successes > 0 ? String(format: "Kết nối ổn định. Trễ: %.0f ms", avgLatency / Double(successes)) : "Lỗi kết nối."
        triggerHaptic(.success)
    }
    
    func testNetworkSpeed() async {
        speedTestResult = "Đang đo..."
        guard let url = URL(string: "https://speed.hetzner.de/10MB.bin") else { return }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForResource = 5.0
        let session = URLSession(configuration: config)
        let start = Date()
        do {
            let (data, _) = try await session.data(from: url)
            let duration = Date().timeIntervalSince(start)
            let mbps = (Double(data.count) * 8 / 1_000_000) / duration
            speedTestResult = String(format: "Tốc độ tải: %.2f Mbps", mbps)
            triggerHaptic(.success)
        } catch {
            speedTestResult = "Đã quá thời gian đo 5 giây, vui lòng thử lại."
        }
    }
    
    func clearImportedFiles() {
        var sizeFreed: Int64 = 0
        for file in importedFiles {
            sizeFreed += file.size
            try? FileManager.default.removeItem(at: file.url)
        }
        importedFiles.removeAll()
        addHistory("Dọn dẹp cache: giải phóng \(sizeFreed / 1024) KB")
        triggerHaptic(.success)
    }
    
    func addHistory(_ msg: String) {
        var current = history
        current.insert(HistoryItem(date: Date(), message: msg), at: 0)
        history = current
    }
}
