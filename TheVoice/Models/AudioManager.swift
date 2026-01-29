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
    
    // Audio Units para efectos (creados bajo demanda)
    private var pitchControl: AVAudioUnitTimePitch?
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
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.installMeterTap()
            }

            isTransmitting = true
            errorMessage = nil
            
     
            print(" Micrófono iniciado con efecto: \(currentEffect.rawValue)")
            
        } catch {
            errorMessage = error.localizedDescription
            stopMicrophone()
            print(" Error al iniciar: \(error)")
        }
    }

    func stopMicrophone() {
        removeMeterTap()
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
        
        // Debug: Imprimir efecto aplicado
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
        
        // Limpiar efectos anteriores
        cleanupEffectNodes()

        inputNode = engine.inputNode
        guard let inputNode else {
            throw NSError(domain: "Audio", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo acceder al micrófono"])
        }

        let format = inputNode.outputFormat(forBus: 0)
        
        print(" Configurando engine con efecto: \(currentEffect.rawValue)")
        print(" Formato de audio: \(format)")
        

        if currentEffect != .none {
            try setupEffectChain(inputNode: inputNode, format: format)
        } else {
            // Conexión directa sin efectos
            engine.connect(inputNode, to: engine.mainMixerNode, format: format)
            print(" Conexión directa (sin efectos)")
        }

        try engine.start()
        print(" Engine iniciado correctamente")
    }
    
    // MARK: - Effect Chain Setup
    private func setupEffectChain(inputNode: AVAudioInputNode, format: AVAudioFormat) throws {
        let mainMixer = engine.mainMixerNode
        
        print(" Configurando cadena de efectos para: \(currentEffect.rawValue)")
        
        switch currentEffect {
        case .none:

            break
            
        case .helium, .monster, .demon, .autoTune:
            // Solo pitch
            let pitch = AVAudioUnitTimePitch()
            configurePitchEffect(pitch, for: currentEffect)
            engine.attach(pitch)
            engine.connect(inputNode, to: pitch, format: format)
            engine.connect(pitch, to: mainMixer, format: format)
            pitchControl = pitch
            print(" Pitch configurado: \(pitch.pitch) cents")
            
        case .robot:
            // Pitch + Distortion
            let pitch = AVAudioUnitTimePitch()
            let dist = AVAudioUnitDistortion()
            configurePitchEffect(pitch, for: currentEffect)
            configureDistortionEffect(dist, for: currentEffect)
            engine.attach(pitch)
            engine.attach(dist)
            engine.connect(inputNode, to: pitch, format: format)
            engine.connect(pitch, to: dist, format: format)
            engine.connect(dist, to: mainMixer, format: format)
            pitchControl = pitch
            distortion = dist
            print("Robot: Pitch + Distortion configurados")
            
        case .echo, .rhythmicDelay:
            // Solo delay
            let del = AVAudioUnitDelay()
            configureDelayEffect(del, for: currentEffect)
            engine.attach(del)
            engine.connect(inputNode, to: del, format: format)
            engine.connect(del, to: mainMixer, format: format)
            delay = del
            print("Delay configurado: \(del.delayTime)s")
            
        case .cathedral, .stadium:
            // Solo reverb
            let rev = AVAudioUnitReverb()
            configureReverbEffect(rev, for: currentEffect)
            engine.attach(rev)
            engine.connect(inputNode, to: rev, format: format)
            engine.connect(rev, to: mainMixer, format: format)
            reverb = rev
            print("Reverb configurado")
            
        case .studio, .feedbackSupressor:
            // Solo EQ
            let equalizer = AVAudioUnitEQ(numberOfBands: 3)
            configureEQEffect(equalizer, for: currentEffect)
            engine.attach(equalizer)
            engine.connect(inputNode, to: equalizer, format: format)
            engine.connect(equalizer, to: mainMixer, format: format)
            eq = equalizer
            print(" EQ configurado")
            
        case .spy, .walkieTalkie:
            // Solo distortion
            let dist = AVAudioUnitDistortion()
            configureDistortionEffect(dist, for: currentEffect)
            engine.attach(dist)
            engine.connect(inputNode, to: dist, format: format)
            engine.connect(dist, to: mainMixer, format: format)
            distortion = dist
            print("Distortion configurado")
        }
    }
    
    // MARK: - Effect Configuration (como en el repositorio)
    private func configurePitchEffect(_ pitch: AVAudioUnitTimePitch, for effect: VoiceEffect) {
        switch effect {
        case .helium:
            pitch.pitch = 1000
        case .robot:
            pitch.pitch = -200
            pitch.rate = 0.95
        case .monster:
            pitch.pitch = -1200
        case .demon:
            pitch.pitch = -1000
            pitch.rate = 0.85
        case .autoTune:
            pitch.pitch = 100
        default:
            break
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
    
    // MARK: - Cleanup Effect Nodes
    private func cleanupEffectNodes() {
        pitchControl = nil
        reverb = nil
        distortion = nil
        delay = nil
        eq = nil
    }

    // MARK: - Mic Level Meter
    private func installMeterTap() {
        guard let inputNode else { return }

        let bus = 0
        let format = inputNode.outputFormat(forBus: bus)

        inputNode.removeTap(onBus: bus)

        inputNode.installTap(
            onBus: bus,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            guard let self else { return }

            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)

            guard let channelData else { return }

            var rms: Float = 0

            for i in 0..<frameLength {
                rms += channelData[i] * channelData[i]
            }

            rms = sqrt(rms / Float(frameLength))

            DispatchQueue.main.async {
                self.micLevel = min(max(rms * 20, 0), 1)
            }
        }
    }

    private func removeMeterTap() {
        inputNode?.removeTap(onBus: 0)
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
