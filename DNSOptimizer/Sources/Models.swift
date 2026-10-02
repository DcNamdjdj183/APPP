import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var cfg: UTType { UTType(exportedAs: "com.example.dnsoptimizer.cfg") }
    static var ips: UTType { UTType(exportedAs: "com.example.dnsoptimizer.ips") }
}

struct DNSPreset: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let dohURL: String
    let primaryIP: String
    let secondaryIP: String
    
    init(id: UUID = UUID(), name: String, dohURL: String, primaryIP: String, secondaryIP: String) {
        self.id = id
        self.name = name
        self.dohURL = dohURL
        self.primaryIP = primaryIP
        self.secondaryIP = secondaryIP
    }
    
    static let cloudflare = DNSPreset(name: "Cloudflare", dohURL: "https://cloudflare-dns.com/dns-query", primaryIP: "1.1.1.1", secondaryIP: "1.0.0.1")
    static let google = DNSPreset(name: "Google", dohURL: "https://dns.google/dns-query", primaryIP: "8.8.8.8", secondaryIP: "8.8.4.4")
    static let adguard = DNSPreset(name: "AdGuard", dohURL: "https://dns.adguard-dns.com/dns-query", primaryIP: "94.140.14.14", secondaryIP: "94.140.15.15")
    static let quad9 = DNSPreset(name: "Quad9", dohURL: "https://dns.quad9.net/dns-query", primaryIP: "9.9.9.9", secondaryIP: "149.112.112.112")
    
    static let all: [DNSPreset] = [.cloudflare, .google, .adguard, .quad9]
}

struct ImportedFile: Identifiable {
    let id = UUID()
    let url: URL
    let type: FileType
    let name: String
    let size: Int64
    
    enum FileType {
        case ips, cfg, unknown
    }
}

struct IPSReport: Codable {
    let processName: String?
    let exception: ExceptionInfo?
    let timestamp: String?
    let threads: [ThreadInfo]?
    
    struct ExceptionInfo: Codable {
        let type: String?
        let subtype: String?
    }
    
    struct ThreadInfo: Codable {
        let id: Int?
        let name: String?
        let crashed: Bool?
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let message: String
    
    init(id: UUID = UUID(), date: Date = Date(), message: String) {
        self.id = id
        self.date = date
        self.message = message
    }
}
