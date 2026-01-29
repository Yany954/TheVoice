import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showRegister = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                        
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                .ignoresSafeArea()
                
                Image("login_background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.4)) // Overlay oscuro
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header con logo
                    HStack(spacing: 10) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("The voice")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 50)
                    
                    Spacer().frame(height: 40)
                    
                    // Título
                    Text("welcome".localized)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("welcome_subtitle".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer().frame(height: 20)
                    
                    // Tarjeta blanca
                    VStack(spacing: 0) {
                        // Selector Log In / Registro
                        HStack(spacing: 0) {
                            Button(action: { showRegister = false }) {
                                Text("login_tab".localized)
                                    .font(.system(size: 16, weight: showRegister ? .regular : .bold))
                                    .foregroundColor(showRegister ? .gray : .black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            
                            Divider()
                                .frame(height: 20)
                                .background(Color.gray.opacity(0.3))
                            
                            Button(action: { showRegister = true }) {
                                Text("register_tab".localized)
                                    .font(.system(size: 16, weight: showRegister ? .bold : .regular))
                                    .foregroundColor(showRegister ? .black : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.2))
                        
                        // Contenido
                        VStack(spacing: 16) {
                            if !showRegister {
                                // Login con redes sociales
                                SocialButton(
                                    title: "continue_google".localized,
                                    icon: "g.circle.fill",
                                    color: .black
                                ) {
                                    authManager.signInWithGoogle()
                                }
                                
                                SocialButton(
                                    title: "continue_facebook".localized,
                                    icon: "f.circle.fill",
                                    color: .blue
                                ) {
                                    // Facebook login (implementar después)
                                }
                            } else {
                                // Formulario de registro
                                RegisterForm(
                                    email: $email,
                                    password: $password,
                                    confirmPassword: $confirmPassword,
                                    onRegister: {
                                        authManager.registerWithEmail(
                                            email: email,
                                            password: password,
                                            confirmPassword: confirmPassword
                                        )
                                    }
                                )
                            }
                            
                            // Mensaje de error
                            if let error = authManager.errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(24)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                
                // Loading indicator
                if authManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationDestination(isPresented: $authManager.isAuthenticated) {
                MainView()
            }
        }
    }
}

// MARK: - Register Form Component
struct RegisterForm: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    var onRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("register_title".localized)
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 8)
            
            // Email field
            TextField("email_placeholder".localized, text: $email)
                .textFieldStyle(RoundedTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            // Password field
            SecureField("password_placeholder".localized, text: $password)
                .textFieldStyle(RoundedTextFieldStyle())
            
            // Confirm password field
            SecureField("confirm_password_placeholder".localized, text: $confirmPassword)
                .textFieldStyle(RoundedTextFieldStyle())
            
            // Register button
            Button(action: onRegister) {
                Text("register_button".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Custom TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
