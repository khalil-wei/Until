import AppIntents
import Foundation

enum CountdownWidgetTheme: String, AppEnum, Codable, Sendable {
    case colorful
    case minimal
    case midnight

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("widget.theme.title")
    )

    static var caseDisplayRepresentations: [CountdownWidgetTheme: DisplayRepresentation] = [
        .colorful: DisplayRepresentation(title: LocalizedStringResource("widget.theme.colorful")),
        .minimal: DisplayRepresentation(title: LocalizedStringResource("widget.theme.minimal")),
        .midnight: DisplayRepresentation(title: LocalizedStringResource("widget.theme.midnight"))
    ]
}

struct CountdownWidgetEventEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("widget.event.title")
    )
    static var defaultQuery = CountdownWidgetEventQuery()

    let id: String
    let title: String
    let categoryName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(categoryName)"
        )
    }

    init(event: CountdownEvent) {
        id = event.id.uuidString
        title = event.title
        categoryName = event.category.displayName
    }
}

struct CountdownWidgetEventQuery: EntityQuery {
    func entities(for identifiers: [CountdownWidgetEventEntity.ID]) async throws -> [CountdownWidgetEventEntity] {
        let identifierSet = Set(identifiers)
        return activeEvents
            .filter { identifierSet.contains($0.id.uuidString) }
            .map(CountdownWidgetEventEntity.init)
    }

    func suggestedEntities() async throws -> [CountdownWidgetEventEntity] {
        activeEvents.map(CountdownWidgetEventEntity.init)
    }

    private var activeEvents: [CountdownEvent] {
        SharedDataService.load()
            .filter { !$0.isIgnored }
            .sorted { $0.daysUntil < $1.daysUntil }
    }
}

struct CountdownWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.configuration.title"
    static var description = IntentDescription("widget.configuration.description")

    @Parameter(title: "widget.configuration.event")
    var event: CountdownWidgetEventEntity?

    @Parameter(title: "widget.configuration.theme", default: .colorful)
    var theme: CountdownWidgetTheme

    init() {}

    init(event: CountdownWidgetEventEntity? = nil, theme: CountdownWidgetTheme = .colorful) {
        self.event = event
        self.theme = theme
    }
}
