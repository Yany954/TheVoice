//
//  SettingsView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 2/25/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo consistente con la app
                LinearGradient(
                    colors: [Color(hex: "1a1544"), Color(hex: "020209")],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink(destination: ProfileView()) {
                            Label("Mi Perfil", systemImage: "person.circle.fill")
                        }
                    } header: { Text("Cuenta") }
                    
                    Section {
                        NavigationLink(destination: AudioTipsView()) {
                            Label("Tips Anti-Acople", systemImage: "lightbulb.fill")
                        }
                        NavigationLink(destination: TechLimitationsView()) {
                            Label("Limitaciones Técnicas", systemImage: "exclamationmark.triangle.fill")
                        }
                    } header: { Text("Ayuda y Guía") }
                    
                    Section {
                        Link(destination: URL(string: "https://tupaginaweb.com")!) {
                            Label("Sitio Web", systemImage: "globe")
                        }
                        Button(action: {
                            let email = "soporte@thevoiceapp.com"
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Contactar Soporte", systemImage: "envelope.fill")
                        }
                    } header: { Text("Contacto") }
                }
                .scrollContentBackground(.hidden) // Para que se vea el degradado
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
