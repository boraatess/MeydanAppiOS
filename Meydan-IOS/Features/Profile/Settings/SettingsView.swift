import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    let user: UserProfile
    
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
                    
                    Text("Ayarlar")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                // Menu Items
                VStack(spacing: 12) {
                    NavigationLink(value: ProfileNavigation.personalInfo(user: user)) {
                        SettingsItemLabel(title: "Kişisel Bilgiler")
                    }
                    
                    NavigationLink(value: ProfileNavigation.accountSettings(user: user)) {
                        SettingsItemLabel(title: "Hesap Bilgileri")
                    }
                    
                    NavigationLink(value: ProfileNavigation.blockedUsers) {
                        SettingsItemLabel(title: "Engellenenler")
                    }
                    
                    SettingsItemButton(title: "Güvenlik ve Gizlilik") {
                        // Action
                    }
                    
                    NavigationLink(value: ProfileNavigation.contactUs) {
                        SettingsItemLabel(title: "Bize Ulaşın")
                    }
                    
                    SettingsItemButton(title: "Çıkış Yap") {
                        authManager.logout()
                        
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                VStack(spacing: 24) {
                    // Social Icons
                    HStack(spacing: 32) {
                        SocialIcon(systemName: "instagram") // Instagram placeholder
                        SocialIcon(systemName: "sendmail") // Email icon
                        SocialIcon(systemName: "linkedin") // LinkedIn placeholder
                    }
                    
                    VStack(spacing: 8) {
                        Text("Meydan Teknoloji ve Yazılım A.Ş. Levent Plaza, Kat: 4, No: 12 Beşiktaş / İstanbul")
                            .font(.manrope(.medium, size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Sürüm: 02.001")
                            .font(.manrope(.medium, size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct SettingsItemLabel: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.manrope(.medium, size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
    }
}

private struct SettingsItemButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsItemLabel(title: title)
        }
    }
}

private struct SocialIcon: View {
    let systemName: String
    
    var body: some View {
        Image(systemName)
            .font(.system(size: 24))
            .foregroundColor(.white)
    }
}

#Preview {
    SettingsView(user: .placeholder)
        .preferredColorScheme(.dark)
        .environmentObject(AuthenticationManager())
}
