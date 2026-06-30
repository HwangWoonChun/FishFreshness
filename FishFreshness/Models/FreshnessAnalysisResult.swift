import Foundation
import FoundationModels
import UIKit

// MARK: - Indicator Status

@Generable
struct IndicatorStatus: Codable {
    @Guide(description: "FRESH, ACCEPTABLE, or POOR")
    var level: IndicatorLevel

    @Guide(description: "한국어로 이 항목만 관찰한 내용. 예: 눈이 맑고 볼록합니다.")
    var observation: String
}

// MARK: - Freshness Analysis Result

@Generable
struct FreshnessAnalysisResult: Codable {

    @Guide(description: "어종 이름. 예: 고등어, 연어. 모르면 Unknown")
    var fishSpecies: String

    @Guide(description: "1~5 정수. 5=매우 신선, 1=부패")
    var overallScore: Int

    @Guide(description: "EXCELLENT, GOOD, ACCEPTABLE, CAUTION, or SPOILED")
    var grade: FreshnessGrade

    @Guide(description: "눈 상태 평가")
    var eyeCondition: IndicatorStatus

    @Guide(description: "아가미 색 평가")
    var gillCondition: IndicatorStatus

    @Guide(description: "비늘 상태 평가")
    var scaleCondition: IndicatorStatus

    @Guide(description: "살 탄력 평가")
    var fleshCondition: IndicatorStatus

    @Guide(description: "전체 색감 평가")
    var colorCondition: IndicatorStatus

    @Guide(description: "한국어 조리 추천. 예: 회나 구이에 적합합니다.")
    var cookingRecommendation: String

    @Guide(description: "한국어 안전 조언. 예: 충분히 익혀 드세요.")
    var safetyAdvice: String

    @Guide(description: "한국어 요약 2~3문장. 예: 전반적으로 신선한 고등어입니다.")
    var summary: String
}

// MARK: - Convenience Extensions

extension FreshnessAnalysisResult {
    var allIndicators: [(title: String, systemImage: String, status: IndicatorStatus)] {
        [
            ("눈 상태",   "eye",               eyeCondition),
            ("아가미 색", "drop.fill",         gillCondition),
            ("비늘 상태", "shield.lefthalf.filled", scaleCondition),
            ("살의 탄력", "hand.raised.fill",  fleshCondition),
            ("전체 색감", "paintpalette.fill", colorCondition),
        ]
    }

    /// Ensures score and grade stay consistent with indicator levels.
    func normalized() -> FreshnessAnalysisResult {
        var copy = self
        copy.overallScore = min(5, max(1, overallScore))

        let derivedScore = Self.derivedScore(from: copy)
        if Self.scoreConflictsWithIndicators(copy) {
            copy.overallScore = derivedScore
        }

        copy.grade = FreshnessGrade.from(score: copy.overallScore)
        return copy
    }

    var isLowQuality: Bool {
        let placeholderPatterns = [
            "should be written",
            "should be given",
            "korean language",
            "never refuse",
            "provide your best",
            "fish freshness",
            "consumption should be avoided",
            "write the summary",
            "safety advice should",
            "cooking should be"
        ]

        let textFields = [
            fishSpecies,
            summary,
            cookingRecommendation,
            safetyAdvice,
            eyeCondition.observation,
            gillCondition.observation,
            scaleCondition.observation,
            fleshCondition.observation,
            colorCondition.observation
        ]
        let combined = textFields.joined(separator: " ").lowercased()

        if placeholderPatterns.contains(where: { combined.contains($0) }) {
            return true
        }

        let observations = textFields.dropFirst(4).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        if observations.count >= 2, Set(observations).count == 1 {
            return true
        }

        if summary.count < 12 || fishSpecies.count < 2 {
            return true
        }

        return Self.scoreConflictsWithIndicators(self)
    }

    private static func scoreConflictsWithIndicators(_ result: FreshnessAnalysisResult) -> Bool {
        let levels = [
            result.eyeCondition.level,
            result.gillCondition.level,
            result.scaleCondition.level,
            result.fleshCondition.level,
            result.colorCondition.level
        ]
        let poorCount = levels.filter { $0 == .poor }.count
        let freshCount = levels.filter { $0 == .fresh }.count

        if poorCount >= 3 && result.overallScore >= 4 { return true }
        if freshCount >= 4 && result.overallScore <= 2 { return true }
        return false
    }

    private static func derivedScore(from result: FreshnessAnalysisResult) -> Int {
        let levels = [
            result.eyeCondition.level,
            result.gillCondition.level,
            result.scaleCondition.level,
            result.fleshCondition.level,
            result.colorCondition.level
        ]
        let fresh = levels.filter { $0 == .fresh }.count
        let poor = levels.filter { $0 == .poor }.count

        switch (fresh, poor) {
        case (4...5, _): return 5
        case (3, 0): return 4
        case (2...3, 0...1): return 3
        case (_, 4...5): return 1
        case (_, 3): return 2
        case (_, 2): return 2
        default: return 3
        }
    }

    /// Convert to SwiftData model for persistence
    func toScanRecord(image: UIImage?, fishHint: String?) -> FishScanRecord {
        let record = FishScanRecord(
            fishSpecies: fishSpecies,
            overallScore: overallScore,
            gradeRaw: grade.rawValue,
            eyeLevelRaw: eyeCondition.level.rawValue,
            eyeObservation: eyeCondition.observation,
            gillLevelRaw: gillCondition.level.rawValue,
            gillObservation: gillCondition.observation,
            scaleLevelRaw: scaleCondition.level.rawValue,
            scaleObservation: scaleCondition.observation,
            fleshLevelRaw: fleshCondition.level.rawValue,
            fleshObservation: fleshCondition.observation,
            colorLevelRaw: colorCondition.level.rawValue,
            colorObservation: colorCondition.observation,
            cookingRecommendation: cookingRecommendation,
            safetyAdvice: safetyAdvice,
            summary: summary,
            fishHint: fishHint
        )
        if let image {
            record.imageData = ImageProcessing.jpegData(from: image)
        }
        return record
    }
}
