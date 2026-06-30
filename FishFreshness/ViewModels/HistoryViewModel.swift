import SwiftData
import SwiftUI
import Observation

@Observable
@MainActor
final class HistoryViewModel {

    var selectedRecord: FishScanRecord?

    func selectRecord(_ record: FishScanRecord) {
        selectedRecord = record
    }

    func deleteRecords(_ records: [FishScanRecord], context: ModelContext) {
        records.forEach { context.delete($0) }
        try? context.save()
    }

    func deleteRecord(_ record: FishScanRecord, context: ModelContext) {
        context.delete(record)
        try? context.save()
    }
}
