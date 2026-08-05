import WidgetKit
import Foundation

struct CountdownWidgetProvider: AppIntentTimelineProvider {

    typealias Entry = CountdownWidgetEntry
    typealias Intent = CountdownWidgetConfigurationIntent

    func placeholder(in context: Context) -> CountdownWidgetEntry {
        CountdownWidgetEntry(date: Date(), events: Self.placeholderEvents, theme: .colorful)
    }

    func snapshot(for configuration: CountdownWidgetConfigurationIntent, in context: Context) async -> CountdownWidgetEntry {
        let events = Self.configuredEvents(for: configuration)
        return CountdownWidgetEntry(
            date: Date(),
            events: events.isEmpty && context.isPreview ? Self.placeholderEvents : Array(events.prefix(8)),
            theme: configuration.theme
        )
    }

    func timeline(for configuration: CountdownWidgetConfigurationIntent, in context: Context) async -> Timeline<CountdownWidgetEntry> {
        let events = Self.configuredEvents(for: configuration)
        let entry = CountdownWidgetEntry(
            date: Date(),
            events: Array(events.prefix(8)),
            theme: configuration.theme
        )

        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    private static func configuredEvents(for configuration: CountdownWidgetConfigurationIntent) -> [CountdownEvent] {
        let events = SharedDataService.load()
            .filter { !$0.isIgnored }
            .sorted { $0.daysUntil < $1.daysUntil }

        guard
            let selectedID = configuration.event?.id,
            let selectedIndex = events.firstIndex(where: { $0.id.uuidString == selectedID })
        else {
            return events
        }

        var ordered = events
        let selected = ordered.remove(at: selectedIndex)
        ordered.insert(selected, at: 0)
        return ordered
    }

    // MARK: - Placeholder data

    static var placeholderEvents: [CountdownEvent] {
        let calendar = Calendar.current
        return [
            CountdownEvent(
                title: String(localized: "preview.mom_birthday"),
                nextOccurrence: calendar.date(byAdding: .day, value: 5, to: Date())!,
                originalDate: Date(),
                category: .birthday
            ),
            CountdownEvent(
                title: String(localized: "preview.wedding_anniversary"),
                nextOccurrence: calendar.date(byAdding: .day, value: 18, to: Date())!,
                originalDate: Date(),
                category: .anniversary
            ),
            CountdownEvent(
                title: String(localized: "preview.company_party"),
                nextOccurrence: calendar.date(byAdding: .day, value: 42, to: Date())!,
                originalDate: Date(),
                category: .custom
            )
        ]
    }
}
