import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: SharedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        Button {
                            vm.showFileImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Chọn files (.cfg, .ips)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        if !vm.importedFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Danh sách file")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                ForEach(vm.importedFiles) { file in
                                    fileCard(file)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Dán mã cấu hình / IPS trực tiếp:")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $vm.pastedCode)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 150)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        Button {
                            vm.showActivateDialog = true
                        } label: {
                            Text(vm.isActivating ? "Đang xử lý..." : "Activate")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background((vm.importedFiles.isEmpty && vm.pastedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? Color.gray : Color.green)
                                .cornerRadius(15)
                        }
                        .disabled((vm.importedFiles.isEmpty && vm.pastedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || vm.isActivating)
                        .padding(.horizontal)
                        
                        if let toast = vm.activationToast {
                            Text(toast)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(10)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Trang chủ")
            .fileImporter(isPresented: $vm.showFileImporter, allowedContentTypes: [.cfg, .ips], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    vm.addFiles(urls: urls)
                case .failure(let error):
                    print("Lỗi chọn file: \(error)")
                }
            }
            .alert("Xác nhận Activate", isPresented: $vm.showActivateDialog) {
                Button("Từ chối", role: .cancel) { }
                Button("Đồng ý") {
                    Task {
                        await vm.activateFiles()
                    }
                }
            } message: {
                Text("Bạn có chắc chắn muốn áp dụng cài đặt từ các file đã chọn?")
            }
            .sheet(isPresented: $vm.showIPSResult) {
                NavigationStack {
                    ScrollView {
                        Text(vm.ipsSummary)
                            .padding()
                            .font(.system(.body, design: .monospaced))
                    }
                    .navigationTitle("Kết quả IPS")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Đóng") { vm.showIPSResult = false }
                        }
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private func fileCard(_ file: ImportedFile) -> some View {
        HStack {
            Image(systemName: file.type == .cfg ? "gearshape.fill" : (file.type == .ips ? "ladybug.fill" : "doc.fill"))
                .foregroundColor(file.type == .cfg ? .cyan : .red)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(file.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("\(file.size / 1024) KB")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button {
                if let idx = vm.importedFiles.firstIndex(where: { $0.id == file.id }) {
                    vm.deleteFile(at: IndexSet(integer: idx))
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
