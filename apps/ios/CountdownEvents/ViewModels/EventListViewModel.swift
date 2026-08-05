import Foundation
import EventKit
import UserNotifications
import WidgetKit

@MainActor
final class EventListViewModel: ObservableObject {

    @Published private(set) var events: [CountdownEvent] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private let calendarService = CalendarService()
    @Published private var ignoredEvents: [CountdownEvent] = []

    var canRestoreIgnoredImportedEvents: Bool {
        ignoredEvents.contains { $0.source == .importedCalendar }
    }

    // MARK: - Lifecycle

    func onAppear() async {
        calendarService.refreshAuthorizationStatus()
        authorizationStatus = calendarService.authorizationStatus

        if authorizationStatus == .notDetermined {
            let granted = await calendarService.requestAccess()
            authorizationStatus = calendarService.authorizationStatus
            if granted {
                await loadEvents()
            } else {
                loadLocalEvents()
            }
        } else if authorizationStatus == .fullAccess {
            await loadEvents()
        } else {
            loadLocalEvents()
        }
    }

    // MARK: - Load

    func refresh() async {
        if authorizationStatus == .fullAccess {
            await loadEvents()
        } else {
            loadLocalEvents()
        }
    }

    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        let storedEvents = SharedDataService.load()
        ignoredEvents = storedEvents.filter(\.isIgnored)
        let fromCalendar = await calendarService.fetchCountdownEvents()
            .map { $0.preservingUserSettings(from: storedEvents) }
            .filter { calendarEvent in
                !ignoredEvents.contains(where: { $0.matchesCalendarIdentity(of: calendarEvent) })
            }
            .uniquedForDisplay()
        let fromLocal = storedEvents.filter {
            !$0.isIgnored && $0.source == .local
        }

        // Merge: calendar events take priority; local-only events appended.
        var merged = fromCalendar
        for local in fromLocal {
            if !merged.contains(where: { $0.matchesSameAnnualEvent(as: local) }) {
                merged.append(local)
            }
        }

