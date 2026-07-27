//
//  UmbraApp.swift
//  Umbra
//
//  App entry point. SwiftUI lifecycle + SwiftData container. Fully local: the
//  model container is an on-device store with no CloudKit, no sync.
//

import SwiftUI
import SwiftData

@main
struct UmbraApp: App {

    /// Local-only SwiftData container. If the store fails to open (e.g. a
    /// migration problem), fall back to an in-memory store so the app still
    /// launches rather than crashing on the user.
    let container: ModelContainer

    init() {
        let schema = Schema([ARProject.self, PlacedBlocker.self, AppSettings.self])
        // UI tests pass `-UITestReset` so every run starts from a clean,
        // in-memory store (fresh onboarding, no projects) instead of whatever
        // state a prior run or a developer's own simulator session left
        // behind. This has no effect outside of XCUITest launches.
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Defensive fallback: never block launch on a persistence error.
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            container = try! ModelContainer(for: schema, configurations: [memory])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
