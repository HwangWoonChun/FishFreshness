import SwiftUI
import SwiftData

struct ResultView: View {

    let result: FreshnessAnalysisResult
    let image: UIImage?
    var record: FishScanRecord?
    var onReanalyze: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroCard
                    indicatorsCard
                    recommendationCard
                    summaryCard
                    actionButtons
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(result.fishSpecies == "Unknown" ? "신선도 분석 결과" : result.fishSpecies)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 16) {
            // Image
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Score + Grade
            HStack(spacing: 24) {
                ScoreGaugeView(score: result.overallScore, grade: result.grade, size: 120)

                VStack(alignment: .leading, spacing: 10) {
                    GradeTagView(grade: result.grade)

                    if result.fishSpecies != "Unknown" {
                        Label(result.fishSpecies, systemImage: "fish")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text(result.grade.safetyLevel)
                        .font(.caption)
                        .foregroundStyle(result.grade.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.grade.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .padding(.bottom, 12)
    }

    // MARK: - Indicators Card

    private var indicatorsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(title: "지표별 상태", icon: "chart.bar.fill")

            VStack(spacing: 0) {
                ForEach(Array(result.allIndicators.enumerated()), id: \.offset) { index, item in
                    IndicatorRowView(
                        icon: item.systemImage,
                        title: item.title,
                        status: item.status
                    )
                    if index < result.allIndicators.count - 1 {
                        Divider().padding(.leading, 42)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, 12)
    }

    // MARK: - Recommendation Card

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(title: "추천 조리법", icon: "fork.knife")

            VStack(alignment: .leading, spacing: 12) {
                // Cooking recommendation
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(result.cookingRecommendation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                // Safety advice
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(result.grade.color)
                        .frame(width: 24)
                    Text(result.safetyAdvice)
                        .font(.subheadline)
                        .foregroundStyle(result.grade == .spoiled || result.grade == .caution ? result.grade.color : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, 12)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader(title: "AI 종합 분석", icon: "sparkles")

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, 12)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
                onReanalyze?()
            } label: {
                Label("다시 분석", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.bordered)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("저장됨")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
    }
}

#Preview {
    let sampleResult = FreshnessAnalysisResult(
        fishSpecies: "고등어",
        overallScore: 4,
        grade: .good,
        eyeCondition: IndicatorStatus(level: .fresh, observation: "눈이 맑고 투명합니다."),
        gillCondition: IndicatorStatus(level: .fresh, observation: "아가미가 선명한 빨간색입니다."),
        scaleCondition: IndicatorStatus(level: .acceptable, observation: "비늘이 대체로 붙어있습니다."),
        fleshCondition: IndicatorStatus(level: .fresh, observation: "살이 탄탄하고 탄력이 있습니다."),
        colorCondition: IndicatorStatus(level: .fresh, observation: "선명한 은빛 광택이 납니다."),
        cookingRecommendation: "구이, 조림, 찌개 모두 가능. 회로도 드실 수 있습니다.",
        safetyAdvice: "신선한 상태로 안전하게 드실 수 있습니다.",
        summary: "전반적으로 신선한 고등어입니다. 눈과 아가미 상태가 좋고 살의 탄력도 양호합니다."
    )

    ResultView(result: sampleResult, image: nil)
}
