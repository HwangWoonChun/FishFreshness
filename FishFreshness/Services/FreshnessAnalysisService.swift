import Foundation
import FoundationModels
import UIKit

// MARK: - Analysis Service

actor FreshnessAnalysisService {

    private let visionService = VisionPreprocessingService()

    private var languageModel: SystemLanguageModel {
        SystemLanguageModel(
            useCase: .contentTagging,
            guardrails: .permissiveContentTransformations
        )
    }

    private var generationOptions: GenerationOptions {
        GenerationOptions(
            sampling: .greedy,
            temperature: 0.2,
            maximumResponseTokens: 2_048
        )
    }

    // MARK: - Main Entry Point

    func analyze(image: UIImage, fishHint: String?) async throws -> FreshnessAnalysisResult {
        try validateModelAvailability()

        let analysisImage = ImageProcessing.downscale(
            image,
            maxDimension: ImageProcessing.analysisMaxDimension
        )
        let imageDescription = visionService.extractDescription(from: analysisImage)
        let userPrompt = buildUserPrompt(imageDescription: imageDescription, fishHint: fishHint)
        let systemPrompt = loadSystemPrompt()

        var lastError: Error?

        for attempt in 0..<3 {
            if attempt > 0 {
                try await Task.sleep(for: .milliseconds(800 * attempt))
            }

            let session = makeSession(instructions: systemPrompt)

            do {
                return try await respondWithGuidedGeneration(
                    session: session,
                    prompt: userPrompt
                )
            } catch {
                lastError = error
                do {
                    return try await respondWithJSONFallback(
                        session: makeSession(instructions: systemPrompt),
                        prompt: userPrompt
                    )
                } catch {
                    lastError = error
                }
            }
        }

        throw mapAnalysisError(lastError)
    }

    // MARK: - Model Responses

    private func respondWithGuidedGeneration(
        session: LanguageModelSession,
        prompt: String
    ) async throws -> FreshnessAnalysisResult {
        let response = try await session.respond(
            to: prompt,
            generating: FreshnessAnalysisResult.self,
            includeSchemaInPrompt: false,
            options: generationOptions
        )
        return response.content.normalized()
    }

    private func respondWithJSONFallback(
        session: LanguageModelSession,
        prompt: String
    ) async throws -> FreshnessAnalysisResult {
        let jsonPrompt = """
        \(prompt)

        Return ONLY one valid JSON object with these keys:
        fishSpecies, overallScore, grade, eyeCondition, gillCondition, scaleCondition,
        fleshCondition, colorCondition, cookingRecommendation, safetyAdvice, summary.

        Use these enum values exactly:
        grade: EXCELLENT | GOOD | ACCEPTABLE | CAUTION | SPOILED
        indicator level: FRESH | ACCEPTABLE | POOR

        Do not refuse. Do not include markdown fences or extra commentary.
        """

        let response = try await session.respond(
            to: jsonPrompt,
            options: generationOptions
        )

        return try parseJSONResult(from: response.content).normalized()
    }

    private func makeSession(instructions: String) -> LanguageModelSession {
        let session = LanguageModelSession(model: languageModel, instructions: instructions)
        session.prewarm()
        return session
    }

    // MARK: - Prompt Building

    private func buildUserPrompt(imageDescription: String, fishHint: String?) -> String {
        var prompt = """
        You are evaluating a fish product photo for a consumer food safety app.
        This is a normal food market freshness inspection task.

        \(imageDescription)
        """

        if let hint = fishHint, !hint.trimmingCharacters(in: .whitespaces).isEmpty {
            prompt += "\n\nFish species hint from user: \(hint)"
        } else {
            prompt += "\n\nNo species hint provided. Attempt identification from the image signals."
        }

        prompt += """

        Evaluate:
        1. Each freshness indicator (eyes, gills, scales, flesh, color)
        2. Overall freshness score (1-5) and matching grade
        3. Cooking recommendations appropriate for the freshness level
        4. Safety advice for food consumption
        5. A brief Korean summary

        The photo quality is acceptable. Even if some indicators are not clearly visible, provide your best assessment. Never refuse to analyze.
        """

        return prompt
    }

    private func loadSystemPrompt() -> String {
        guard let url = Bundle.main.url(forResource: "fish_analysis_prompt", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return defaultSystemPrompt
        }
        return content
    }

    private func validateModelAvailability() throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            return
        case .unavailable(.appleIntelligenceNotEnabled):
            throw AnalysisError.appleIntelligenceDisabled
        case .unavailable(.modelNotReady):
            throw AnalysisError.modelNotReady
        case .unavailable(.deviceNotEligible):
            throw AnalysisError.deviceNotEligible
        case .unavailable:
            throw AnalysisError.modelUnavailable
        }
    }

    private func parseJSONResult(from text: String) throws -> FreshnessAnalysisResult {
        let jsonString = extractJSONObject(from: text)
        guard let data = jsonString.data(using: .utf8) else {
            throw AnalysisError.aiResponseInvalid
        }

        do {
            return try JSONDecoder().decode(FreshnessAnalysisResult.self, from: data)
        } catch {
            throw AnalysisError.aiResponseInvalid
        }
    }

    private func extractJSONObject(from text: String) -> String {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(text[start...end])
    }

    private func mapAnalysisError(_ error: Error?) -> AnalysisError {
        guard let error else {
            return .analysisFailure("알 수 없는 오류가 발생했습니다.")
        }

        if let analysisError = error as? AnalysisError {
            return analysisError
        }

        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .guardrailViolation:
                return .analysisFailure("콘텐츠 안전 필터에 의해 분석이 차단되었습니다.")
            case .assetsUnavailable, .decodingFailure:
                return .modelNotReady
            case .unsupportedLanguageOrLocale:
                return .analysisFailure("현재 언어 설정에서 Apple Intelligence 분석을 사용할 수 없습니다.")
            case .rateLimited:
                return .analysisFailure("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.")
            case .concurrentRequests:
                return .analysisFailure("이전 분석이 아직 진행 중입니다. 잠시 후 다시 시도해주세요.")
            case .exceededContextWindowSize:
                return .analysisFailure("입력 데이터가 너무 큽니다.")
            case .unsupportedGuide:
                return .modelNotReady
            case .refusal:
                return .analysisFailure("AI가 분석을 거부했습니다.")
            @unknown default:
                return .modelNotReady
            }
        }

        let message = error.localizedDescription.lowercased()
        if message.contains("thoughtcontents")
            || message.contains("espresso")
            || message.contains("safety")
            || message.contains("sanitize")
            || message.contains("model manager")
            || message.contains("decoding") {
            return .modelNotReady
        }

        return .modelNotReady
    }

    private let defaultSystemPrompt = """
    You are an expert fish freshness analyst helping shoppers assess food quality.
    Evaluate fish freshness from image analysis data and return a structured assessment.
    Always attempt analysis even with limited information. Write summary in Korean. Never refuse.
    """
}

