//
//  TechLimitationsView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 2/25/26.
//
import SwiftUI
struct TechLimitationsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("¿Por qué ocurre el pitido?")
                    .font(.title2).bold().foregroundColor(.white)
                
                Text("Tu iPhone utiliza un micrófono **omnidireccional**. A diferencia de los micrófonos de escenario que solo captan lo que tienen enfrente, el iPhone está diseñado para captar sonidos de todas partes para que Siri o tus llamadas se escuchen bien en cualquier posición.")
                    .foregroundColor(.white.opacity(0.8))
                
                Divider().background(Color.white.opacity(0.2))
                
                Text("Física del Sonido")
                    .font(.headline).foregroundColor(.yellow)
                
                Text("Cuando el sonido sale por el altavoz y entra de nuevo por el micrófono en menos de milisegundos, se crea un bucle infinito llamado **Retroalimentación Acústica**. \n\nAunque nuestra app incluye un sistema profesional de filtrado (Notch Filters), la física no se puede engañar al 100% si el volumen es extremo.")
                    .foregroundColor(.white.opacity(0.8))
                
                // Espacio para una imagen generada por IA que podrías poner en Assets
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text("Imagen: Bucle de sonido")
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
            .padding()
        }
        .navigationTitle("Limitaciones")
        .background(Color(hex: "020209"))
    }
}
