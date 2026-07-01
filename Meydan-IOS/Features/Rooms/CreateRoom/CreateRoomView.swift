import SwiftUI

struct CreateRoomView: View {
    let onBack: () -> Void

    @StateObject private var viewModel = CreateRoomViewModel()

    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var categoryText: String = ""
    
    // UI State
    @State private var showPhotoOptions = false
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showCategoryPicker = false

    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        photoSection
                        
                        // Inputs
                        VStack(spacing: 12) {
                            customTextField(placeholder: "Yayın Başlığı Yazınız", text: $title)
                            
                            customSelectField(placeholder: "Tarih-Saat Belirleyiniz", value: formattedDateTime) {
                                withAnimation { showDatePicker = true }
                            }
                            
                            customSelectField(placeholder: "Kategori Seçiniz", value: categoryText) {
                                withAnimation { showCategoryPicker = true }
                            }
                        }

                        Spacer().frame(height: 10)

                        Button {
                            Task {
                                let didCreate = await viewModel.createRoom(
                                    title: title,
                                    date: selectedDate,
                                    categoryName: categoryText,
                                    selectedImage: selectedImage
                                )

                                if didCreate {
                                    onBack()
                                }
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "#2C2C2C"))
                                    .cornerRadius(18)
                            } else {
                                Text("Yayını Planla")
                                    .font(.manrope(.bold, size: 18))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "#2C2C2C"))
                                    .cornerRadius(18)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading)

                        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.manrope(.medium, size: 14))
                                .foregroundColor(Color(hex: "#FF5C5C"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }

            // Overlays
            if showPhotoOptions {
                photoOptionsPopup
            }
            
            if showDatePicker {
                DatePickerPopup(selectedDate: $selectedDate) {
                    withAnimation {
                        showDatePicker = false
                        showTimePicker = true
                    }
                }
                .transition(.opacity)
            }
            
            if showTimePicker {
                TimePickerPopup(selectedDate: $selectedDate) {
                    withAnimation { showTimePicker = false }
                }
                .transition(.opacity)
            }
            if showCategoryPicker {
                CategoryPickerPopup(
                    hobbies: viewModel.hobbies,
                    selectedCategory: $categoryText,
                    onDismiss: { withAnimation { showCategoryPicker = false } }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.fetchHobbies()
        }
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: selectedDate)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "#1B1B1B"))
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)

            Text("Sohbet Odası Oluştur")
                .font(.manrope(.bold, size: 20))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private var photoSection: some View {
        Group {
            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1.6, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .cornerRadius(22)
                        .clipped()
                    
                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                    }
                }
            } else {
                Button {
                    withAnimation { showPhotoOptions = true }
                } label: {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                        Text("Fotoğraf Ekle")
                            .font(.manrope(.medium, size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(hex: "#1B1B1B"))
                    .cornerRadius(22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 32)
        
    }

    private func customTextField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundColor(.white.opacity(0.6))
            }
            TextField("", text: text)
                .foregroundColor(.white)
        }
        .font(.manrope(.medium, size: 16))
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(18)
    }

    private func customSelectField(placeholder: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(value.isEmpty ? placeholder : value)
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(value.isEmpty ? .white.opacity(0.6) : .white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color(hex: "#1B1B1B"))
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }

    private var photoOptionsPopup: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { withAnimation { showPhotoOptions = false } }
            
            VStack(spacing: 14) {
                popupOption(title: "Galeriden Seç", systemImage: "photo.stack") {
                    withAnimation {
                        showPhotoOptions = false
                        showImagePicker = true
                    }
                }
                popupOption(title: "Stok Görsel Seç", systemImage: "photo") {
                    // This could also open a custom stock picker or just the image picker
                    withAnimation {
                        showPhotoOptions = false
                        showImagePicker = true
                    }
                }
                Button {
                    withAnimation { showPhotoOptions = false }
                } label: {
                    Text("Vazgeç")
                        .font(.manrope(.medium, size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(hex: "#121212"))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .offset(y: -120)
        }
        
    }

    private func popupOption(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.manrope(.medium, size: 17))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(hex: "#2C2C2C"))
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CategoryPickerPopup
struct CategoryPickerPopup: View {
    let hobbies: [Hobby]
    @Binding var selectedCategory: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: 16) {
                Text("Kategori Seç")
                    .font(.manrope(.bold, size: 18))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                if hobbies.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.bottom, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(hobbies, id: \._id) { hobby in
                                Button {
                                    selectedCategory = hobby.name
                                    onDismiss()
                                } label: {
                                    Text(hobby.name)
                                        .font(.manrope(.medium, size: 16))
                                        .foregroundColor(selectedCategory == hobby.name ? Color(hex: "#FF5C5C") : .white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .frame(height: 50)
                                        .background(selectedCategory == hobby.name ? Color(hex: "#FF5C5C").opacity(0.15) : Color(hex: "#2C2C2C"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .frame(maxHeight: 300)
                }
            }
            .background(Color(hex: "#1B1B1B"))
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - DatePickerPopup
struct DatePickerPopup: View {
    @Binding var selectedDate: Date
    let onContinue: () -> Void
    
    @State private var currentMonth = Date()
    let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text(monthYearString(from: currentMonth))
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 20) {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left").foregroundColor(.red)
                        }
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right").foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 10)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                    let days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Ct", "Paz"]
                    ForEach(days, id: \.self) { day in
                        Text(day).font(.manrope(.medium, size: 12)).foregroundColor(.gray)
                    }
                    
                    let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
                    let firstWeekday = calendar.component(.weekday, from: startOfMonth(currentMonth)) - 2 // Adjust for Monday start
                    let offset = firstWeekday < 0 ? 6 : firstWeekday
                    
                    ForEach(0..<offset, id: \.self) { _ in
                        Text("").frame(width: 36, height: 36)
                    }
                    
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let isSelected = isSameDay(day: day)
                        Text("\(day)")
                            .font(.manrope(.medium, size: 16))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(isSelected ? Color.red.opacity(0.8) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectDay(day)
                                onContinue()
                            }
                    }
                }
            }
            .padding(24)
            .background(Color(hex: "#1B1B1B"))
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date).capitalized
    }
    
    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func isSameDay(day: Int) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        return components.year == currentComponents.year && components.month == currentComponents.month && components.day == day
    }
    
    private func selectDay(_ day: Int) {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        components.year = currentComponents.year
        components.month = currentComponents.month
        components.day = day
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
    }
}

