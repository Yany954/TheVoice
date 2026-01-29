//
//  PremiumView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/29/26.
//

import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: PremiumPlan = .monthly
    
    var body: some View {
        ZStack {
            // Degradado premium
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),  // Morado muy oscuro
                    Color(hex: "0f0520"),  // Negro morado
                    Color(hex: "020209")   // Negro
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    
                    // Icono premium (usa SF Symbol o agrega tu propia imagen)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.3),
                                        Color.orange.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 30)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 20)
                    
                    // Título
                    VStack(spacing: 12) {
                        Text("Desbloquea Premium")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Únete y diviértete con tus amigos\nsin límites")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 30)
                    
                    // Beneficios
                    VStack(spacing: 16) {
                        PremiumFeature(
                            icon: "waveform.path.ecg",
                            title: "Efectos de voz ilimitados",
                            description: "Acceso a todos los efectos premium"
                        )
                        
                        PremiumFeature(
                            icon: "sparkles",
                            title: "Auto-Tune profesional",
                            description: "Suena como un artista profesional"
                        )
                        
                        PremiumFeature(
                            icon: "building.columns",
                            title: "Efectos de ambiente",
                            description: "Catedral, estadio y más"
                        )
                        
                        PremiumFeature(
                            icon: "speaker.wave.3.fill",
                            title: "Calidad de estudio",
                            description: "Audio profesional con EQ y compresión"
                        )
                        
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    // Selector de plan
                    VStack(spacing: 12) {
                        PremiumPlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly
                        ) {
                            selectedPlan = .monthly
                        }
                        
                        PremiumPlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly
                        ) {
                            selectedPlan = .yearly
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    // Botón de continuar
                    Button(action: handlePurchase) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                            Text("Continuar con el pago")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    // Nota legal
                    Text("Se renovará automáticamente. Cancela cuando quieras desde Ajustes.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func handlePurchase() {
        // Aquí irá la lógica de pago con StoreKit 2
        print("💳 Iniciando compra: \(selectedPlan.rawValue)")
        
        // Por ahora solo mostramos que se procesará
        // En producción: usar StoreKit 2 o RevenueCat
    }
}

// MARK: - Premium Plan
enum PremiumPlan: String {
    case monthly = "Mensual"
    case yearly = "Anual"
    
    var price: String {
        switch self {
        case .monthly: return "$4.99/mes"
        case .yearly: return "$39.99/año"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Ahorra 33%"
        }
    }
}

// MARK: - Premium Feature
struct PremiumFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Premium Plan Card
struct PremiumPlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.rawValue)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(plan.price)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .yellow : .gray)
            }
            .padding(20)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.yellow.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    PremiumView()
}
