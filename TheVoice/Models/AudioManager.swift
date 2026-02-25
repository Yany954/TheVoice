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
    private var peakingParametricEQ: PeakingParametricEqualizerFilter?
    private var dynamicsProcessor: DynamicsProcessor?
    private var highPassFilter: HighPassFilter?
    private var lowPassFilter: LowPassFilter?
    
    // Feedback detection
    private var feedbackDetectionTimer: Timer?
    private var previousRMS: Float = 0.0
    private let feedbackThreshold: Float = 0.15  // Umbral de RMS para detectar feedback
    private let rmsIncreaseThreshold: Float = 2.5  // Si RMS aumenta 2.5x rápido = feedback
    private var pitchTap: PitchTap?
    
    private var isStartingEngine = false
    private let audioSession = AVAudioSession.sharedInstance()
    private var levelTap: RawDataTap?

    // MARK: - Init
    init() {
        configureNotifications()
        checkBluetoothStatus()
    }

    deinit {
        stopMicrophone()
        feedbackDetectionTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
  

    func installAutoTune(on input: Node, shifter: PitchShifter) {

        pitchTap = PitchTap(input) { pitches, _ in
            guard let freq = pitches.first, freq > 0 else { return }

            let midi = 69 + 12 * log2(freq / 440.0)

            // Redondear a nota más cercana (corrección)
            let correctedMidi = round(midi)

            let diff = correctedMidi - midi

            DispatchQueue.main.async {
                shifter.shift = diff
            }
        }

        pitchTap?.start()
    }

    // MARK: - Public API
    func startMicrophone() {
        guard !isTransmitting else { return }
        guard !isInterrupted else { return }

        isStartingEngine = true

        do {
            try configureSession()
            try startAudioKit()

            isTransmitting = true
            errorMessage = nil
            
            // Iniciar monitoreo de feedback
            startFeedbackDetection()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isStartingEngine = false
                self.checkBluetoothStatus()
            }
            
            print("🎤 Micrófono iniciado con efecto: \(currentEffect.rawValue)")
            
        } catch {
            isStartingEngine = false
            errorMessage = error.localizedDescription
            stopMicrophone()
            print("❌ Error al iniciar: \(error)")
        }
    }

    func stopMicrophone() {
        engine?.stop()
        
        // Detener monitoreo de feedback
        feedbackDetectionTimer?.invalidate()
        feedbackDetectionTimer = nil
        previousRMS = 0.0
        
        // Limpiar efectos
        pitchShifter = nil
        reverb = nil
        distortion = nil
        delay = nil
        peakingParametricEQ = nil
        dynamicsProcessor = nil
        highPassFilter = nil
        lowPassFilter = nil
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
        let outputs = audioSession.currentRoute.outputs
        let inputs = audioSession.currentRoute.inputs
        
        let btOutputTypes: [AVAudioSession.Port] = [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
        let btInputTypes: [AVAudioSession.Port] = [.bluetoothHFP]
        
        let hasBluetoothOutput = outputs.contains { btOutputTypes.contains($0.portType) }
        let hasBluetoothInput  = inputs.contains  { btInputTypes.contains($0.portType) }
        
        isBluetoothConnected = hasBluetoothOutput || hasBluetoothInput
    }

    // MARK: - Audio Setup
    private func configureSession() throws {
        // Configurar buffer muy bajo para reducir latencia y energía del loop
        try audioSession.setPreferredIOBufferDuration(0.005)  // 5ms
        
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .mixWithOthers]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        print("✅ Buffer duration configurado: \(audioSession.ioBufferDuration)")
    }

    private func startAudioKit() throws {
        engine = AudioEngine()
        
        guard let engine = engine else {
            throw NSError(domain: "Audio", code: -1)
        }
        
        guard let input = engine.input else {
            throw NSError(domain: "Audio", code: -2, userInfo: [NSLocalizedDescriptionKey: "No hay micrófono disponible"])
        }
        
        mic = input
        
        print("🔧 Configurando AudioKit con efecto: \(currentEffect.rawValue)")
        
        let output = setupAudioKitChain(input: input)
        engine.output = output
        installLevelTap(on: input)
        
        try engine.start()
        
        print("✅ AudioKit iniciado correctamente")
    }
    
    // MARK: - SISTEMA PROFESIONAL ANTI-FEEDBACK
    
    // 1️⃣ HIGH-PASS FILTER (elimina graves donde feedback ama vivir)
    private func applyHighPassFilter(to node: Node) -> Node {
        let hpf = HighPassFilter(node)
        hpf.cutoffFrequency = 120  // Corta todo por debajo de 120Hz
        hpf.resonance = 0.0        // Sin resonancia para evitar picos
        highPassFilter = hpf
        return hpf
    }
    
    // 2️⃣ MULTI-NOTCH FILTERS (cubre frecuencias problemáticas comunes)
    private func applyMultiNotchFilters(to node: Node) -> Node {
        var currentNode = node
        
        // Notch 1: 250 Hz (graves-medios)
        let eq1 = PeakingParametricEqualizerFilter(currentNode)
        eq1.centerFrequency = 250
        eq1.q = 3.5
        eq1.gain = -18
        currentNode = eq1
        
        // Notch 2: 500 Hz (medios)
        let eq2 = PeakingParametricEqualizerFilter(currentNode)
        eq2.centerFrequency = 500
        eq2.q = 3.5
        eq2.gain = -18
        currentNode = eq2
        
        // Notch 3: 1000 Hz (medios-altos)
        let eq3 = PeakingParametricEqualizerFilter(currentNode)
        eq3.centerFrequency = 1000
        eq3.q = 3.5
        eq3.gain = -18
        currentNode = eq3
        
        // Notch 4: 2000 Hz (presencia)
        let eq4 = PeakingParametricEqualizerFilter(currentNode)
        eq4.centerFrequency = 2000
        eq4.q = 3.5
        eq4.gain = -15  // Menos agresivo para no matar la voz
        currentNode = eq4
        
        peakingParametricEQ = eq1  // Guardar referencia
        return currentNode
    }
    
    // 3️⃣ LIMITER AGRESIVO (evita runaway gain)
    private func applyLimiter(to node: Node) -> Node {
        let limiter = DynamicsProcessor(node)
        limiter.threshold = -12       // Limita a -12dB
        limiter.headRoom = 12         // Máxima reducción de 12dB
        limiter.attackTime = 0.001    // Ataque ultra rápido (1ms)
        limiter.releaseTime = 0.05    // Release rápido (50ms)
        limiter.expansionRatio = 1.0  // Sin expansión
        limiter.masterGain = 0        // Sin ganancia adicional
        dynamicsProcessor = limiter
        return limiter
    }
    
    // 4️⃣ LOW-PASS FILTER suave (quita agudos extremos que pueden oscilar)
    private func applyLowPassFilter(to node: Node) -> Node {
        let lpf = LowPassFilter(node)
        lpf.cutoffFrequency = 8000  // Corta por encima de 8kHz
        lpf.resonance = 0.0
        lowPassFilter = lpf
        return lpf
    }
    
    // 5️⃣ CADENA COMPLETA ANTI-FEEDBACK (aplicar a TODOS los efectos)
    private func applyFeedbackSuppressionChain(to node: Node) -> Node {
        var currentNode = node
        
        // Orden crítico:
        currentNode = applyHighPassFilter(to: currentNode)      // 1. HPF primero
        currentNode = applyMultiNotchFilters(to: currentNode)   // 2. Multi-notch
        currentNode = applyLimiter(to: currentNode)             // 3. Limiter
        currentNode = applyLowPassFilter(to: currentNode)       // 4. LPF último
        
        return currentNode
    }
    
    // 6️⃣ DETECCIÓN AUTOMÁTICA DE FEEDBACK
    private func startFeedbackDetection() {
        feedbackDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentRMS = self.micLevel
            
            // Detectar aumento súbito de RMS (posible feedback)
            if self.previousRMS > 0 {
                let rmsRatio = currentRMS / self.previousRMS
                
                // Si RMS aumenta más de 2.5x en 50ms + está sobre umbral = FEEDBACK
                if rmsRatio > self.rmsIncreaseThreshold && currentRMS > self.feedbackThreshold {
                    self.handleFeedbackDetected()
                }
            }
            
            self.previousRMS = currentRMS
        }
    }
    
    private func handleFeedbackDetected() {
        print("🚨 FEEDBACK DETECTADO - Reduciendo volumen automáticamente")
        
        // Reducir volumen del mixer inmediatamente
        if let mixer = mixer {
            let currentVolume = mixer.volume
            let newVolume = currentVolume * 0.65  // Reducir 35%
            
            DispatchQueue.main.async {
                mixer.volume = max(newVolume, 0.3)  // Mínimo 30%
                
                // Mensaje al usuario
                //self.errorMessage = "Volumen reducido automáticamente (anti-acople)"
                
                // Limpiar mensaje después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.errorMessage == "Volumen reducido automáticamente (anti-acople)" {
                        self.errorMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - AudioKit Effect Chain
    private func setupAudioKitChain(input: Node) -> Node {
        var currentNode: Node = input
        
        // CRÍTICO: Aplicar cadena anti-feedback PRIMERO, antes de cualquier efecto
        currentNode = applyFeedbackSuppressionChain(to: currentNode)
        
        switch currentEffect {
            
        case .none:
            mixer = Mixer(currentNode)
            mixer!.volume = 0.75  // Volumen conservador
            print("✅ Sin efecto + Anti-feedback PRO")
            return mixer!
            
        case .helium:
            let shifter = PitchShifter(currentNode, shift: 12)
            pitchShifter = shifter
            mixer = Mixer(shifter)
            mixer!.volume = 0.70
            print("✅ Helio + Anti-feedback PRO")
            return mixer!
            
        case .monster:
            let shifter = PitchShifter(currentNode, shift: -12)
            
            // EQ oscuro (después del anti-feedback)
            let eq = PeakingParametricEqualizerFilter(shifter)
            eq.centerFrequency = 8000
            eq.q = 0.5
            eq.gain = -15
            
            // Reverb MUY controlado
            let rev = Reverb(eq)
            rev.loadFactoryPreset(.mediumHall)
            rev.dryWetMix = 0.15  // Reducido aún más
            
            mixer = Mixer(rev)
            mixer!.volume = 4
            
            pitchShifter = shifter
            reverb = rev
            
            print("✅ Monster + Anti-feedback PRO")
            return mixer!

        case .echo:
            // Echo con feedback controlado
            let del = Delay(currentNode)
            del.time = 0.3
            del.feedback = 40  // Reducido de 50
            del.dryWetMix = 0.35  // Reducido de 0.4
            delay = del
            mixer = Mixer(del)
            mixer!.volume = 0.70
            print("✅ Echo + Anti-feedback PRO")
            return mixer!
            
        case .rhythmicDelay:
            let del = Delay(currentNode)
            del.time = 0.5
            del.feedback = 50  // Reducido de 60
            del.dryWetMix = 0.45  // Reducido de 0.5
            delay = del
            mixer = Mixer(del)
            mixer!.volume = 0.70
            print("✅ Rhythmic Delay + Anti-feedback PRO")
            return mixer!
            
        case .cathedral:
            // Cathedral con wet reducido
            let rev = Reverb(currentNode)
            rev.loadFactoryPreset(.cathedral)
            rev.dryWetMix = 0.50  // Reducido de 0.6
            reverb = rev
            mixer = Mixer(rev)
            mixer!.volume = 0.65
            print("✅ Cathedral + Anti-feedback PRO")
            return mixer!
            
        case .stadium:
            // Stadium con wet reducido
            let rev = Reverb(currentNode)
            rev.loadFactoryPreset(.largeHall)
            rev.dryWetMix = 0.60  // Reducido de 0.7
            reverb = rev
            mixer = Mixer(rev)
            mixer!.volume = 0.65
            print("✅ Stadium + Anti-feedback PRO")
            return mixer!
            
        
            
        default:
            mixer = Mixer(currentNode)
            mixer!.volume = 0.75
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
        guard !isStartingEngine else {
            print("⚠️ routeChanged ignorado durante inicio del engine")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let wasConnected = self.isBluetoothConnected
            self.checkBluetoothStatus()
            
            if wasConnected && !self.isBluetoothConnected && self.isTransmitting {
                self.stopMicrophone()
                self.errorMessage = "Bluetooth desconectado"
                print("🔴 Bluetooth desconectado - deteniendo micrófono")
            }
        }
    }
}
