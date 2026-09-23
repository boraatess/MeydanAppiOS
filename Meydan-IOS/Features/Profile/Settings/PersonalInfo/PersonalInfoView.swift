import SwiftUI
import PhotosUI

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PersonalInfoViewModel
    
    @State private var showImageOptions = false
    @State private var showGallery = false
    @State private var isEditing = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(user: UserProfile? = nil) {
        _viewModel = StateObject(wrappedValue: PersonalInfoViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Text("Kişisel Bilgiler")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        if isEditing {
                            Task {
                                await viewModel.updateProfile()
                                if viewModel.errorMessage == nil {
                                    withAnimation { isEditing = false }
                                }
                            }
                        } else {
                            withAnimation { isEditing = true }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isEditing ? Color.branding : Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Image
                        ZStack(alignment: .bottomTrailing) {
                            profileImageView
                            
                            // Edit photo icon
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(Color.background, lineWidth: 2))
                                
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showImageOptions.toggle()
                            }
                        }
                        .padding(.top, 10)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            InfoEditField(label: "Ad Soyad", value: $viewModel.name, isEditing: isEditing)
                            InfoEditField(label: "Kullanıcı Adı", value: $viewModel.username, isEditing: isEditing)
                            InfoEditField(label: "Biyografi", value: $viewModel.bio, isEditing: isEditing, isMultiline: true)
                            BirthDateField(
                                label: "Doğum Tarihi",
                                value: $viewModel.birthDate,
                                selectedDate: Binding(
                                    get: { viewModel.birthDatePickerValue },
                                    set: { viewModel.setBirthDate($0) }
                                ),
                                isEditing: isEditing
                            )

                            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.manrope(.medium, size: 14))
                                    .foregroundColor(.red.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 30)
                }
            }
            if showImageOptions {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showImageOptions = false
                        }
                    }

                VStack {
                    PhotoOptionsPopUp(
                        onSelectGallery: {
                            withAnimation(.easeInOut(duration: 0.2)) { showImageOptions = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showGallery = true
                            }
                        },
                        onSelectCamera: {
                            withAnimation(.easeInOut(duration: 0.2)) { showImageOptions = false }
                        },
                        onSelectRemove: {
                            withAnimation(.easeInOut(duration: 0.2)) { showImageOptions = false }
                            Task {
                                await viewModel.removeProfileImage()
                            }
                        }
                    )
                    .padding(.top, 205)
                    Spacer()
                }
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .photosPicker(isPresented: $showGallery, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }
            Task {
                await handleSelectedPhotoItem(newItem)
            }
        }
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let selectedImage = viewModel.selectedProfileImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        } else if let url = URL(string: viewModel.profileImageURL), !viewModel.profileImageURL.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }

    private func handleSelectedPhotoItem(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }

            await viewModel.uploadSelectedImage(image)
            selectedPhotoItem = nil
        } catch {
            print("Secilen fotograf okunurken hata: \(error.localizedDescription)")
        }
    }
    
    private struct InfoEditField: View {
        let label: String
        @Binding var value: String
        let isEditing: Bool
        var isMultiline: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.manrope(.bold, size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Group {
                    if isEditing {
                        if isMultiline {
                            TextEditor(text: $value)
                                .font(.manrope(.medium, size: 16))
                                .foregroundColor(.white)
                                .frame(minHeight: 100)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(16)
                        } else {
                            TextField("", text: $value)
                                .font(.manrope(.medium, size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                    } else {
                        Text(value)
                            .font(.manrope(.medium, size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: isMultiline ? 100 : 56, alignment: isMultiline ? .topLeading : .leading)
                            .padding(.vertical, isMultiline ? 16 : 0)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                }
            }
        }
    }

    private struct BirthDateField: View {
        let label: String
        @Binding var value: String
        @Binding var selectedDate: Date
        let isEditing: Bool
        private let minimumBirthDate = Calendar(identifier: .gregorian).date(byAdding: .year, value: -100, to: Date()) ?? .distantPast
        private let maximumBirthDate = Calendar(identifier: .gregorian).date(byAdding: .year, value: -15, to: Date()) ?? Date()

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.manrope(.bold, size: 14))
                    .foregroundColor(.white.opacity(0.6))

                if isEditing {
                    VStack(spacing: 12) {
                        HStack {
                            Text(value.isEmpty ? "Doğum tarihi seç" : value)
                                .font(.manrope(.medium, size: 16))
                                .foregroundColor(value.isEmpty ? .white.opacity(0.4) : .white)
                            Spacer()
                        }

                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: minimumBirthDate...maximumBirthDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(.branding)
                        .colorScheme(.dark)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                } else {
                    Text(value.isEmpty ? "-" : value)
                        .font(.manrope(.medium, size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 56, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
        }
    }
    
}


// MARK: - Photo Options Pop-up
private struct PhotoOptionsPopUp: View {
    let onSelectGallery: () -> Void
    let onSelectCamera: () -> Void
    let onSelectRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            OptionItem(title: "Kütüphaneden Seç", action: onSelectGallery)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            OptionItem(title: "Fotoğraf Çek", action: onSelectCamera)
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            OptionItem(title: "Mevcut Fotoğrafı Kaldır", action: onSelectRemove)
        }
        .frame(maxWidth: 310)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1B1B1B"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black, radius: 12, y: 8)
    }
    
    private func OptionItem(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }
    
}

// MARK: - Gallery Picker Placeholder
struct GalleryPickerView: View {
    @Binding var isPresented: Bool
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Kamera")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                }
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(0..<15) { i in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white.opacity(0.2))
                                )
                        }
                    }
                }
                
                Button {
                    isPresented = false
                } label: {
                    Text("Görseli Seç")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.branding)
                        .cornerRadius(12)
                        .padding(24)
                }
            }
        }
    }
}

#Preview {
    PersonalInfoView(user: .placeholder)
        .preferredColorScheme(.dark)
        .environmentObject(AuthenticationManager())
}

/*
 /*
  Color.black.opacity(0.6)
  .ignoresSafeArea()
  .onTapGesture {
      withAnimation(.easeInOut(duration: 0.2)) {
          showPhotoOptions = false
      }
  }

VStack(spacing: 14) {
  popupOption(title: "Galeriden Sec", systemImage: "photo.stack") {
      closePhotoOptions()
  }

  popupOption(title: "Stok Gorsel Sec", systemImage: "photo") {
      closePhotoOptions()
  }

  Button {
      closePhotoOptions()
  } label: {
      Text("Vazgec")
          .font(.manrope(.medium, size: 17))
          .foregroundColor(.white.opacity(0.9))
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(
              RoundedRectangle(cornerRadius: 18)
                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
          )
  }
  .buttonStyle(.plain)
}
.padding(14)
.background(
  RoundedRectangle(cornerRadius: 24)
      .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
      .overlay(
          RoundedRectangle(cornerRadius: 24)
              .stroke(Color.white.opacity(0.14), lineWidth: 1)
      )
)
.padding(.horizontal, 24)
.transition(.scale(scale: 0.96).combined(with: .opacity))
  
  */
 
 */
