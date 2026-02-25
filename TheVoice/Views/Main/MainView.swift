import SwiftUI

struct MainView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showAlert = false
    @State private var showSettings = false
    @State private var showEffects = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                LinearGradient(
                    colors: [
                        Color(hex: "271C67"),
                        Color(hex: "1a1544"),
                        Color(hex: "020209")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        
                        Button(action: {
                            if !audioManager.isTransmitting {
                                showEffects = true
                            }
                        }) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(audioManager.isTransmitting ? .gray : .white)
                                .frame(width: 44, height: 44)
                                .background(
                                    audioManager.isTransmitting
                                    ? Color.gray.opacity(0.3)
                                    : Color.white.opacity(0.15)
                                )
                                .clipShape(Circle())
                        }
                        .disabled(audioManager.isTransmitting)
                        
                        Spacer()
                        
                        Text("The voice")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Botón de perfil (reemplaza el menú)
                        // En MainView.swift, dentro del Header (HStack)
                        Button(action: {
                            showSettings = true // Cambia el nombre de la variable de estado
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "gearshape.fill") // Icono de engranaje
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Micrófono central con switch (MÁS GRANDE)
                    VStack(spacing: 20) {
                        ZStack {
                            // Glow effect cuando está activo
                            if audioManager.isTransmitting {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.green.opacity(0.5),
                                                Color.green.opacity(0.3),
                                                Color.green.opacity(0.1),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 80,
                                            endRadius: 200
                                        )
                                    )
                                    .frame(width: 400, height: 400)
                                    .scaleEffect(audioManager.isTransmitting ? 1.15 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                        value: audioManager.isTransmitting
                                    )
                            }
                            
                            // Imagen del micrófono (AÚN MÁS GRANDE)
                            Image("microphone_image") // Agrega tu imagen en Assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 350, height: 350) // Aumentado de 300 a 350
                                .shadow(
                                    color: audioManager.isTransmitting ? .green.opacity(0.6) : .black.opacity(0.4),
                                    radius: 40,
                                    y: 15
                                )
                            
                            // Switch/Botón circular sobre el micrófono (también más grande)
                            VStack {
                                Spacer()
                                Button(action: toggleMicrophone) {
                                    ZStack {
                                        // Fondo del botón
                                        Circle()
                                            .fill(
                                                audioManager.isTransmitting
                                                    ? Color.green
                                                    : Color.gray.opacity(0.6)
                                            )
                                            .frame(width: 95, height: 95) // Aumentado de 85 a 95
                                            .shadow(
                                                color: audioManager.isTransmitting ? .green.opacity(0.7) : .black.opacity(0.4),
                                                radius: 15,
                                                y: 8
                                            )
                                        
                                        // Icono
                                        Image(systemName: audioManager.isTransmitting ? "mic.fill" : "mic.slash.fill")
                                            .font(.system(size: 38))
                                            .foregroundColor(.white)
                                    }
                                }
                                .disabled(!audioManager.isBluetoothConnected && !audioManager.isTransmitting)
                                .scaleEffect(audioManager.isTransmitting ? 1.08 : 1.0)
                                .animation(.spring(response: 0.3), value: audioManager.isTransmitting)
                            }
                            .frame(width: 350, height: 350)
                            .padding(.top, 70)
                        }
                    }
                    
                    Spacer().frame(height: 50)
                    
                    HStack(spacing: 10) {
                        Circle()
                            .fill(audioManager.isBluetoothConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(audioManager.isBluetoothConnected ? "bluetooth_connected".localized : "bluetooth_disconnected".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(25)
                    
                    Spacer().frame(height: 30)
                    
                    // Texto de estado
                    Text(audioManager.isTransmitting ? "stop_microphone".localized : "activate_microphone".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if let errorMessage = audioManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEffects) {
                VoiceEffectsView()
            }
            .alert("bluetooth_required".localized, isPresented: $showAlert) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text("bluetooth_message".localized)
            }
            .onAppear {
                audioManager.checkBluetoothStatus()
            }
        }
    }
    
    // MARK: - Toggle Microphone
    private func toggleMicrophone() {
        if audioManager.isTransmitting {
            audioManager.stopMicrophone()
        } else {
            if audioManager.isBluetoothConnected {
                audioManager.startMicrophone()
            } else {
                showAlert = true
            }
        }
    }
}

// MARK: - Color Extension para usar HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MainView()
        .environmentObject(AudioManager())
        .environmentObject(AuthManager())
}
