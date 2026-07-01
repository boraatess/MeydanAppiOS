import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let user: UserProfile
    
    @State private var email: String
    @State private var password = "************"
    
    init(user: UserProfile) {
        self.user = user
        self._email = State(initialValue: user.email)
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
                    
                    Text("Hesap Bilgileri")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                Spacer()
                
                
                VStack(spacing: 24) {
                    // Fields
                    VStack(alignment: .leading, spacing: 12) {
                        Text("E-Posta")
                            .font(.manrope(.bold, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        NavigationLink(value: ProfileNavigation.emailUpdate) {
                            AccountField(value: email) {
                                // Action is now handled by NavigationLink
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Şifre")
                            .font(.manrope(.bold, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        NavigationLink(value: ProfileNavigation.passwordRenewal) {
                            AccountField(value: password) { }
                                .disabled(true) // Click handled by NavigationLink
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    NavigationLink(value: ProfileNavigation.deactivateAccount) {
                        Text("Hesabı Devre Dışı Bırak")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(value: ProfileNavigation.deleteAccount) {
                        Text("Hesabı Sil")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct AccountField: View {
    let value: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(value)
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "pencil")
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView(user: .placeholder)
            .preferredColorScheme(.dark)
            .environmentObject(AuthenticationManager())
    }
}
