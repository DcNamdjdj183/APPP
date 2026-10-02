# DNSOptimizer

DNSOptimizer là ứng dụng iOS (SwiftUI, iOS 16+) giúp tối ưu cấu hình DNS, chặn quảng cáo và đo đạc kết nối mạng.

## Tính năng
- Parse và áp dụng file `.cfg` để cấu hình DNS.
- Phân tích cơ bản file crash `.ips` của iOS.
- Cài đặt DNS DoH bằng NetworkExtension (`NEDNSSettingsManager`).
- Hỗ trợ On-Demand rules (Chỉ dùng trên Wi-Fi).
- Benchmark DNS, Ping test, Speed test.

## Build tự động (GitHub Actions)
Project này đã được cấu hình với GitHub Actions để tự động build ra file `.ipa` **UNSIGNED** mỗi khi có thay đổi trên branch `main`.

1. Push code lên GitHub.
2. Vào tab **Actions**, chọn workflow "Build Unsigned IPA".
3. Tải artifact `DNSOptimizer-IPA` về máy.
4. Giải nén file `.zip` sẽ thu được file `DNSOptimizer.ipa`.

## Hướng dẫn Sideload (Cài đặt lên iPhone)
Vì app sử dụng `.ipa` unsigned, bạn cần tự ký ứng dụng bằng Apple ID của mình.

### Cách 1: Sử dụng AltStore hoặc Sideloadly
1. Cài đặt AltStore / Sideloadly lên máy tính (Windows/Mac).
2. Kết nối iPhone với máy tính bằng cáp.
3. Kéo thả file `DNSOptimizer.ipa` vào AltStore/Sideloadly và nhập Apple ID để ký.
4. Trên iPhone, vào **Cài đặt > Cài đặt chung > VPN & Quản lý thiết bị**, chọn tin cậy chứng chỉ nhà phát triển của bạn.
5. Mở ứng dụng DNSOptimizer.

### Cách 2: Sử dụng TrollStore (Dành cho máy đã jailbreak hoặc firmware tương thích)
1. Cài đặt TrollStore trên thiết bị của bạn.
2. Tải trực tiếp file `.ipa` bằng Safari trên điện thoại.
3. Mở file `.ipa` bằng TrollStore để cài đặt vĩnh viễn (không cần gia hạn sau 7 ngày).

## Lưu ý quan trọng về Entitlement
Để chức năng cài đặt DNS hoạt động trực tiếp qua `NEDNSSettingsManager`, ứng dụng cần có entitlement `com.apple.developer.networking.networkextension = [dns-settings]`.
Entitlement này yêu cầu tải khoản Apple Developer Program (trả phí 99$/năm) và cần được tick trên trang Apple Developer.

Nếu bạn cài đặt bằng Apple ID miễn phí (Free Developer Account), chứng chỉ ký sẽ **không có entitlement này**. Ứng dụng sẽ tự động chuyển sang cơ chế **fallback**:
- Ứng dụng sẽ tạo ra một file **MobileConfig Profile** (cấu hình).
- Một bảng chia sẻ (ShareSheet) sẽ hiện lên, hãy chọn **Lưu vào Tệp**.
- Mở ứng dụng Tệp, chọn file cấu hình vừa lưu để cài đặt.
- Sau đó vào **Cài đặt > Cài đặt chung > VPN & Quản lý thiết bị** để cài đặt Profile DNS.
