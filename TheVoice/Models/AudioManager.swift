import Foundation
import AVFoundation
import UIKit

final class AudioManager: ObservableObject {

    // MARK: - UI State
    @Published private(set) var isTransmitting = false
    @Published private(set) var isBluetoothConnected = false
    @Published private(set) var isInterrupted = false
    @Published private(set) var micLevel: Float = 0.0

    @Published var currentEffect: VoiceEffect = .none
    @Published var errorMessage: String?

    // MARK: - Audio Core
    private let audioSession = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    
    // Player node para reproducir el audio capturado
    private let playerNode = AVAudioPlayerNode()
    
    // Audio Units para efectos
    private var varispeed: AVAudioUnitVarispeed?
    private var reverb: AVAudioUnitReverb?
    private var distortion: AVAudioUnitDistortion?
    private var delay: AVAudioUnitDelay?
    private var eq: AVAudioUnitEQ?

    // MARK: - Init
    init() {
        configureNotifications()
        checkBluetoothStatus()
    }

    deinit {
        stopMicrophone()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API
    func startMicrophone() {
        guard !isTransmitting else { return }
        guard !isInterrupted else { return }

        do {
            try configureSession()
            try startEngine()

            isTransmitting = true
            errorMessage = nil
            
            print("🎤 Micrófono iniciado con efecto: \(currentEffect.rawValue)")
            
        } catch {
            errorMessage = error.localizedDescription
            stopMicrophone()
            print("❌ Error al iniciar: \(error)")
        }
    }

    func stopMicrophone() {
        playerNode.stop()
        engine.stop()
        engine.reset()
        
        cleanupEffectNodes()

        isTransmitting = false
        micLevel = 0
    }

    func applyEffect(_ effect: VoiceEffect) {
        guard !isTransmitting else {
            errorMessage = "Detén el micrófono antes de cambiar el efecto"
            print(" Intento de cambiar efecto con mic activo")
            return
        }
        
        currentEffect = effect
        errorMessage = nil
        print(" Efecto aplicado: \(effect.rawValue)")
    }

    func checkBluetoothStatus() {
        isBluetoothConnected = audioSession.currentRoute.outputs.contains {
            $0.portType == .bluetoothA2DP ||
            $0.portType == .bluetoothLE ||
            $0.portType == .bluetoothHFP
        }
    }

    // MARK: - Audio Setup
    private func configureSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers]
        )
        try audioSession.setActive(true)
    }

    private func startEngine() throws {
        engine.stop()
        engine.reset()
        cleanupEffectNodes()

        inputNode = engine.inputNode
        guard let inputNode else {
            throw NSError(domain: "Audio", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo acceder al micrófono"])
        }

        let format = inputNode.outputFormat(forBus: 0)
        
        print(" Configurando engine con efecto: \(currentEffect.rawValue)")
        print(" Formato de audio: \(format)")
        
        // Adjuntar player node
        engine.attach(playerNode)
        
        // Configurar cadena de efectos desde playerNode (NO desde inputNode)
        setupEffectChain(playerNode: playerNode, format: format)
        
        // CRÍTICO: Iniciar engine PRIMERO
        try engine.start()
        print(" Engine iniciado correctamente")
        
        // LUEGO iniciar player
        playerNode.play()
        print(" PlayerNode iniciado")
        
        // FINALMENTE instalar tap (con pequeño delay para asegurar que todo esté listo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.installMicrophoneTap(format: format)
            print("Tap instalado")
        }
    }
    
    // MARK: - Microphone Tap (Solución de Stack Overflow)
    private func installMicrophoneTap(format: AVAudioFormat) {
        guard let inputNode else { return }
        
        inputNode.removeTap(onBus: 0)
        
        // Tap para capturar y reproducir audio en tiempo real
        inputNode.installTap(onBus: 0, bufferSize: 256, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Reproducir buffer capturado a través del playerNode
            // Esto permite aplicar efectos
            self.playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            
            // Calcular nivel de micrófono
            self.calculateMicLevel(from: buffer)
        }
    }
    
    // MARK: - Effect Chain Setup (desde playerNode)
    private func setupEffectChain(playerNode: AVAudioPlayerNode, format: AVAudioFormat) {
        let mainMixer = engine.mainMixerNode
        
        print(" Configurando cadena de efectos para: \(currentEffect.rawValue)")
        
        switch currentEffect {
        case .none:
            // Conexión directa
            engine.connect(playerNode, to: mainMixer, format: format)
            print("Conexión directa (sin efectos)")
            
        case .helium, .monster, .demon, .autoTune:
            let speed = AVAudioUnitVarispeed()
            configureVarispeedEffect(speed, for: currentEffect)
            engine.attach(speed)
            engine.connect(playerNode, to: speed, format: format)
            engine.connect(speed, to: mainMixer, format: format)
            varispeed = speed
            print("Varispeed configurado: rate=\(speed.rate)")
            
        case .robot:
            let speed = AVAudioUnitVarispeed()
            let dist = AVAudioUnitDistortion()
            configureVarispeedEffect(speed, for: currentEffect)
            configureDistortionEffect(dist, for: currentEffect)
            engine.attach(speed)
            engine.attach(dist)
            engine.connect(playerNode, to: speed, format: format)
            engine.connect(speed, to: dist, format: format)
            engine.connect(dist, to: mainMixer, format: format)
            varispeed = speed
            distortion = dist
            print(" Robot: Varispeed + Distortion")
            
        case .echo, .rhythmicDelay:
            let del = AVAudioUnitDelay()
            configureDelayEffect(del, for: currentEffect)
            engine.attach(del)
            engine.connect(playerNode, to: del, format: format)
            engine.connect(del, to: mainMixer, format: format)
            delay = del
            print(" Delay configurado")
            
        case .cathedral, .stadium:
            let rev = AVAudioUnitReverb()
            configureReverbEffect(rev, for: currentEffect)
            engine.attach(rev)
            engine.connect(playerNode, to: rev, format: format)
            engine.connect(rev, to: mainMixer, format: format)
            reverb = rev
            print(" Reverb configurado")
            
        case .studio, .feedbackSupressor:
            let equalizer = AVAudioUnitEQ(numberOfBands: 3)
            configureEQEffect(equalizer, for: currentEffect)
            engine.attach(equalizer)
            engine.connect(playerNode, to: equalizer, format: format)
            engine.connect(equalizer, to: mainMixer, format: format)
            eq = equalizer
            print("EQ configurado")
            
        case .spy, .walkieTalkie:
            let dist = AVAudioUnitDistortion()
            configureDistortionEffect(dist, for: currentEffect)
            engine.attach(dist)
            engine.connect(playerNode, to: dist, format: format)
            engine.connect(dist, to: mainMixer, format: format)
            distortion = dist
            print(" Distortion configurado")
        }
    }
    
    // MARK: - Calculate Mic Level
    private func calculateMicLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        var rms: Float = 0
        for i in 0..<frameLength {
            rms += channelData[i] * channelData[i]
        }
        rms = sqrt(rms / Float(frameLength))
        
        DispatchQueue.main.async {
            self.micLevel = min(max(rms * 20, 0), 1)
        }
    }
    
    // MARK: - Effect Configuration
    private func configureVarispeedEffect(_ speed: AVAudioUnitVarispeed, for effect: VoiceEffect) {
        switch effect {
        case .helium:
            speed.rate = 2.0
        case .robot:
            speed.rate = 0.75
        case .monster:
            speed.rate = 0.5
        case .demon:
            speed.rate = 0.6
        case .autoTune:
            speed.rate = 1.05
        default:
            speed.rate = 1.0
        }
    }
    
    private func configureDistortionEffect(_ dist: AVAudioUnitDistortion, for effect: VoiceEffect) {
        switch effect {
        case .robot:
            dist.loadFactoryPreset(.multiBrokenSpeaker)
            dist.wetDryMix = 50
        case .spy:
            dist.loadFactoryPreset(.speechRadioTower)
            dist.wetDryMix = 50
        case .walkieTalkie:
            dist.loadFactoryPreset(.speechRadioTower)
            dist.wetDryMix = 70
        default:
            break
        }
    }
    
    private func configureDelayEffect(_ del: AVAudioUnitDelay, for effect: VoiceEffect) {
        switch effect {
        case .echo:
            del.delayTime = 0.3
            del.feedback = 50
            del.wetDryMix = 40
        case .rhythmicDelay:
            del.delayTime = 0.5
            del.feedback = 60
            del.wetDryMix = 50
        default:
            break
        }
    }
    
    private func configureReverbEffect(_ rev: AVAudioUnitReverb, for effect: VoiceEffect) {
        switch effect {
        case .cathedral:
            rev.loadFactoryPreset(.cathedral)
            rev.wetDryMix = 60
        case .stadium:
            rev.loadFactoryPreset(.largeHall)
            rev.wetDryMix = 70
        default:
            break
        }
    }
    
    private func configureEQEffect(_ equalizer: AVAudioUnitEQ, for effect: VoiceEffect) {
        switch effect {
        case .studio:
            equalizer.bands[0].frequency = 100
            equalizer.bands[0].gain = 3
            equalizer.bands[0].filterType = .parametric
            equalizer.bands[0].bypass = false
            
            equalizer.bands[1].frequency = 2000
            equalizer.bands[1].gain = 4
            equalizer.bands[1].filterType = .parametric
            equalizer.bands[1].bypass = false
            
            equalizer.bands[2].frequency = 8000
            equalizer.bands[2].gain = 2
            equalizer.bands[2].filterType = .parametric
            equalizer.bands[2].bypass = false
            
        case .feedbackSupressor:
            equalizer.bands[0].frequency = 2000
            equalizer.bands[0].gain = -12
            equalizer.bands[0].filterType = .parametric
            equalizer.bands[0].bypass = false
            
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    private func cleanupEffectNodes() {
        varispeed = nil
        reverb = nil
        distortion = nil
        delay = nil
        eq = nil
    }

    // MARK: - Notifications
    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(routeChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    // MARK: - Handlers
    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == .began {
            isInterrupted = true
            stopMicrophone()
        } else if type == .ended {
            isInterrupted = false
            
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    DispatchQueue.main.async {
                        self.errorMessage = "Audio interrumpido. Presiona para continuar."
                    }
                }
            }
        }
    }

    @objc private func appDidEnterBackground() {
        print("App entered background - audio continúa")
    }

    @objc private func appWillEnterForeground() {
        checkBluetoothStatus()
        
        if isTransmitting {
            do {
                try audioSession.setActive(true)
            } catch {
                print("Error reactivando sesión: \(error)")
            }
        }
    }

    @objc private func routeChanged() {
        let wasConnected = isBluetoothConnected
        checkBluetoothStatus()
        
        if wasConnected && !isBluetoothConnected && isTransmitting {
            DispatchQueue.main.async {
                self.stopMicrophone()
                self.errorMessage = "Bluetooth desconectado"
            }
        }
    }
}
