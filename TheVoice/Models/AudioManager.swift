import Foundation
import AVFoundation
import UIKit
import AudioKit
import SoundpipeAudioKit
import Accelerate

final class AudioManager: ObservableObject {

    // MARK: - UI State
    @Published private(set) var isTransmitting = false
    @Published private(set) var isBluetoothConnected = false
    @Published private(set) var isInterrupted = false
    @Published private(set) var micLevel: Float = 0.0

    @Published var currentEffect: VoiceEffect = .none
    @Published var errorMessage: String?

    // MARK: - AudioKit Core
    private var mic: AudioEngine.InputNode?
    private var mixer: Mixer?
    private var engine: AudioEngine?
    
    // AudioKit Effects
    private var pitchShifter: PitchShifter?
    private var reverb: Reverb?
    private var distortion: Distortion?
    private var delay: Delay?
    
    // AVAudioSession para Bluetooth
    private let audioSession = AVAudioSession.sharedInstance()
    
    // Tap para medidor
    private var levelTap: RawDataTap?

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
            try startAudioKit()

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
        engine?.stop()
        
        // Limpiar efectos
        pitchShifter = nil
        reverb = nil
        distortion = nil
        delay = nil
        mixer = nil
        levelTap = nil
        
        isTransmitting = false
        micLevel = 0
    }

    func applyEffect(_ effect: VoiceEffect) {
        /*guard !effect.isPremium else {
            errorMessage = "Este efecto es Premium"
            return
        }*/
        
        guard !isTransmitting else {
            errorMessage = "Detén el micrófono antes de cambiar el efecto"
            return
        }
        
        currentEffect = effect
        errorMessage = nil
        print("✅ Efecto aplicado: \(effect.rawValue)")
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

    private func startAudioKit() throws {
        // Crear engine
        engine = AudioEngine()
        
        guard let engine = engine else {
            throw NSError(domain: "Audio", code: -1)
        }
        
        // Obtener input del micrófono
        guard let input = engine.input else {
            throw NSError(domain: "Audio", code: -2, userInfo: [NSLocalizedDescriptionKey: "No hay micrófono disponible"])
        }
        
        mic = input
        
        print("🔧 Configurando AudioKit con efecto: \(currentEffect.rawValue)")
        
        // Configurar cadena de efectos
        let output = setupAudioKitChain(input: input)
        
        // Conectar al output
        engine.output = output
        
        // Instalar tap para medidor
        installLevelTap(on: input)
        
        // Iniciar engine
        try engine.start()
        
        print("✅ AudioKit iniciado correctamente")
    }
    
    // MARK: - AudioKit Effect Chain
    private func setupAudioKitChain(input: Node) -> Node {
        var currentNode: Node = input
        
        switch currentEffect {
        case .none:
            // Sin efectos
            mixer = Mixer(currentNode)
            return mixer!
            
        case .helium:
            // Pitch shifter +12 semitonos (1 octava)
            let shifter = PitchShifter(currentNode, shift: 12)
            pitchShifter = shifter
            mixer = Mixer(shifter)
            print("✅ PitchShifter: +12 semitonos (Helio)")
            return mixer!
            
        case .monster:
            // Pitch shifter -12 semitonos (monstruo profundo)
            let shifter = PitchShifter(currentNode, shift: -12)
            pitchShifter = shifter
            mixer = Mixer(shifter)
            print("✅ PitchShifter: -12 semitonos (Monstruo)")
            return mixer!
            
        
            
        case .robot:
            // Pitch -3 + Distortion
            let shifter = PitchShifter(currentNode, shift: -3)
            let dist = Distortion(shifter)
            dist.delay = 0.1
            dist.decay = 1.0
            dist.delayMix = 0.5
            pitchShifter = shifter
            distortion = dist
            mixer = Mixer(dist)
            print("✅ Robot: Pitch -3 + Distortion")
            return mixer!
            
        case .autoTune:
            // Pitch sutil +2 semitonos
            let shifter = PitchShifter(currentNode, shift: 2)
            pitchShifter = shifter
            mixer = Mixer(shifter)
            print("✅ Auto-Tune: +2 semitonos")
            return mixer!
            
        case .echo:
            // Delay simple
            let del = Delay(currentNode)
            del.time = 0.3
            del.feedback = 50
            del.dryWetMix = 0.4
            delay = del
            mixer = Mixer(del)
            print("✅ Echo configurado")
            return mixer!
            
        case .rhythmicDelay:
            // Delay rítmico
            let del = Delay(currentNode)
            del.time = 0.5
            del.feedback = 60
            del.dryWetMix = 0.5
            delay = del
            mixer = Mixer(del)
            print("✅ Rhythmic Delay")
            return mixer!
            
        case .cathedral:
            // Reverb catedral
            let rev = Reverb(currentNode)
            rev.loadFactoryPreset(.cathedral)
            rev.dryWetMix = 0.6
            reverb = rev
            mixer = Mixer(rev)
            print("✅ Cathedral Reverb")
            return mixer!
            
        case .stadium:
            // Reverb estadio
            let rev = Reverb(currentNode)
            rev.loadFactoryPreset(.largeHall)
            rev.dryWetMix = 0.7
            reverb = rev
            mixer = Mixer(rev)
            print("✅ Stadium Reverb")
            return mixer!
            
        case .studio:
            // Sin procesamiento especial por ahora
            mixer = Mixer(currentNode)
            return mixer!
            
        case .feedbackSupressor:
            // Sin procesamiento especial
            mixer = Mixer(currentNode)
            return mixer!
            
        case .spy:
            // Distortion tipo radio
            let dist = Distortion(currentNode)
            dist.delay = 0.05
            dist.decay = 0.5
            dist.delayMix = 0.5
            distortion = dist
            mixer = Mixer(dist)
            print("✅ Spy: Radio Distortion")
            return mixer!
 
        }
    }
    
    // MARK: - Level Tap
    private func installLevelTap(on node: Node) {
        levelTap = RawDataTap(node) { [weak self] (samples: [Float]) in
            guard let self = self, !samples.isEmpty else { return }
            
            var rms: Float = 0
            
            vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
            
            DispatchQueue.main.async {
               self.micLevel = min(max(rms * 25.0, 0), 1)
            }
        }
        levelTap?.start()
        
        
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
