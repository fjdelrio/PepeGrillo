import Foundation

enum OutputMode: String, CaseIterable, Identifiable {
    case nudges = "Nudges"
    case full = "Full"
    case cluely = "Cluely"

    var id: String { rawValue }

    var maxBullets: Int {
        switch self {
        case .nudges: return 2
        case .full: return 6
        case .cluely: return 1
        }
    }
}

enum LanguageMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case english = "English"
    case spanish = "Español"

    var id: String { rawValue }
}
