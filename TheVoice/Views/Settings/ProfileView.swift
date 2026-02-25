import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showSignOutAlert = false
    @State private var showPremium = false
    
    var body: some View {
        ZStack {
            // Degradado de fondo
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.10, blue: 0.25),
                    Color(red: 0.25, green: 0.15, blue: 0.35),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Perfil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Espacio para mantener centrado el título
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Avatar y nombre de usuario
                        VStack(spacing: 16) {
                            // Avatar circular
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.purple.opacity(0.6),
                                                Color.blue.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                if let firstLetter = authManager.user?.displayName?.first ?? authManager.user?.email?.first {
                                    Text(String(firstLetter).uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                }
                            }
                            .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)
                            
                            // Nombre de usuario
                            Text(authManager.user?.displayName ?? "Usuario")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Email
                            Text(authManager.user?.email ?? "")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 30)
                        
                        // Información de cuenta
                        VStack(spacing: 16) {
                            // Botón Premium destacado
                            Button(action: { showPremium = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Hazte Premium")
                                            .font(.system(size: 16, weight: .bold))
                                        Text("Desbloquea todos los efectos")
                                            .font(.system(size: 13))
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .yellow.opacity(0.3), radius: 10, y: 5)
                            }
                            
                            ProfileInfoCard(
                                icon: "envelope.fill",
                                title: "Email",
                                value: authManager.user?.email ?? "No disponible"
                            )
                            
                            ProfileInfoCard(
                                icon: "calendar",
                                title: "Miembro desde",
                                value: formatDate(authManager.user?.metadata.creationDate)
                            )
                            
                            ProfileInfoCard(
                                icon: "crown.fill",
                                title: "Plan",
                                value: "Gratis" // Cambiar cuando implementes premium
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Botones de acción
                        VStack(spacing: 16) {
                            // Botón de cerrar sesión
                            Button(action: { showSignOutAlert = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                    Text("Cerrar Sesión")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                            }
                            
                            // Botón de eliminar cuenta
                            Button(action: { showDeleteAlert = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18))
                                    Text("Eliminar Cuenta")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.red.opacity(0.6))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        .alert("Cerrar Sesión", isPresented: $showSignOutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                dismiss()
                authManager.signOut()
            }
        } message: {
            Text("¿Estás seguro que deseas cerrar sesión?")
        }
        .alert("Eliminar Cuenta", isPresented: $showDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                dismiss()
                authManager.deleteAccount()
            }
        } message: {
            Text("Esta acción es permanente y no se puede deshacer. Se eliminarán todos tus datos.")
        }
    }
    
    // MARK: - Format Date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No disponible" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - Profile Info Card Component
struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icono
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
