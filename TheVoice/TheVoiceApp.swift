//
//  TheVoiceApp.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import SwiftUI

@main
struct TheVoiceApp: App {
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(audioManager)
        }
    }
}
