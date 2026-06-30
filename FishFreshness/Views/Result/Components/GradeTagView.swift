import SwiftUI

struct GradeTagView: View {

    let grade: FreshnessGrade
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Circle()
                .fill(grade.color)
                .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
            Text(grade.displayName)
                .font(compact ? .caption.bold() : .subheadline.bold())
                .foregroundStyle(grade.color)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(grade.color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(grade.color.opacity(0.3), lineWidth: 1))
        .accessibilityLabel("등급: \(grade.displayName)")
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(FreshnessGrade.allCases, id: \.self) { grade in
            HStack {
                GradeTagView(grade: grade)
                GradeTagView(grade: grade, compact: true)
            }
        }
    }
    .padding()
}
