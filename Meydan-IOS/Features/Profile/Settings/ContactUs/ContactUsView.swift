import SwiftUI

struct ContactUsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ContactUsViewModel()
    @State private var showAttachmentOptions = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showDropdown = false
    
    let topics = ["Teknik Sorun", "Şikayet", "Öneri / Geri Bildirim"]
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if viewModel.isSubmitted {
                SuccessView(onDismiss: { dismiss() })
            } else {
                VStack(spacing: 0) {
                    // Header
                    ContactHeader(title: "Bize Ulaşın", onBack: { dismiss() })
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Topic Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Konu nedir?")
                                    .font(.manrope(.bold, size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button {
                                    withAnimation { showDropdown.toggle() }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedTopic)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white)
                                            .rotationEffect(.degrees(showDropdown ? 180 : 0))
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                
                                if showDropdown {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(topics, id: \.self) { topic in
                                            Button {
                                                viewModel.selectedTopic = topic
                                                withAnimation { showDropdown = false }
                                            } label: {
                                                Text(topic)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding()
                                            }
                                            if topic != topics.last {
                                                Divider().background(Color.white.opacity(0.1))
                                            }
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Yaşadığınız sorun nedir?")
                                    .font(.manrope(.bold, size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextEditor(text: $viewModel.message)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(height: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Attachment
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sorunun ekran görüntülerini yükler misiniz?")
                                    .font(.manrope(.bold, size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button {
                                    showAttachmentOptions = true
                                } label: {
                                    Group {
                                        if let image = viewModel.selectedImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 140)
                                                .clipped()
                                        } else {
                                            VStack(spacing: 12) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white)
                                                Text("Fotoğraf Ekle")
                                                    .font(.manrope(.bold, size: 14))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 140)
                                            .background(Color.white.opacity(0.05))
                                        }
                                    }
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.manrope(.medium, size: 14))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                    
                    // Submit Button
                    Button {
                        Task {
                            await viewModel.submitSupport()
                        }
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Gönder")
                                    .font(.manrope(.bold, size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.message.isEmpty || viewModel.isLoading ? Color.branding.opacity(0.5) : Color.branding)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.message.isEmpty || viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Fotoğraf Ekle", isPresented: $showAttachmentOptions, titleVisibility: .visible) {
            Button("Kamera") {
                imagePickerSource = .camera
                showImagePicker = true
            }
            Button("Galeri") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            Button("İptal", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            UnifiedImagePicker(image: $viewModel.selectedImage, sourceType: imagePickerSource)
        }
    }
}

private struct ContactHeader: View {
    let title: String
    let onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            Text(title)
                .font(.manrope(.bold, size: 20))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

private struct SuccessView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Mesajın başarı ile iletildi.")
                .font(.manrope(.bold, size: 24))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onDismiss()
            }
        }
    }
}

#Preview {
    ContactUsView()
        .preferredColorScheme(.dark)
}
