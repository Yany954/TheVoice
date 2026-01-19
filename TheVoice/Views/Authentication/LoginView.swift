//
//  LoginView.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import SwiftUI

struct LoginView: View {
    @State private var showRegister = false
    @State private var navigateToMain = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(
                    colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(alignment:.leading, spacing: 20){
                    HStack(spacing:10){
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30,height: 30)
                        Text("The Voice")
                            .font(.system(size: 18,weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top,50)
                    Spacer().frame(height: 40)
                    Text("Bienvenido")
                        .font(.system(size: 36,weight: .bold))
                        .foregroundColor(.white)
                    Text("Crea una cuenta o loguéate para utilizar la app")
                        .font(.system(size:16))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer().frame(height:20)
                    
                    //Tarjeta login
                    VStack(spacing:0){
                        //Selector de Login
                        HStack(spacing:0){
                            Button(action:{
                                showRegister=false
                            }){
                                Text("Log In")
                                    .font(.system(size: 16, weight: showRegister ? .regular : .bold))
                                    .foregroundColor(showRegister ? .gray : .black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical,16)
                            }
                            Divider()
                                .frame(height: 20)
                                .background(Color.gray.opacity(0.3))
                            
                            Button(action:{
                                showRegister=true
                            }){
                                Text("Registro")
                                    .font(.system(size:16 ,weight: showRegister ? .bold : .regular))
                                    .foregroundColor(showRegister ? .black : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical,16)
                            }
                        }
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        
                        //Contenido de la tarjeta
                        VStack(spacing:16){
                            if !showRegister{
                                SocialButton(
                                    title:"Continuar con Google",
                                    icon: "g.circle.fill",
                                    color: .black){
                                        navigateToMain = true
                                    }
                                SocialButton(
                                    title:"Continuar con Facebook",
                                    icon: "f.circle.fill",
                                    color: .blue){
                                        navigateToMain = true
                                    }
                                
                            }
                            else{
                                    Text("Formulario de registro próximamente")
                                        .foregroundColor(.gray)
                                        .padding(.vertical,30)
                                }
                        }.padding(24)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                    
                    Spacer()
                }
                .padding(.horizontal,30)
                
            }
            .navigationDestination(isPresented: $navigateToMain){
                MainView()
            }
        }
    }
}
#Preview{
    LoginView()
}
