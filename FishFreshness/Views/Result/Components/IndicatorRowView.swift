import SwiftUI

struct IndicatorRowView: View {

    let icon: String
    let title: String
    let status: IndicatorStatus

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(status.level.color)
                .frame(width: 28, height: 28)
                .background(status.level.color.opacity(0.12), in: Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: status.level.systemImage)
                            .font(.caption.bold())
                            .foregroundStyle(status.level.color)
                        Text(status.level.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(status.level.color)
                    }
                }

                Text(status.observation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(status.level.displayName). \(status.observation)")
    }
}

#Preview {
    VStack(spacing: 12) {
        IndicatorRowView(
            icon: "eye",
            title: "눈 상태",
            status: IndicatorStatus(
                level: .fresh,
                observation: "눈이 맑고 투명하며 볼록하게 돌출되어 있습니다."
            )
        )
        IndicatorRowView(
            icon: "drop.fill",
            title: "아가미 색",
            status: IndicatorStatus(
                level: .acceptable,
                observation: "아가미 색이 약간 어두워졌지만 아직 허용 범위입니다."
            )
        )
        IndicatorRowView(
            icon: "shield.lefthalf.filled",
            title: "비늘 상태",
            status: IndicatorStatus(
                level: .poor,
                observation: "비늘이 많이 떨어져 있고 광택이 사라졌습니다."
            )
        )
    }
    .padding()
}