        events = merged.sorted { $0.daysUntil < $1.daysUntil }
        persist()
    }

    func loadLocalEvents() {
        let storedEvents = SharedDataService.load()
        ignoredEvents = storedEvents.filter(\.isIgnored)
        events = storedEvents
            .filter { !$0.isIgnored && $0.source != .importedCalendar }
            .sorted { $0.daysUntil < $1.daysUntil }
        Task {
            await NotificationService.rescheduleNotifications(for: storedEvents)
        }
    }

    // MARK: - Add

    func addEvent(
        title: String,
        date: Date,
        category: EventCategory,
        dateCalendar: EventDateCalendar = .gregorian,
        notes: String?,
        reminderLeadTime: ReminderLeadTime = .none
    ) async {
        do {
            let identifier = try await calendarService.createEvent(
                title: title,
                date: date,
                category: category,
                notes: notes
            )
            let nextDate = CalendarService.nextAnnualOccurrence(from: date, dateCalendar: dateCalendar)
            let event = CountdownEvent(
                title: title,
                nextOccurrence: nextDate,
                originalDate: date,
                category: category,
                dateCalendar: dateCalendar,
                source: .appCalendar,
                calendarEventID: identifier,
                notes: notes,
                reminderLeadTime: reminderLeadTime
            )
            events.append(event)
            events.sort { $0.daysUntil < $1.daysUntil }
            persist()
        } catch {
            errorMessage = String.localizedStringWithFormat(
                String(localized: "error.create_event_failed"),
                error.localizedDescription
            )
        }
    }

    /// Add an event locally (without writing to Calendar — useful if access denied)
    func addLocalEvent(
        title: String,
        date: Date,
        category: EventCategory,
        dateCalendar: EventDateCalendar = .gregorian,
        notes: String?,
        reminderLeadTime: ReminderLeadTime = .none
    ) {
        let nextDate = CalendarService.nextAnnualOccurrence(from: date, dateCalendar: dateCalendar)
        let event = CountdownEvent(
            title: title,
            nextOccurrence: nextDate,
            originalDate: date,
            category: category,
            dateCalendar: dateCalendar,
            calendarEventID: nil,
            notes: notes,
            reminderLeadTime: reminderLeadTime
        )
        events.append(event)
        events.sort { $0.daysUntil < $1.daysUntil }
        persist()
    }

    // MARK: - Edit

    func updateEvent(
        _ event: CountdownEvent,
        title: String,
        date: Date,
        category: EventCategory,
        dateCalendar: EventDateCalendar,
        syncToCalendar: Bool,
        notes: String?,
        reminderLeadTime: ReminderLeadTime
    ) async {
        let shouldSync = syncToCalendar && authorizationStatus == .fullAccess && dateCalendar == .gregorian
        var calendarEventID: String?
        var source: EventSource = shouldSync
            ? (event.source == .importedCalendar ? .importedCalendar : .appCalendar)
            : .local

        do {
            if shouldSync {
                if let existingID = event.calendarEventID {
                    calendarEventID = try await calendarService.updateEvent(
                        identifier: existingID,
                        title: title,
                        date: date,
                        category: category,
                        notes: notes
                    )
                } else {
                    calendarEventID = try await calendarService.createEvent(
                        title: title,
                        date: date,
                        category: category,
                        notes: notes
                    )
                }
            } else if let existingID = event.calendarEventID, event.source == .appCalendar {
                try? calendarService.deleteEvent(identifier: existingID)
            } else if event.source == .importedCalendar {
                rememberIgnoredEvent(event)
                calendarEventID = nil
                source = .local
            }

            let nextDate = CalendarService.nextAnnualOccurrence(from: date, dateCalendar: dateCalendar)
            let updatedEvent = CountdownEvent(
                id: event.id,
                title: title,
                nextOccurrence: nextDate,
                originalDate: date,
                category: category,
                dateCalendar: dateCalendar,
                source: source,
                calendarEventID: calendarEventID,
                notes: notes,
                reminderLeadTime: reminderLeadTime
            )

            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = updatedEvent
            } else {
                events.append(updatedEvent)
            }
            events.sort { $0.daysUntil < $1.daysUntil }
            persist()
        } catch {
            errorMessage = String.localizedStringWithFormat(
                String(localized: "error.update_event_failed"),
                error.localizedDescription
            )
        }
    }

    // MARK: - Delete

    func deleteEvent(_ event: CountdownEvent) {
        if event.source == .importedCalendar {
            ignoreImportedEvent(event)
            return
        }

        if let id = event.calendarEventID, event.source == .appCalendar {
            try? calendarService.deleteEvent(identifier: id)
        }
        NotificationService.cancelNotifications(for: [event])
        events.removeAll { $0.id == event.id }
        persist()
    }

    func deleteEvents(_ eventsToDelete: [CountdownEvent]) {
        eventsToDelete.forEach { deleteEvent($0) }
    }

    func ignoreImportedEvent(_ event: CountdownEvent) {
        guard event.source == .importedCalendar else {
            deleteEvent(event)
            return
        }

        rememberIgnoredEvent(event)
        events.removeAll { $0.id == event.id }
        persist()
    }

    func restoreIgnoredImportedEvents() async {
        ignoredEvents.removeAll { $0.source == .importedCalendar }
        persist()
        await refresh()
    }

    func deleteImportedEventFromCalendar(_ event: CountdownEvent) {
        deleteCalendarBackedEvent(event)
    }

    func deleteCalendarBackedEvent(_ event: CountdownEvent) {
        guard event.source == .importedCalendar || event.source == .appCalendar else {
            deleteEvent(event)
            return
        }

        do {
            if let id = event.calendarEventID {
                try calendarService.deleteEvent(identifier: id)
            }
        } catch {
            errorMessage = String.localizedStringWithFormat(
                String(localized: "error.delete_event_failed"),
                error.localizedDescription
            )
            return
        }

        NotificationService.cancelNotifications(for: [event])
        events.removeAll { $0.id == event.id }
        if event.source == .importedCalendar {
            ignoredEvents.removeAll { $0.matchesCalendarIdentity(of: event) }
        }
        persist()
    }

    // MARK: - Persist

    private func persist() {
        let storedEvents = events + ignoredEvents
        SharedDataService.save(storedEvents)
        WidgetCenter.shared.reloadTimelines(ofKind: "CountdownEventsWidget")
        Task {
            await NotificationService.rescheduleNotifications(for: storedEvents)
        }
    }

    private func rememberIgnoredEvent(_ event: CountdownEvent) {
        var ignored = event
        ignored.isIgnored = true
        if !ignoredEvents.contains(where: { $0.matchesCalendarIdentity(of: ignored) }) {
            ignoredEvents.append(ignored)
        }
    }
}

