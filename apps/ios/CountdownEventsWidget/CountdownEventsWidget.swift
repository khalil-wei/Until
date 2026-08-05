import WidgetKit
import SwiftUI

struct CountdownEventsWidget: Widget {
    let kind = "CountdownEventsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CountdownWidgetConfigurationIntent.self,
            provider: CountdownWidgetProvider()
        ) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "widget.display_name"))
        .description(String(localized: "widget.description"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct CountdownEventsWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownEventsWidget()
    }
}
