import Foundation

enum VoiceEffect: String, CaseIterable, Identifiable {
    case none = "Sin Efecto"
    
    // GRATIS - Básicos
    case helium = "Helio"
    case echo = "Eco"
    
    // PREMIUM - Transformación
    case monster = "Monstruo"
    
    // PREMIUM - Profundidad y Ambiente
    case cathedral = "Catedral"
    case stadium = "Estadio"
    case rhythmicDelay = "Eco Rítmico"
    
    
    var id: String { self.rawValue }
    
    var isPremium: Bool {
        switch self {
        case .none, .helium, .echo:
            return false
        default:
            return true
        }
    }
    
    var category: EffectCategory {
        switch self {
        case .none:
            return .basic
        case .helium, .echo:
            return .basic
        case . monster:
            return .transformation
        case .cathedral, .stadium, .rhythmicDelay:
            return .ambient
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.wave.2"
        case .helium: return "balloon"
        case .echo: return "waveform"
        case .cathedral: return "building.columns"
        case .stadium: return "sportscourt"
        case .rhythmicDelay: return "metronome"
        case .monster: return "flame.fill"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "Voz natural sin modificaciones"
        case .helium:
            return "Voz aguda y divertida como con helio"
        case .echo:
            return "Eco simple para ambiente"
        case .cathedral:
            return "Reverberación amplia como en una catedral"
        case .stadium:
            return "Sonido de estadio masivo"
        case .rhythmicDelay:
            return "Repeticiones controladas de tu voz"
        case .monster:
            return "Voz profunda y aterradora"
        }
    }
}

enum EffectCategory: String, CaseIterable {
    case basic = "Básicos"
    case transformation = "Transformación Total"
    case ambient = "Profundidad y Ambiente"
    
    var icon: String {
        switch self {
        case .basic: return "star"
        case .ambient: return "waveform.path.ecg"
        case .transformation: return "theatermasks.fill"
        }
    }
}