private enum NotificationService {
    static func rescheduleNotifications(for events: [CountdownEvent]) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = events.map(\.notificationIdentifier)

        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }

        let activeReminderEvents = events.filter {
            !$0.isIgnored && $0.reminderLeadTime != .none
        }

        guard !activeReminderEvents.isEmpty, await ensureAuthorization() else {
            return
        }

        for event in activeReminderEvents {
            await scheduleNotification(for: event)
        }
    }

    static func cancelNotifications(for events: [CountdownEvent]) {
        let identifiers = events.map(\.notificationIdentifier)
        guard !identifiers.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private static func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await notificationSettings(center: center)

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func notificationSettings(center: UNUserNotificationCenter) async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private static func scheduleNotification(for event: CountdownEvent) async {
        guard
            let reminderDate = reminderDate(for: event),
            reminderDate > Date()
        else {
            return
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.title")
        content.body = String.localizedStringWithFormat(
            NSLocalizedString("notification.body", comment: "Local notification body for an upcoming event"),
            event.title,
            event.countdownLabel
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: event.notificationIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func reminderDate(for event: CountdownEvent) -> Date? {
        guard event.reminderLeadTime != .none else { return nil }

        let calendar = Calendar.current
        let eventDay = calendar.startOfDay(for: event.nextOccurrence)
        guard let reminderDay = calendar.date(
            byAdding: .day,
            value: -event.reminderLeadTime.rawValue,
            to: eventDay
        ) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDay)
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components)
    }
}

private extension CountdownEvent {
    func preservingUserSettings(from storedEvents: [CountdownEvent]) -> CountdownEvent {
        guard
            let storedEvent = storedEvents.first(where: {
                !$0.isIgnored && $0.matchesCalendarIdentity(of: self)
            })
        else {
            return self
        }

        return CountdownEvent(
            id: storedEvent.id,
            title: title,
            nextOccurrence: nextOccurrence,
            originalDate: originalDate,
            category: category,
            dateCalendar: dateCalendar,
            source: source,
            isIgnored: isIgnored,
            calendarEventID: calendarEventID,
            calendarItemID: calendarItemID,
            notes: notes,
            reminderLeadTime: storedEvent.reminderLeadTime
        )
    }

    func matchesCalendarIdentity(of other: CountdownEvent) -> Bool {
        if let calendarItemID, let otherCalendarItemID = other.calendarItemID {
            return calendarItemID == otherCalendarItemID || matchesSameAnnualEvent(as: other)
        }

        if let calendarEventID, let otherCalendarEventID = other.calendarEventID {
            return calendarEventID == otherCalendarEventID || matchesSameAnnualEvent(as: other)
        }

        return matchesSameAnnualEvent(as: other)
    }
}

private extension Array where Element == CountdownEvent {
    func uniquedForDisplay() -> [CountdownEvent] {
        reduce(into: []) { uniqueEvents, event in
            guard let existingIndex = uniqueEvents.firstIndex(where: { $0.matchesSameAnnualEvent(as: event) }) else {
                uniqueEvents.append(event)
                return
            }

            if event.preferredDisplayRank < uniqueEvents[existingIndex].preferredDisplayRank {
                uniqueEvents[existingIndex] = event
            }
        }
    }
}

private extension CountdownEvent {
    var preferredDisplayRank: Int {
        switch source {
        case .appCalendar: return 0
        case .local: return 1
        case .importedCalendar: return 2
        }
    }
}
