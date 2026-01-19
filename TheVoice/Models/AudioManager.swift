//
//  AudioManager.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import AVFoundation
import Combine

class AudioManager: ObservableObject{
    private var engine = AVAudioEngine()
    private var audioSession = AVAudioSession.sharedInstance()
    
    @Published var isBluetoothConnected: Bool = false
    @Published var isTransmitting: Bool = false
    @Published var errorMessage: String?
    
    init(){
        setupAudioSession()
        checkBluetoothStatus()
        setupNotifications()
    }
    
    //MARK - Configuracion de audioSession
    private func setupAudioSession(){
        do{
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetooth, .defaultToSpeaker]
            )
            try audioSession.setActive(true)
        } catch {
            print("Error configurando audio session: \(error)")
        }
    }
    
    //MARK - Notificaciones de cambio de ruta
    private func setupNotifications(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    @objc private func handleRouteChange (notification: Notification){
        checkBluetoothStatus()
    }
    
    //MARK - Verificar estado de Bluetooth
    func checkBluetoothStatus(){
        let currentRoute = audioSession.currentRoute
        
        //Verificar si hay salida Bluetooth activa
        let hasBluetoothOutput = currentRoute.outputs.contains{ output in
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE
        }
        DispatchQueue.main.async{
            self.isBluetoothConnected = hasBluetoothOutput
            
            //Si se desconecta Bluetooth, detener transmision
            if !hasBluetoothOutput && self.isTransmitting{
                self.stopMicrophone()
                self.errorMessage = "Bluetooth desconectado. Transmisión detenida."
            }
        }
    }
    
    //MARK - Iniciar microfono
    func startMicrophone(){
        //Solo funciona si el Bluetooth conectado
        guard isBluetoothConnected else {
            errorMessage = "No hay altavoz Bluetooth conectado. Conecta uno para continuar."
            return
        }
        guard !isTransmitting else { return }
        
        let inputNode = engine.inputNode
        let outputNode = engine.mainMixerNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Conectar entrada de micrófono directamente a la salida
        engine.connect(inputNode, to: outputNode, format: inputFormat)
                
        // Agregar tap para monitorear (opcional)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, time in
        // Aquí podrías agregar efectos, procesamiento, etc.
    }
        do {
            try engine.start()
            DispatchQueue.main.async {
                self.isTransmitting = true
                self.errorMessage = nil
            }
        }catch{
                DispatchQueue.main.async{
                    self.errorMessage = "Error al iniciar el micrófono: \(error.localizedDescription)"
                }
            }
        }
    // MARK: - Detener Micrófono
        func stopMicrophone() {
            guard isTransmitting else { return }
            
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
            
            DispatchQueue.main.async {
                self.isTransmitting = false
            }
        }
        
        // MARK: - Cleanup
        deinit {
            NotificationCenter.default.removeObserver(self)
            stopMicrophone()
        }
    
}
