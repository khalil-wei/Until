import EventKit
import Foundation
import UIKit

@MainActor
final class CalendarService: ObservableObject {

    private let store = EKEventStore()
    @Published private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        let status = (try? await store.requestFullAccessToEvents()) ?? false
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        return status
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Fetch

    /// Fetches birthday and anniversary events from Calendar and maps them
    /// to CountdownEvent with their next annual occurrence date.
    func fetchCountdownEvents() async -> [CountdownEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .year, value: 2, to: start) else { return [] }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        return await Task.detached(priority: .userInitiated) {
            let store = EKEventStore()
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            let ekEvents = store.events(matching: predicate)
            var closestEventsByKey: [String: CountdownEvent] = [:]

            for event in ekEvents {
                guard let recurrence = Self.detectRecurrence(for: event) else { continue }
                let happensToday = Self.event(event, intersectsStart: start, end: tomorrow)
                guard let category = Self.detectCategory(for: event) ?? (happensToday ? .custom : nil) else {
                    continue
                }

                let key = Self.deduplicationKey(for: event, category: category)
                let nextDate = happensToday ? start : Calendar.current.startOfDay(for: event.startDate)
                let dateCalendar = Self.detectDateCalendar(for: event)
                let metadataDate = Self.metadataValue("originalDate", for: event).flatMap(Double.init)
                    .flatMap { $0.isFinite ? Date(timeIntervalSince1970: $0) : nil }
                let originalDate = CalendarImportRules.validatedAnchor(
                    metadataDate: metadataDate,
                    metadataRecurrence: Self.metadataValue("recurrence", for: event).flatMap(EventRecurrence.init(rawValue:)),
                    sourceOccurrence: event.startDate, dateCalendar: dateCalendar,
                    recurrence: recurrence, referenceDate: start, calendar: calendar
                )
                let ce = CountdownEvent(
                    title: event.title ?? String(localized: "event.unnamed"),
                    nextOccurrence: nextDate,
                    originalDate: originalDate,
                    category: category,
                    dateCalendar: dateCalendar,
                    recurrence: recurrence,
                    source: Self.detectSource(for: event),
                    calendarEventID: event.eventIdentifier,
                    calendarItemID: event.calendarItemIdentifier,
                    notes: event.notes
                )

                if let existing = closestEventsByKey[key], existing.nextOccurrence <= ce.nextOccurrence {
                    continue
                }
                closestEventsByKey[key] = ce
            }
            return Array(closestEventsByKey.values)
        }.value
    }

    // MARK: - Create

    /// Creates a recurring yearly EKEvent and returns the new event identifier.
    func createEvent(title: String, date: Date, recurrence: EventRecurrence = .yearly, category: EventCategory, notes: String?) async throws -> String {
        let event = EKEvent(eventStore: store)
        configure(event, title: title, date: date, recurrence: recurrence, category: category, notes: notes)
        event.calendar = countdownCalendar()

        try store.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier
    }

    /// Updates an existing yearly EKEvent. If the backing event no longer exists,
    /// a replacement event is created and its identifier is returned.
    func updateEvent(
        identifier: String,
        title: String,
        date: Date,
        recurrence: EventRecurrence = .yearly,
        category: EventCategory,
        notes: String?
    ) async throws -> String {
        guard let event = store.event(withIdentifier: identifier) else {
            return try await createEvent(title: title, date: date, recurrence: recurrence, category: category, notes: notes)
        }

        configure(event, title: title, date: date, recurrence: recurrence, category: category, notes: notes)
        try store.save(event, span: .futureEvents, commit: true)
        return event.eventIdentifier
    }

    // MARK: - Delete

    func deleteEvent(identifier: String) throws {
        guard let event = store.event(withIdentifier: identifier) else { return }
        try store.remove(event, span: .futureEvents, commit: true)
    }

    // MARK: - Helpers

    private func countdownCalendar() -> EKCalendar {
        let calTitle = String(localized: "calendar.countdown_reminders")
        let knownTitles = [calTitle, "待到提醒", "Until Reminders", "倒计时提醒", "Countdown Reminders"]
        if let existing = store.calendars(for: .event).first(where: { knownTitles.contains($0.title) }) {
            return existing
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calTitle
        cal.cgColor = UIColor.systemPink.cgColor
        if let source = store.defaultCalendarForNewEvents?.source {
            cal.source = source
        }
        try? store.saveCalendar(cal, commit: true)
        return cal
    }

    nonisolated private static func detectCategory(for event: EKEvent) -> EventCategory? {
        if let category = metadataValue("category", for: event).flatMap(EventCategory.init(rawValue:)) {
            return category
        }

        let title = (event.title ?? "").lowercased()
        let calName = (event.calendar?.title ?? "").lowercased()

        let birthdayKeywords = ["birthday", "生日", "birthdays"]
        let anniversaryKeywords = ["anniversary", "纪念日", "anniversaries"]

        if birthdayKeywords.contains(where: { title.contains($0) || calName.contains($0) }) {
            return .birthday
        }
        if anniversaryKeywords.contains(where: { title.contains($0) || calName.contains($0) }) {
            return .anniversary
        }
        // Include events in "Birthdays" system calendar
        if calName.contains("birthday") || calName.contains("生日") {
            return .birthday
        }
        if isCountdownCalendarTitle(calName) {
            return .custom
        }
        return nil
    }

    nonisolated private static func event(_ event: EKEvent, intersectsStart start: Date, end: Date) -> Bool {
        event.startDate < end && event.endDate > start
    }

    nonisolated private static func detectDateCalendar(for event: EKEvent) -> EventDateCalendar {
        if let metadataCalendar = metadataValue("dateCalendar", for: event)
            .flatMap({ EventDateCalendar(rawValue: $0) }) {
            return metadataCalendar
        }

        let title = (event.title ?? "").lowercased()
        let calName = (event.calendar?.title ?? "").lowercased()
        if isLunarAnnualEventText(title) || isLunarAnnualEventText(calName) {
            return .lunar
        }

        if event.recurrenceRules?.contains(where: { $0.calendarIdentifier == "chinese" }) == true {
            return .lunar
        }

        return .gregorian
    }

    nonisolated private static func detectSource(for event: EKEvent) -> EventSource {
        let calName = (event.calendar?.title ?? "").lowercased()
        if metadataValue("category", for: event) != nil || isCountdownCalendarTitle(calName) {
            return .appCalendar
        }
        return .importedCalendar
    }

    nonisolated private static func deduplicationKey(for event: EKEvent, category: EventCategory) -> String {
        if !event.calendarItemIdentifier.isEmpty {
            return "calendar-item:\(event.calendarItemIdentifier)"
        }

        let title = (event.title ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let calendarTitle = (event.calendar?.title ?? "").lowercased()
        return "fallback:\(category.rawValue):\(calendarTitle):\(title)"
    }

    nonisolated private static func metadataURL(
        category: EventCategory,
        dateCalendar: EventDateCalendar,
        recurrence: EventRecurrence,
        originalDate: Date
    ) -> URL? {
        URL(string: "until://countdown-event?category=\(category.rawValue)&dateCalendar=\(dateCalendar.rawValue)&recurrence=\(recurrence.rawValue)&originalDate=\(originalDate.timeIntervalSince1970)")
    }

    /// Only import schedules the local model can reproduce without losing rules.
    nonisolated private static func detectRecurrence(for event: EKEvent) -> EventRecurrence? {
        let rules = event.recurrenceRules ?? []
        // Keep the existing annual interpretation of non-recurring imports.
        if rules.isEmpty { return .yearly }
        guard rules.count == 1, let rule = rules.first,
              !event.isDetached, rule.interval == 1, rule.recurrenceEnd == nil,
              (rule.daysOfTheYear ?? []).isEmpty,
              (rule.weeksOfTheYear ?? []).isEmpty,
              (rule.setPositions ?? []).isEmpty else { return nil }
        let calendar = detectDateCalendar(for: event).foundationCalendar
        let day = calendar.component(.day, from: event.startDate)
        let month = calendar.component(.month, from: event.startDate)
        let monthDays = rule.daysOfTheMonth ?? []
        let months = rule.monthsOfTheYear ?? []
        let weekDays = rule.daysOfTheWeek ?? []
        if !monthDays.isEmpty && (monthDays.count != 1 || monthDays.first?.intValue != day) { return nil }
        if !months.isEmpty && (months.count != 1 || months.first?.intValue != month) { return nil }
        switch rule.frequency {
        case .yearly:
            return weekDays.isEmpty ? .yearly : nil
        case .monthly:
            return weekDays.isEmpty && months.isEmpty ? .monthly : nil
        case .weekly:
            guard monthDays.isEmpty, months.isEmpty else { return nil }
            if let weekday = weekDays.first {
                guard weekDays.count == 1, weekday.weekNumber == 0,
                      weekday.dayOfTheWeek.rawValue == Calendar.current.component(.weekday, from: event.startDate) else { return nil }
            }
            return .weekly
        default: return nil
        }
    }

    nonisolated private static func metadataValue(_ name: String, for event: EKEvent) -> String? {
        guard let url = event.url,
              url.scheme == "until",
              url.host == "countdown-event",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        return components.queryItems?.first(where: { $0.name == name })?.value
    }

    nonisolated private static func isLunarAnnualEventText(_ text: String) -> Bool {
        EventTextClassifier.looksLikeLunarAnnualEvent(text)
    }

    nonisolated private static func isCountdownCalendarTitle(_ title: String) -> Bool {
        ["待到提醒", "until reminders", "倒计时提醒", "countdown reminders"].contains(title)
    }

    /// Given any date, return the next upcoming same month/day occurrence.
    nonisolated static func nextAnnualOccurrence(
        from date: Date,
        dateCalendar: EventDateCalendar = .gregorian
    ) -> Date {
        CountdownEvent.nextAnnualOccurrence(from: date, dateCalendar: dateCalendar)
    }

    private func configure(_ event: EKEvent, title: String, date: Date, recurrence: EventRecurrence, category: EventCategory, notes: String?) {
        let day = Calendar.current.startOfDay(for: date)
        event.title = title
        event.notes = notes
        event.url = Self.metadataURL(category: category, dateCalendar: .gregorian, recurrence: recurrence, originalDate: day)
        event.isAllDay = true
        event.startDate = day
        event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day

        let frequency: EKRecurrenceFrequency = recurrence == .weekly ? .weekly : recurrence == .monthly ? .monthly : .yearly
        let rule = EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: 1,
            end: nil
        )
        event.recurrenceRules = [rule]
    }
}
