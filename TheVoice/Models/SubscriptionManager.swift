//
//  SubscriptionManager.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/29/26.
//

import Foundation

final class SubscriptionManager: ObservableObject {
    @Published private var isPremium: Bool = false

    func unlockPremium() {
        isPremium = true
    }

    func revokePremium() {
        isPremium = false
    }
}

