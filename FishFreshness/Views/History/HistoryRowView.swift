import SwiftUI

struct HistoryRowView: View {

    let record: FishScanRecord

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            thumbnailView

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(record.fishSpecies == "Unknown" ? "어종 미상" : record.fishSpecies)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    GradeTagView(grade: record.grade, compact: true)
                }

                HStack(spacing: 8) {
                    Text(record.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Score dots
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= record.overallScore ? record.grade.color : Color(.systemFill))
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Text(record.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.fishSpecies), 점수 \(record.overallScore)점, \(record.grade.displayName), \(record.formattedDate)")
    }

    private var thumbnailView: some View {
        Group {
            if let image = record.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.systemFill)
                    .overlay {
                        Image(systemName: "fish.fill")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
