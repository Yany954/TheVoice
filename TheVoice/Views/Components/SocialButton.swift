//
//  SocialButton.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import SwiftUI

struct SocialButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action:action){
            HStack(spacing: 12){
                Image(systemName:icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 15,weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3),lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
}
