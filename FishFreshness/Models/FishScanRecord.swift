import Foundation
import SwiftData
import UIKit

@Model
final class FishScanRecord {

    // MARK: - Identity
    var id: UUID
    var timestamp: Date

    // MARK: - Image
    var imageData: Data?

    // MARK: - Core Result
    var fishSpecies: String
    var overallScore: Int
    var gradeRaw: String

    // MARK: - Indicators (flattened for SwiftData)
    var eyeLevelRaw: String
    var eyeObservation: String

    var gillLevelRaw: String
    var gillObservation: String

    var scaleLevelRaw: String
    var scaleObservation: String

    var fleshLevelRaw: String
    var fleshObservation: String

    var colorLevelRaw: String
    var colorObservation: String

    // MARK: - Recommendations
    var cookingRecommendation: String
    var safetyAdvice: String
    var summary: String

    // MARK: - Optional
    var fishHint: String?

    init(
        fishSpecies: String,
        overallScore: Int,
        gradeRaw: String,
        eyeLevelRaw: String,
        eyeObservation: String,
        gillLevelRaw: String,
        gillObservation: String,
        scaleLevelRaw: String,
        scaleObservation: String,
        fleshLevelRaw: String,
        fleshObservation: String,
        colorLevelRaw: String,
        colorObservation: String,
        cookingRecommendation: String,
        safetyAdvice: String,
        summary: String,
        fishHint: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.fishSpecies = fishSpecies
        self.overallScore = overallScore
        self.gradeRaw = gradeRaw
        self.eyeLevelRaw = eyeLevelRaw
        self.eyeObservation = eyeObservation
        self.gillLevelRaw = gillLevelRaw
        self.gillObservation = gillObservation
        self.scaleLevelRaw = scaleLevelRaw
        self.scaleObservation = scaleObservation
        self.fleshLevelRaw = fleshLevelRaw
        self.fleshObservation = fleshObservation
        self.colorLevelRaw = colorLevelRaw
        self.colorObservation = colorObservation
        self.cookingRecommendation = cookingRecommendation
        self.safetyAdvice = safetyAdvice
        self.summary = summary
        self.fishHint = fishHint
    }

    // MARK: - Computed Properties

    var grade: FreshnessGrade {
        FreshnessGrade(rawValue: gradeRaw) ?? .acceptable
    }

    var thumbnailImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    /// Reconstruct FreshnessAnalysisResult for detail display
    var analysisResult: FreshnessAnalysisResult {
        FreshnessAnalysisResult(
            fishSpecies: fishSpecies,
            overallScore: overallScore,
            grade: grade,
            eyeCondition: IndicatorStatus(
                level: IndicatorLevel(rawValue: eyeLevelRaw) ?? .acceptable,
                observation: eyeObservation
            ),
            gillCondition: IndicatorStatus(
                level: IndicatorLevel(rawValue: gillLevelRaw) ?? .acceptable,
                observation: gillObservation
            ),
            scaleCondition: IndicatorStatus(
                level: IndicatorLevel(rawValue: scaleLevelRaw) ?? .acceptable,
                observation: scaleObservation
            ),
            fleshCondition: IndicatorStatus(
                level: IndicatorLevel(rawValue: fleshLevelRaw) ?? .acceptable,
                observation: fleshObservation
            ),
            colorCondition: IndicatorStatus(
                level: IndicatorLevel(rawValue: colorLevelRaw) ?? .acceptable,
                observation: colorObservation
            ),
            cookingRecommendation: cookingRecommendation,
            safetyAdvice: safetyAdvice,
            summary: summary
        )
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 HH:mm"
        return formatter.string(from: timestamp)
    }
}
