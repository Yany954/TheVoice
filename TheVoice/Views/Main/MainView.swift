//
//  MainView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//
import SwiftUI

struct MainView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            // Fondo degradado similar al mockup
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.1, blue: 0.3),
                    Color(red: 0.25, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: {
                        // Acción para regresar
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("The voice")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Botón de configuración
                    }) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 50)
                
                Spacer()
                
                // Micrófono central
                VStack(spacing: 30) {
                    ZStack {
                        // Círculo animado cuando está transmitiendo
                        if audioManager.isTransmitting {
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 3)
                                .frame(width: 280, height: 280)
                                .scaleEffect(audioManager.isTransmitting ? 1.1 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true),
                                    value: audioManager.isTransmitting
                                )
                        }
                        
                        // Imagen del micrófono
                        Image("logo") // O usa una imagen de micrófono
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    }
                    
                    // Estado del Bluetooth
                    HStack(spacing: 8) {
                        Circle()
                            .fill(audioManager.isBluetoothConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(audioManager.isBluetoothConnected ? "Bluetooth conectado" : "Bluetooth desconectado")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    
                    // Botón de activar/desactivar micrófono
                    Button(action: {
                        if audioManager.isTransmitting {
                            audioManager.stopMicrophone()
                        } else {
                            if audioManager.isBluetoothConnected {
                                audioManager.startMicrophone()
                            } else {
                                showAlert = true
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: audioManager.isTransmitting ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 20))
                            
                            Text(audioManager.isTransmitting ? "Detener" : "Activar Micrófono")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 250, height: 56)
                        .background(
                            audioManager.isTransmitting
                                ? Color.red
                                : (audioManager.isBluetoothConnected ? Color.green : Color.gray)
                        )
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .disabled(!audioManager.isBluetoothConnected && !audioManager.isTransmitting)
                }
                
                Spacer()
                
                // Mensaje de error si existe
                if let errorMessage = audioManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Bluetooth Requerido", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Por favor conecta un altavoz Bluetooth para usar el micrófono.")
        }
        .onAppear {
            audioManager.checkBluetoothStatus()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AudioManager())
}
