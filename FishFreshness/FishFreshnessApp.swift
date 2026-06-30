//
//  FishFreshnessApp.swift
//  FishFreshness
//
//  Created by lotte on 6/30/26.
//

import SwiftUI
import SwiftData

@main
struct FishFreshnessApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FishScanRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
