import SwiftUI
import SwiftData
import Observation

// MARK: - Analysis State Machine

enum AnalysisState {
    case preprocessing
    case analyzing
    case completed(FreshnessAnalysisResult)
    case failed(Error)

    var isLoading: Bool {
        switch self {
        case .preprocessing, .analyzing: return true
        default: return false
        }
    }

    var statusText: String {
        switch self {
        case .preprocessing: return "Vision 이미지 분석 중..."
        case .analyzing:     return "AI 신선도 평가 중..."
        case .completed:     return "분석 완료"
        case .failed:        return "분석 실패"
        }
    }
}

// MARK: - AnalysisViewModel

@Observable
@MainActor
final class AnalysisViewModel {

    let image: UIImage
    let fishHint: String?

    var state: AnalysisState = .preprocessing
    var savedRecord: FishScanRecord?

    private let service = FreshnessAnalysisService()
    private var analysisTask: Task<Void, Never>?

    init(image: UIImage, fishHint: String?) {
        self.image = image
        self.fishHint = fishHint
    }

    // MARK: - Analysis

    func startAnalysis(modelContext: ModelContext) {
        analysisTask?.cancel()
        savedRecord = nil
        state = .preprocessing

        analysisTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()

                state = .analyzing
                let result = try await service.analyze(image: image, fishHint: fishHint)
                try Task.checkCancellation()

                let record = result.toScanRecord(image: image, fishHint: fishHint)
                modelContext.insert(record)
                do {
                    try modelContext.save()
                } catch {
                    throw AnalysisError.saveFailed(error.localizedDescription)
                }

                savedRecord = record
                state = .completed(result)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                state = .failed(error)
            }
        }
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
    }

    // MARK: - Computed

    var completedResult: FreshnessAnalysisResult? {
        if case .completed(let result) = state { return result }
        return nil
    }

    var errorMessage: String? {
        if case .failed(let error) = state {
            if let analysisError = error as? AnalysisError {
                return analysisError.userFacingMessage
            }
            if let localized = error as? LocalizedError,
               let description = localized.errorDescription {
                if let suggestion = localized.recoverySuggestion {
                    return "\(description)\n\n\(suggestion)"
                }
                return description
            }
            return error.localizedDescription
        }
        return nil
    }
}
