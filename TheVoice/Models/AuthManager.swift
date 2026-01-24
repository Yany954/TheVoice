import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        self.user = auth.currentUser
        self.isAuthenticated = user != nil
        
        // Observar cambios en el estado de autenticación
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.user = user
                self.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Error de configuración"
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "No se pudo obtener el controlador"
            isLoading = false
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Error obteniendo token"
                self.isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            self.signInWithCredential(credential)
        }
    }
    
    // MARK: - Email/Password Register
    func registerWithEmail(email: String, password: String, confirmPassword: String) {
        isLoading = true
        errorMessage = nil
        
        // Validaciones
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor completa todos los campos"
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            isLoading = false
            return
        }
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            
            if let user = result?.user {
                self.createUserProfile(user: user)
            }
        }
    }
    
    // MARK: - Email/Password Login
    func signInWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor completa todos los campos"
            isLoading = false
            return
        }
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                self.user = result?.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign In with Credential
    private func signInWithCredential(_ credential: AuthCredential) {
        auth.signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            
            if let user = result?.user {
                self.createUserProfile(user: user)
            }
        }
    }
    
    // MARK: - Create User Profile in Firestore
    private func createUserProfile(user: User) {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "createdAt": Timestamp(date: Date()),
            "isPremium": false
        ]
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                } else {
                    self.user = user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                self.isLoading = false // ✅ Importante: detener loading
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() {
        guard let user = auth.currentUser else { return }
        
        isLoading = true
        
        // Primero eliminar datos de Firestore
        db.collection("users").document(user.uid).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error al eliminar datos: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // Luego eliminar cuenta de Authentication
            user.delete { error in
                if let error = error {
                    self.errorMessage = "Error al eliminar cuenta: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                // Cerrar sesión de Google también
                GIDSignIn.sharedInstance.signOut()
                
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                    self.isLoading = false
                }
            }
        }
    }
}