// MARK: - TimePickerPopup
struct TimePickerPopup: View {
    @Binding var selectedDate: Date
    let onConfirm: () -> Void
    
    @State private var hour: Int
    @State private var minute: Int
    
    init(selectedDate: Binding<Date>, onConfirm: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onConfirm = onConfirm
        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedDate.wrappedValue)
        _hour = State(initialValue: components.hour ?? 0)
        _minute = State(initialValue: components.minute ?? 0)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(formattedDate)
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 0) {
                    Picker("Saat", selection: $hour) {
                        ForEach(0..<24) { h in
                            Text(String(format: "%02d", h)).tag(h)
                                .foregroundColor(.white)
                                .font(.manrope(.bold, size: 24))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                    
                    Text(":")
                        .font(.manrope(.bold, size: 24))
                        .foregroundColor(.white)
                    
                    Picker("Dakika", selection: $minute) {
                        ForEach(0..<60) { m in
                            Text(String(format: "%02d", m)).tag(m)
                                .foregroundColor(.white)
                                .font(.manrope(.bold, size: 24))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                }
                .frame(height: 150)
                .background(Color(hex: "#2C2C2C"))
                .cornerRadius(18)
                
                Button(action: confirmTime) {
                    Text("Saati Onayla")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#FF5C5C"))
                        .cornerRadius(18)
                }
            }
            .padding(24)
            .background(Color(hex: "#1B1B1B"))
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: selectedDate)
    }
    
    private func confirmTime() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = hour
        components.minute = minute
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        }
        onConfirm()
    }
}

// MARK: - Helper Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - ImagePicker
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    let uiImage = object as? UIImage
                    DispatchQueue.main.async {
                        self.parent.image = uiImage
                    }
                }
            }
        }
    }
}

#Preview {
    CreateRoomView(onBack: {})
}
