import Foundation
import NaturalLanguage

enum DetectedLanguage {
    case en
    case es

    var bcp47: String {
        switch self {
        case .en: return "en-US"
        case .es: return "es-MX"
        }
    }
}

struct LanguageDetector {
    static func detect(from text: String) -> DetectedLanguage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 25 else { return nil }

        let rec = NLLanguageRecognizer()
        rec.processString(trimmed)
        guard let lang = rec.dominantLanguage else { return nil }

        if lang == .spanish { return .es }
        if lang == .english { return .en }
        return nil
    }
}
