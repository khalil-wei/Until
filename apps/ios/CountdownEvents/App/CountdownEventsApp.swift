import SwiftUI

@main
struct CountdownEventsApp: App {
    @StateObject private var viewModel = EventListViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
