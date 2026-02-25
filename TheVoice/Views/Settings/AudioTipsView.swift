//
//  AudioTipsView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 2/25/26.
//
import SwiftUI
struct AudioTipsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                TipCard(
                    title: "Distancia de Seguridad",
                    description: "Mantente al menos a 2 metros del altavoz. Cuanto más cerca estés, más fácil será que el sonido 'entre' de nuevo al micro.",
                    icon: "arrow.left.and.right.square.fill",
                    color: .blue
                )
                
                TipCard(
                    title: "Orientación del Teléfono",
                    description: "Apunta la parte inferior del iPhone (donde está el micro) lejos del altavoz Bluetooth.",
                    icon: "phone.arrow.up.right.fill",
                    color: .green
                )
                
                TipCard(
                    title: "Usa Auriculares",
                    description: "La mejor forma de evitar el feedback es usar auriculares mientras hablas. Esto aísla el micro del sonido de salida.",
                    icon: "headphones",
                    color: .purple
                )
                
                TipCard(
                    title: "Volumen Moderado",
                    description: "Si subes el volumen al 100%, el micro captará el sonido del ambiente incluso si estás lejos.",
                    icon: "speaker.wave.2.bubble.left.fill",
                    color: .orange
                )
            }
            .padding()
        }
        .navigationTitle("Tips Anti-Feedback")
        .background(Color(hex: "020209"))
    }
}

struct TipCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}
