import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \FishScanRecord.timestamp, order: .reverse)
    private var records: [FishScanRecord]

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    recordsList
                }
            }
            .navigationTitle("분석 히스토리")
            .sheet(item: $viewModel.selectedRecord) { record in
                ResultView(
                    result: record.analysisResult,
                    image: record.thumbnailImage,
                    record: record
                )
            }
        }
    }

    // MARK: - Records List

    private var recordsList: some View {
        List {
            ForEach(records) { record in
                HistoryRowView(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectRecord(record)
                    }
            }
            .onDelete { indexSet in
                let toDelete = indexSet.map { records[$0] }
                viewModel.deleteRecords(toDelete, context: modelContext)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.quaternary)
            VStack(spacing: 8) {
                Text("아직 분석 기록이 없어요")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("생선 사진을 촬영하면\n분석 기록이 여기에 쌓입니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: FishScanRecord.self, inMemory: true)
}
