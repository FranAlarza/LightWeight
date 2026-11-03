import SwiftUI

@main
struct LightWeightApp: App {
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                // Load the catalog at launch so "add exercise" opens with results.
                .task { await dependencies.catalog.prefetch() }
        }
    }
}
