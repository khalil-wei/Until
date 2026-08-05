import WidgetKit
import Foundation

struct CountdownWidgetEntry: TimelineEntry {
    let date: Date
    let events: [CountdownEvent]
    let theme: CountdownWidgetTheme
}
