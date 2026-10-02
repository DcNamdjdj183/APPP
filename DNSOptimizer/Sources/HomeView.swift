import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Import Button
                        Button {
                            vm.triggerHaptic(.light)
                            vm.showFileImporter = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 40, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.cyan)
                                
                                Text("Nhập file cấu hình (.cfg, .ips)")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        // Pasted Code Area
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.gray)
                                Text("Hoặc dán mã trực tiếp")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundColor(.gray)
                            }
                            
                            TextEditor(text: $vm.pastedCode)
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(height: 120)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        // File List
                        if !vm.importedFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Danh sách file đã chọn")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                
                                ForEach(vm.importedFiles) { file in
                                    fileCard(file)
                                }
                            }
                        }
                        
                        // Activate Button
                        let canActivate = !vm.importedFiles.isEmpty || !vm.pastedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        Button {
                            vm.triggerHaptic(.medium)
                            vm.showActivateDialog = true
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text(vm.isActivating ? "Đang xử lý..." : "Kích hoạt ngay")
                            }
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canActivate ?
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(Capsule())
                            .shadow(color: canActivate ? .cyan.opacity(0.5) : .clear, radius: 15, x: 0, y: 8)
                        }
                        .disabled(!canActivate || vm.isActivating)
                        .padding(.top, 10)
                        
                        if let toast = vm.activationToast {
                            Text(toast)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.green.opacity(0.8)))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tổng quan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fileImporter(isPresented: $vm.showFileImporter, allowedContentTypes: [.cfg, .ips], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): vm.addFiles(urls: urls)
                case .failure(let error): print("Lỗi chọn file: \(error)")
                }
            }
            .alert("Xác nhận", isPresented: $vm.showActivateDialog) {
                Button("Huỷ", role: .cancel) { }
                Button("Áp dụng") { Task { await vm.activateFiles() } }
            } message: { Text("Tiến hành đọc và áp dụng cấu hình DNS / phân tích IPS?") }
            .sheet(isPresented: $vm.showIPSResult) {
                NavigationStack {
                    ScrollView {
                        Text(vm.ipsSummary)
                            .padding()
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(white: 0.1).ignoresSafeArea())
                    .navigationTitle("Kết quả phân tích")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Đóng") { vm.showIPSResult = false }
                        }
                    }
                    .preferredColorScheme(.dark)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.0, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private func fileCard(_ file: ImportedFile) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(file.type == .cfg ? Color.cyan.opacity(0.2) : Color.pink.opacity(0.2))
                    .frame(width: 46, height: 46)
                Image(systemName: file.type == .cfg ? "slider.horizontal.3" : (file.type == .ips ? "ladybug.fill" : "doc.fill"))
                    .foregroundColor(file.type == .cfg ? .cyan : .pink)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(.callout, design: .rounded).weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(file.size / 1024) KB")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
            Spacer()
            Button {
                if let idx = vm.importedFiles.firstIndex(where: { $0.id == file.id }) {
                    withAnimation(.spring()) {
                        vm.deleteFile(at: IndexSet(integer: idx))
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