// MARK: - Errors

enum AnalysisError: LocalizedError {
    case modelUnavailable
    case modelNotReady
    case appleIntelligenceDisabled
    case deviceNotEligible
    case aiResponseInvalid
    case analysisFailure(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence를 사용할 수 없습니다."
        case .modelNotReady:
            return "Apple Intelligence 모델을 불러오지 못했습니다. 사진 문제가 아니라 기기의 AI 모델 상태를 확인해주세요."
        case .appleIntelligenceDisabled:
            return "Apple Intelligence가 비활성화되어 있습니다."
        case .deviceNotEligible:
            return "이 기기는 Apple Intelligence를 지원하지 않습니다."
        case .aiResponseInvalid:
            return "AI 분석 응답을 처리하지 못했습니다. Apple Intelligence 모델 상태를 확인해주세요."
        case .analysisFailure(let reason):
            return reason
        case .saveFailed(let reason):
            return "분석 결과 저장 실패: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .modelUnavailable, .appleIntelligenceDisabled:
            return "설정 > Apple Intelligence & Siri 에서 활성화하세요."
        case .modelNotReady, .aiResponseInvalid:
            return "Wi-Fi 연결 후 Apple Intelligence 모델 다운로드가 완료됐는지 확인하고, 앱을 재시작한 뒤 다시 시도해주세요."
        case .deviceNotEligible:
            return "iPhone 15 Pro 이상 또는 Apple Intelligence 지원 기기가 필요합니다."
        case .analysisFailure(let reason):
            if reason.contains("차단") || reason.contains("거부") {
                return "다른 사진으로 다시 시도해보세요."
            }
            return "잠시 후 다시 시도해주세요."
        case .saveFailed:
            return "저장 공간을 확인한 뒤 다시 시도해주세요."
        }
    }

    var userFacingMessage: String {
        guard let suggestion = recoverySuggestion else {
            return errorDescription ?? "분석에 실패했습니다."
        }
        return "\(errorDescription ?? "분석에 실패했습니다.")\n\n\(suggestion)"
    }
}
