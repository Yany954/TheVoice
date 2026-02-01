//
//  CustomTextField.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/29/26.
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.horizontal, 16)
            }
            
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(.black)
                    .padding()
            } else {
                TextField("", text: $text)
                    .foregroundColor(.black)
                    .padding()
            }
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

