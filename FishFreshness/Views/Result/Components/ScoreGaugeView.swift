import SwiftUI

struct ScoreGaugeView: View {

    let score: Int          // 1–5
    let grade: FreshnessGrade
    var size: CGFloat = 140

    private var progress: Double { Double(score) / 5.0 }
    private var strokeWidth: CGFloat { size * 0.09 }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(90))

            // Progress
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * progress)
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, grade.color],
                        center: .center,
                        startAngle: .degrees(45),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .animation(.spring(duration: 1.0), value: score)

            // Center content
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(grade.color)
                Text("/ 5")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("신선도 점수 \(score)점 / 5점")
    }
}

#Preview {
    HStack(spacing: 24) {
        ScoreGaugeView(score: 5, grade: .excellent)
        ScoreGaugeView(score: 3, grade: .acceptable)
        ScoreGaugeView(score: 1, grade: .spoiled)
    }
    .padding()
}
