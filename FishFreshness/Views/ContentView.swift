import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("분석", systemImage: "camera.fill") {
                HomeView()
            }
            Tab("히스토리", systemImage: "clock.fill") {
                HistoryView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FishScanRecord.self, inMemory: true)
}
