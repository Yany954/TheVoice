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
    
    // AudioKit Effects (componentes disponibles en AudioKit 5.6.5)
    private var pitchShifter: PitchShifter?
    private var reverb: Reverb?
    private var distortion: Distortion?
    private var delay: Delay?
    private var peakingParametricEQ: PeakingParametricEqualizerFilter?
    private var dynamicsProcessor: DynamicsProcessor?
    
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
        peakingParametricEQ = nil
        dynamicsProcessor = nil
        mixer = nil
        levelTap = nil
        
        isTransmitting = false
        micLevel = 0
    }

    func applyEffect(_ effect: VoiceEffect) {
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
            // EFECTO VECNA MEJORADO
            // Pitch muy bajo (-12 semitonos)
            let shifter = PitchShifter(currentNode, shift: -12)
            
            // EQ para atenuar agudos (usando PeakingParametricEqualizerFilter)
            let eq = PeakingParametricEqualizerFilter(shifter)
            eq.centerFrequency = 8000  // Frecuencias agudas
            eq.q = 0.5  // Bandwidth inverso
            eq.gain = -15  // Atenuar agudos
            
            // Reverb sutil para efecto de distancia
            let rev = Reverb(eq)
            rev.loadFactoryPreset(.mediumHall)
            rev.dryWetMix = 0.35
            
            // Mixer final con volumen reducido
            mixer = Mixer(rev)
            mixer!.volume = 0.7
            
            pitchShifter = shifter
            peakingParametricEQ = eq
            reverb = rev
            print("✅ Monster: Pitch -12 + EQ oscuro + Reverb distante")
            return mixer!
            
        case .robot:
            // EFECTO ROBOT SIMPLIFICADO (sin RingModulator)
            // Pitch shifter moderado
            let shifter = PitchShifter(currentNode, shift: -5)
            shifter.crossfade = 256  // Más robótico
            
            // Delay muy corto para eco metálico
            let del = Delay(shifter)
            del.time = 0.005  // 5ms
            del.feedback = 0.01
            del.dryWetMix = 0.3
            
            // Distortion para carácter metálico
            let dist = Distortion(del)
            dist.delay = 0.05
            dist.decay = 0.8
            dist.delayMix = 0.5
            
            // EQ para enfatizar frecuencias metálicas
            let eq = PeakingParametricEqualizerFilter(dist)
            eq.centerFrequency = 2000  // Frecuencias metálicas
            eq.q = 1.0
            eq.gain = 8
            
            pitchShifter = shifter
            delay = del
            distortion = dist
            peakingParametricEQ = eq
            mixer = Mixer(eq)
            print("✅ Robot: Pitch + Delay metálico + Distortion + EQ")
            return mixer!
            
        case .autoTune:
            let shifter = PitchShifter(currentNode, shift: 0)
            shifter.crossfade = 4096  // Máxima suavidad
            
            let rev = Reverb(shifter)
            rev.loadFactoryPreset(.smallRoom)
            rev.dryWetMix = 0.08
            
            pitchShifter = shifter
            reverb = rev
            mixer = Mixer(rev)
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
            // Solo EQ suave y Reverb muy sutil
            let eq = PeakingParametricEqualizerFilter(currentNode)
            eq.centerFrequency = 3000  // Presencia vocal
            eq.q = 1.0
            eq.gain = 2  // Ganancia suave
            
            // Reverb muy sutil
            let rev = Reverb(eq)
            rev.loadFactoryPreset(.mediumRoom)
            rev.dryWetMix = 0.12  // Muy bajo para evitar cortes
            
            peakingParametricEQ = eq
            reverb = rev
            mixer = Mixer(rev)
            print("✅ Studio: EQ suave + Reverb sutil")
            return mixer!
            
        case .feedbackSupressor:
            // Solo un EQ notch en frecuencia común de acople
            let eq = PeakingParametricEqualizerFilter(currentNode)
            eq.centerFrequency = 500  // Frecuencia típica de feedback
            eq.q = 2.0  // Notch moderado
            eq.gain = -12  // Reducción moderada
            
            // Volumen reducido
            mixer = Mixer(eq)
            mixer!.volume = 0.75  // No tan bajo como antes
            
            peakingParametricEQ = eq
            print("✅ Feedback Suppressor: EQ notch simple")
            return mixer!
            
        case .spy:
            // EFECTO SPY/ANONYMOUS SIMPLIFICADO (sin RingModulator)
            // Pitch muy bajo
            let shifter = PitchShifter(currentNode, shift: -8)
            shifter.crossfade = 256  // Más artificial
            
            // Distortion tipo radio
            let dist = Distortion(shifter)
            dist.delay = 0.05
            dist.decay = 0.5
            dist.delayMix = 0.5
            
            // EQ para oscurecer
            let eq1 = PeakingParametricEqualizerFilter(dist)
            eq1.centerFrequency = 6000
            eq1.q = 0.7
            eq1.gain = -10
            
            // EQ para agregar presencia metálica
            let eq2 = PeakingParametricEqualizerFilter(eq1)
            eq2.centerFrequency = 800
            eq2.q = 1.5
            eq2.gain = 6
            
            // Delay sutil
            let del = Delay(eq2)
            del.time = 0.08
            del.feedback = 15
            del.dryWetMix = 0.2
            
            pitchShifter = shifter
            distortion = dist
            peakingParametricEQ = eq1
            delay = del
            mixer = Mixer(del)
            print("✅ Spy: Pitch bajo + Distortion + Multi-EQ + Delay")
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
