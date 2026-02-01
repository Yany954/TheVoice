import SwiftUI

struct VoiceEffectsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: EffectCategory = .basic
    @State private var showPremium = false
    
    
    var body: some View {
        ZStack {
            // Degradado de fondo
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Efectos de Voz")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(audioManager.currentEffect.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // Categorías tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(EffectCategory.allCases, id: \.self) { category in
                            CategoryTab(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
                
                // Lista de efectos
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredEffects) { effect in
                            EffectCard(
                                effect: effect,
                                isSelected: audioManager.currentEffect == effect
                            ) {
                                /*if effect.isPremium {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    showPremium = true
                                } else {
                                    audioManager.applyEffect(effect)
                                }*/
                                audioManager.applyEffect(effect)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: .constant(audioManager.errorMessage != nil && audioManager.errorMessage?.contains("Detén el micrófono") == true)) {
            Button("OK", role: .cancel) {
                audioManager.errorMessage = nil
            }
        } message: {
            if let error = audioManager.errorMessage {
                Text(error)
            }
        }
    }
    
    
    var filteredEffects: [VoiceEffect] {
        VoiceEffect.allCases.filter { $0.category == selectedCategory }
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: EffectCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                isSelected
                ? LinearGradient(
                    colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(
                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Effect Card
struct EffectCard: View {
    let effect: VoiceEffect
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icono
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: effect.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Información
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(effect.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if effect.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                Text("Premium")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        }
                    }
                    
                    Text(effect.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.green.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    VoiceEffectsView()
        .environmentObject(AudioManager())
}
