import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var viewModel: EventListViewModel
    @State private var deepLink: AppDeepLink?

    var body: some View {
        EventListView(deepLink: $deepLink)
            .task {
                await viewModel.onAppear()
            }
            .onOpenURL { url in
                deepLink = AppDeepLink(url: url)
            }
    }
}

enum AppDeepLink: Equatable {
    case add
    case event(UUID)

    init?(url: URL) {
        guard url.scheme == "until" else { return nil }

        switch url.host {
        case "add":
            self = .add
        case "event":
            guard
                let identifier = url.pathComponents.dropFirst().first,
                let id = UUID(uuidString: identifier)
            else { return nil }
            self = .event(id)
        default:
            return nil
        }
    }
}
