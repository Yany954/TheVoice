//
//  TheVoiceApp.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import SwiftUI
import FirebaseCore

@main
struct TheVoiceApp: App {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    init(){
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView2()
                .environmentObject(audioManager)
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
        }
    }
}
struct ContentView2: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}
