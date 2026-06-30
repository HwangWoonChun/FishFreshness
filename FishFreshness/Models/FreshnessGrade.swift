import SwiftUI
import FoundationModels

// MARK: - Freshness Grade

@Generable
enum FreshnessGrade: String, CaseIterable, Codable {
    case excellent = "EXCELLENT"
    case good = "GOOD"
    case acceptable = "ACCEPTABLE"
    case caution = "CAUTION"
    case spoiled = "SPOILED"

    var displayName: String {
        switch self {
        case .excellent: return "최상급"
        case .good:      return "신선"
        case .acceptable: return "보통"
        case .caution:   return "주의"
        case .spoiled:   return "부패"
        }
    }

    var color: Color {
        switch self {
        case .excellent:  return Color(hex: "34C759")
        case .good:       return Color(hex: "30D158")
        case .acceptable: return Color(hex: "FFD60A")
        case .caution:    return Color(hex: "FF9500")
        case .spoiled:    return Color(hex: "FF3B30")
        }
    }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .excellent:  return 5...5
        case .good:       return 4...4
        case .acceptable: return 3...3
        case .caution:    return 2...2
        case .spoiled:    return 1...1
        }
    }

    var emoji: String {
        switch self {
        case .excellent:  return "🟢"
        case .good:       return "🟩"
        case .acceptable: return "🟡"
        case .caution:    return "🟠"
        case .spoiled:    return "🔴"
        }
    }

    var safetyLevel: String {
        switch self {
        case .excellent:  return "날로 먹어도 안전"
        case .good:       return "회로 섭취 가능"
        case .acceptable: return "완전히 익혀서 섭취"
        case .caution:    return "섭취 시 주의 필요"
        case .spoiled:    return "섭취 금지"
        }
    }

    static func from(score: Int) -> FreshnessGrade {
        switch min(5, max(1, score)) {
        case 5: return .excellent
        case 4: return .good
        case 3: return .acceptable
        case 2: return .caution
        default: return .spoiled
        }
    }
}

// MARK: - Indicator Level

@Generable
enum IndicatorLevel: String, CaseIterable, Codable {
    case fresh      = "FRESH"
    case acceptable = "ACCEPTABLE"
    case poor       = "POOR"

    var displayName: String {
        switch self {
        case .fresh:      return "양호"
        case .acceptable: return "보통"
        case .poor:       return "불량"
        }
    }

    var color: Color {
        switch self {
        case .fresh:      return Color(hex: "34C759")
        case .acceptable: return Color(hex: "FFD60A")
        case .poor:       return Color(hex: "FF3B30")
        }
    }

    var systemImage: String {
        switch self {
        case .fresh:      return "checkmark.circle.fill"
        case .acceptable: return "exclamationmark.circle.fill"
        case .poor:       return "xmark.circle.fill"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
