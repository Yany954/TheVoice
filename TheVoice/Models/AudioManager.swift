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
            installMeterTap()

            isTransmitting = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            stopMicrophone()
        }
    }

    func stopMicrophone() {
        removeMeterTap()
        engine.stop()
        engine.reset()

        isTransmitting = false
        micLevel = 0
    }

    func applyEffect(_ effect: VoiceEffect) {
        currentEffect = effect
        // Effects must be applied ONLY when engine is stopped
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
            options: [.allowBluetooth, .defaultToSpeaker]
        )
        try audioSession.setActive(true)
    }

    private func startEngine() throws {
        engine.stop()
        engine.reset()

        inputNode = engine.inputNode
        guard let inputNode else {
            throw NSError(domain: "Audio", code: -1)
        }

        let format = inputNode.outputFormat(forBus: 0)

        engine.connect(inputNode, to: engine.mainMixerNode, format: format)

        try engine.start()
    }

    // MARK: - Mic Level Meter (CORRECT)

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
        } else {
            isInterrupted = false
        }
    }

    @objc private func appDidEnterBackground() {
        stopMicrophone()
    }

    @objc private func appWillEnterForeground() {
        checkBluetoothStatus()
    }

    @objc private func routeChanged() {
        checkBluetoothStatus()
    }
}
