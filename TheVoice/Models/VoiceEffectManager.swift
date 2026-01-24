import Foundation

enum VoiceEffect: String, CaseIterable, Identifiable {
    case none = "Sin Efecto"
    
    // GRATIS - Básicos
    case helium = "Helio"
    case robot = "Robot"
    case echo = "Eco"
    
    // PREMIUM - Calidad Profesional
    case autoTune = "Auto-Tune"
    case studio = "Voz de Estudio"
    case feedbackSupressor = "Anti-Acople"
    
    // PREMIUM - Profundidad y Ambiente
    case cathedral = "Catedral"
    case stadium = "Estadio"
    case rhythmicDelay = "Eco Rítmico"
    
    // PREMIUM - Transformación Total
    case monster = "Monstruo"
    case demon = "Demonio"
    case spy = "Modo Espía"
    case walkieTalkie = "Walkie-Talkie"
    
    var id: String { self.rawValue }
    
    var isPremium: Bool {
        switch self {
        case .none, .helium, .robot, .echo:
            return false
        default:
            return true
        }
    }
    
    var category: EffectCategory {
        switch self {
        case .none:
            return .basic
        case .helium, .robot, .echo:
            return .basic
        case .autoTune, .studio, .feedbackSupressor:
            return .professional
        case .cathedral, .stadium, .rhythmicDelay:
            return .ambient
        case .monster, .demon, .spy, .walkieTalkie:
            return .transformation
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.wave.2"
        case .helium: return "balloon"
        case .robot: return "bolt.fill"
        case .echo: return "waveform"
        case .autoTune: return "music.note"
        case .studio: return "mic.fill"
        case .feedbackSupressor: return "speaker.slash.fill"
        case .cathedral: return "building.columns"
        case .stadium: return "sportscourt"
        case .rhythmicDelay: return "metronome"
        case .monster: return "flame.fill"
        case .demon: return "eyes"
        case .spy: return "eye.slash"
        case .walkieTalkie: return "radio"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "Voz natural sin modificaciones"
        case .helium:
            return "Voz aguda y divertida como con helio"
        case .robot:
            return "Transformación robótica clásica"
        case .echo:
            return "Eco simple para ambiente"
        case .autoTune:
            return "Afinación automática profesional"
        case .studio:
            return "Calidad de grabación profesional con compresión y EQ"
        case .feedbackSupressor:
            return "Elimina el molesto pitido del feedback"
        case .cathedral:
            return "Reverberación amplia como en una catedral"
        case .stadium:
            return "Sonido de estadio masivo"
        case .rhythmicDelay:
            return "Repeticiones controladas de tu voz"
        case .monster:
            return "Voz profunda y aterradora"
        case .demon:
            return "Transformación demoníaca extrema"
        case .spy:
            return "Voz distorsionada para agentes secretos"
        case .walkieTalkie:
            return "Efecto de radio vintage con estática"
        }
    }
}

enum EffectCategory: String, CaseIterable {
    case basic = "Básicos"
    case professional = "Calidad Profesional"
    case ambient = "Profundidad y Ambiente"
    case transformation = "Transformación Total"
    
    var icon: String {
        switch self {
        case .basic: return "star"
        case .professional: return "crown.fill"
        case .ambient: return "waveform.path.ecg"
        case .transformation: return "theatermasks.fill"
        }
    }
}
