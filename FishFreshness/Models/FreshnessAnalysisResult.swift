import Foundation
import FoundationModels
import UIKit

// MARK: - Indicator Status

@Generable
struct IndicatorStatus: Codable {
    @Guide(description: "Status level of this indicator: FRESH means the indicator looks healthy and fresh, ACCEPTABLE means borderline, POOR means this indicator shows signs of spoilage")
    var level: IndicatorLevel

    @Guide(description: "Brief 1-2 sentence observation describing what was observed for this specific indicator. Be specific and factual.")
    var observation: String
}

// MARK: - Freshness Analysis Result

@Generable
struct FreshnessAnalysisResult: Codable {

    @Guide(description: "The detected fish species (e.g., '고등어', '연어', '도미'). If the species cannot be identified, use 'Unknown'.")
    var fishSpecies: String

    @Guide(description: "Overall freshness score from 1 to 5. 5 = extremely fresh (just caught), 4 = fresh (safe to eat raw), 3 = acceptable (cook thoroughly), 2 = borderline (caution), 1 = spoiled (do not consume).")
    var overallScore: Int

    @Guide(description: "Overall freshness grade based on all indicators combined.")
    var grade: FreshnessGrade

    @Guide(description: "Assessment of the fish eyes. Fresh fish have clear, bright, bulging eyes. Old fish have cloudy, sunken, or flat eyes.")
    var eyeCondition: IndicatorStatus

    @Guide(description: "Assessment of the gill color. Fresh fish gills are bright red or pink. Old fish gills are brown, grey, or slimy.")
    var gillCondition: IndicatorStatus

    @Guide(description: "Assessment of the scales. Fresh fish have tight, shiny, metallic-looking scales. Old fish have loose, dull, or missing scales.")
    var scaleCondition: IndicatorStatus

    @Guide(description: "Assessment of flesh firmness and elasticity. Fresh fish flesh is firm and elastic (springs back when pressed). Old fish flesh is soft, indented, or mushy.")
    var fleshCondition: IndicatorStatus

    @Guide(description: "Assessment of overall color vibrancy. Fresh fish have vibrant, natural coloring. Old fish appear faded, yellowish, or discolored.")
    var colorCondition: IndicatorStatus

    @Guide(description: "Recommended cooking method based on the freshness level. For high freshness, include raw preparations. For lower freshness, recommend thorough cooking or avoiding consumption.")
    var cookingRecommendation: String

    @Guide(description: "Safety advice for consumption. Be clear and direct about any risks.")
    var safetyAdvice: String

    @Guide(description: "A brief overall summary of the analysis in Korean (2-3 sentences). Include the main freshness assessment and key observations.")
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

    /// Ensures score and grade stay consistent with the defined scale.
    func normalized() -> FreshnessAnalysisResult {
        var copy = self
        copy.overallScore = min(5, max(1, overallScore))
        copy.grade = FreshnessGrade.from(score: copy.overallScore)
        return copy
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
