//
//  RegisterView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Imagen de fondo opcional
            Image("login_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.4))
            
            ScrollView {
                VStack(spacing: 24) {
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
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 50)
                    
                    // Logo
                    HStack(spacing: 10) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("The voice")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Título
                    VStack(spacing: 8) {
                        Text("Crear cuenta")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Únete y empieza a divertirte")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 10)
                    
                    // Formulario
                    VStack(spacing: 16) {
                        // Nombre
                        CustomTextField(
                            placeholder: "Nombre completo",
                            text: $name,
                            icon: "person.fill"
                        )
                        
                        // Email
                        CustomTextField(
                            placeholder: "Correo electrónico",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        // Contraseña
                        CustomSecureField(
                            placeholder: "Contraseña",
                            text: $password,
                            showPassword: $showPassword,
                            icon: "lock.fill"
                        )
                        
                        // Confirmar contraseña
                        CustomSecureField(
                            placeholder: "Confirmar contraseña",
                            text: $confirmPassword,
                            showPassword: $showConfirmPassword,
                            icon: "lock.fill"
                        )
                        
                        // Mensaje de error
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Botón de registro
                        Button(action: register) {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Crear cuenta")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .disabled(authManager.isLoading)
                        .padding(.top, 8)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("o")
                                .foregroundColor(.gray)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 8)
                        
                        // Botones sociales
                        SocialButton(
                            title: "Continuar con Google",
                            icon: "g.circle.fill",
                            color: .black
                        ) {
                            authManager.signInWithGoogle()
                        }
                        
                        SocialButton(
                            title: "Continuar con Facebook",
                            icon: "f.circle.fill",
                            color: .blue
                        ) {
                            // Facebook login
                        }
                        
                        // Ya tienes cuenta
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Text("¿Ya tienes cuenta?")
                                    .foregroundColor(.gray)
                                Text("Inicia sesión")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 15))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func register() {
        authManager.registerWithEmail(
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager())
}
