import Foundation

enum EventCategory: String, Codable, CaseIterable, Sendable {
    case birthday = "birthday"
    case anniversary = "anniversary"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .birthday: return String(localized: "category.birthday")
        case .anniversary: return String(localized: "category.anniversary")
        case .custom: return String(localized: "category.custom")
        }
    }

    var symbolName: String {
        switch self {
        case .birthday: return "birthday.cake"
        case .anniversary: return "heart.fill"
        case .custom: return "star.fill"
        }
    }
}

enum EventDateCalendar: String, Codable, CaseIterable, Sendable {
    case gregorian = "gregorian"
    case lunar = "lunar"

    var displayName: String {
        switch self {
        case .gregorian: return String(localized: "calendar.gregorian")
        case .lunar: return String(localized: "calendar.lunar")
        }
    }

    var foundationCalendar: Calendar {
        var calendar = Calendar(identifier: self == .gregorian ? .gregorian : .chinese)
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    static func formattedLunarMonthDay(from date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        if locale.identifier.lowercased().hasPrefix("zh") {
            var lunarCalendar = EventDateCalendar.lunar.foundationCalendar
            lunarCalendar.locale = locale
            let components = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)

            guard
                let month = components.month,
                let day = components.day,
                (1...12).contains(month),
                (1...30).contains(day)
            else {
                return fallbackLunarMonthDay(from: date, locale: locale)
            }

            let monthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
            let leapPrefix = components.isLeapMonth == true ? "闰" : ""
            return "\(leapPrefix)\(monthNames[month - 1])月\(formattedChineseLunarDay(day))"
        }

        return fallbackLunarMonthDay(from: date, locale: locale)
    }

    static func formattedMonthDay(
        from date: Date,
        dateCalendar: EventDateCalendar,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        guard dateCalendar == .lunar else {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
            return formatter.string(from: date)
        }

        return formattedLunarMonthDay(from: date, locale: locale)
    }

    static func formattedDisplayDate(
        from date: Date,
        dateCalendar: EventDateCalendar,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let gregorianDate = formattedMonthDay(from: date, dateCalendar: .gregorian, locale: locale)

        guard dateCalendar == .lunar else {
            return gregorianDate
        }

        return String.localizedStringWithFormat(
            NSLocalizedString("date.lunar_format", comment: "Lunar date followed by Gregorian date"),
            formattedLunarMonthDay(from: date, locale: locale),
            gregorianDate
        )
    }

    private static func formattedChineseLunarDay(_ day: Int) -> String {
        let numerals = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

        switch day {
        case 1...10:
            return "初\(numerals[day])"
        case 11...19:
            return "十\(numerals[day - 10])"
        case 20:
            return "二十"
        case 21...29:
            return "廿\(numerals[day - 20])"
        case 30:
            return "三十"
        default:
            return "\(day)"
        }
    }

    private static func fallbackLunarMonthDay(from date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = EventDateCalendar.lunar.foundationCalendar
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }
}

enum EventSource: String, Codable, Sendable {
    case local = "local"
    case appCalendar = "appCalendar"
    case importedCalendar = "importedCalendar"
}

enum CountdownSpecialNumber: Int, Equatable, Sendable {
    case answer = 42
    case orbit = 365
    case heart = 520

    static func match(daysUntil: Int, isChinese: Bool) -> CountdownSpecialNumber? {
        switch daysUntil {
        case answer.rawValue:
            return .answer
        case orbit.rawValue:
            return .orbit
        case heart.rawValue where isChinese:
            return .heart
        default:
            return nil
        }
    }
}

enum NightLetterPolicy {
    static let cooldown: TimeInterval = 30 * 24 * 60 * 60
    private static let cadenceInDays = 5

    static func shouldShow(
        now: Date,
        lastShownAt: Date?,
        hasEvents: Bool,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard hasEvents else { return false }

        let hour = calendar.component(.hour, from: now)
        guard (0..<5).contains(hour) else { return false }

        if let lastShownAt {
            let elapsed = now.timeIntervalSince(lastShownAt)
            guard elapsed >= cooldown else { return false }
        }

        guard let dayOrdinal = calendar.ordinality(of: .day, in: .era, for: now) else {
            return false
        }

        return dayOrdinal.isMultiple(of: cadenceInDays)
    }
}

enum CountdownEasterEggPolicy {
    static func canRevealDistantCountdown(daysUntil: Int) -> Bool {
        daysUntil > 999
    }

    static func canCelebrateArrival(daysUntil: Int) -> Bool {
        daysUntil == 0
    }

    static func arrivalDayToken(
        eventID: UUID,
        date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(eventID.uuidString)|\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

enum ReminderLeadTime: Int, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case none = -1
    case sameDay = 0
    case oneDay = 1
    case threeDays = 3
    case sevenDays = 7

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .none: return String(localized: "reminder.none")
        case .sameDay: return String(localized: "reminder.same_day")
        case .oneDay: return String(localized: "reminder.one_day")
        case .threeDays: return String(localized: "reminder.three_days")
        case .sevenDays: return String(localized: "reminder.seven_days")
        }
    }
}

enum EventTextClassifier {
    private static let lunarBirthdayKeywords = [
        "chinese birthday",
        "chinese birthdays",
        "lunar birthday",
        "lunar birthdays",
        "农历生日",
        "农历生辰",
        "农历诞辰",
        "阴历生日",
        "阴历生辰",
        "阴历诞辰",
        "旧历生日",
        "旧历生辰",
        "旧历诞辰",
        "農曆生日",
        "農曆生辰",
        "農曆誕辰",
        "陰曆生日",
        "陰曆生辰",
        "陰曆誕辰",
        "舊曆生日",
        "舊曆生辰",
        "舊曆誕辰"
    ]

    private static let lunarAnniversaryKeywords = [
        "chinese anniversary",
        "chinese anniversaries",
        "lunar anniversary",
        "lunar anniversaries",
        "农历纪念日",
        "阴历纪念日",
        "旧历纪念日",
        "農曆紀念日",
        "陰曆紀念日",
        "舊曆紀念日"
    ]

    static func looksLikeLunarBirthday(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return lunarBirthdayKeywords.contains { normalized.contains($0) }
    }

    static func looksLikeLunarAnnualEvent(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return (lunarBirthdayKeywords + lunarAnniversaryKeywords).contains { normalized.contains($0) }
    }
}

struct CountdownEvent: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var nextOccurrence: Date   // next upcoming date of this event
    var originalDate: Date     // raw date stored in calendar (year may be arbitrary)
    var category: EventCategory
    var dateCalendar: EventDateCalendar
    var source: EventSource
    var isIgnored: Bool
    var calendarEventID: String?
    var calendarItemID: String?
    var notes: String?
    var reminderLeadTime: ReminderLeadTime

    init(
        id: UUID = UUID(),
        title: String,
        nextOccurrence: Date,
        originalDate: Date,
        category: EventCategory,
        dateCalendar: EventDateCalendar = .gregorian,
        source: EventSource = .local,
        isIgnored: Bool = false,
        calendarEventID: String? = nil,
        calendarItemID: String? = nil,
        notes: String? = nil,
        reminderLeadTime: ReminderLeadTime = .none
    ) {
        self.id = id
        self.title = title
        self.nextOccurrence = nextOccurrence
        self.originalDate = originalDate
        self.category = category
        self.dateCalendar = dateCalendar
        self.source = source
        self.isIgnored = isIgnored
        self.calendarEventID = calendarEventID
        self.calendarItemID = calendarItemID
        self.notes = notes
        self.reminderLeadTime = reminderLeadTime
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case nextOccurrence
        case originalDate
        case category
        case dateCalendar
        case source
        case isIgnored
        case calendarEventID
        case calendarItemID
        case notes
        case reminderLeadTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        nextOccurrence = try container.decode(Date.self, forKey: .nextOccurrence)
        originalDate = try container.decode(Date.self, forKey: .originalDate)
        category = try container.decode(EventCategory.self, forKey: .category)
        let decodedDateCalendar = try container.decodeIfPresent(EventDateCalendar.self, forKey: .dateCalendar) ?? .gregorian
        let decodedCalendarEventID = try container.decodeIfPresent(String.self, forKey: .calendarEventID)
        source = try container.decodeIfPresent(EventSource.self, forKey: .source) ?? .legacySource(
            calendarEventID: decodedCalendarEventID
        )
        dateCalendar = source == .importedCalendar && (category == .birthday || category == .anniversary) && title.looksLikeLunarAnnualEvent
            ? .lunar
            : decodedDateCalendar
        isIgnored = try container.decodeIfPresent(Bool.self, forKey: .isIgnored) ?? false
        calendarEventID = decodedCalendarEventID
        calendarItemID = try container.decodeIfPresent(String.self, forKey: .calendarItemID)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderLeadTime = try container.decodeIfPresent(ReminderLeadTime.self, forKey: .reminderLeadTime) ?? .none
    }

    var notificationIdentifier: String {
        "countdown-event-\(id.uuidString)"
    }

    /// Days remaining until the next occurrence (0 = today, negative = past)
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: nextOccurrence)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Returns a copy whose next occurrence is recalculated from the original annual date.
    func normalizedForDisplay(referenceDate: Date = Date(), calendar: Calendar = .current) -> CountdownEvent {
        var copy = self
        copy.nextOccurrence = Self.nextAnnualOccurrence(
            from: originalDate,
            dateCalendar: dateCalendar,
            referenceDate: referenceDate,
            calendar: calendar
        )
        return copy
    }

    /// Given any date, return the next upcoming same month/day occurrence.
    static func nextAnnualOccurrence(
        from date: Date,
        dateCalendar: EventDateCalendar = .gregorian,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        guard dateCalendar == .gregorian else {
            return nextLunarOccurrence(
                from: date,
                referenceDate: referenceDate,
                calendar: calendar
            )
        }

        let referenceDay = calendar.startOfDay(for: referenceDate)
        var components = calendar.dateComponents([.month, .day], from: date)
        let referenceYear = calendar.component(.year, from: referenceDay)

        // Try the next several years so dates such as February 29 resolve to
        // the next valid leap-year occurrence instead of falling back to the past.
        for year in referenceYear...(referenceYear + 8) {
            components.year = year
            guard let candidate = calendar.date(from: components) else { continue }
            if candidate >= referenceDay {
                return candidate
            }
        }

        return date
    }

    func matchesSameAnnualEvent(as other: CountdownEvent, calendar: Calendar = .current) -> Bool {
        guard dateCalendar == other.dateCalendar else { return false }

        var matchingCalendar = dateCalendar.foundationCalendar
        matchingCalendar.timeZone = calendar.timeZone
        let lhs = matchingCalendar.dateComponents([.month, .day, .isLeapMonth], from: originalDate)
        let rhs = matchingCalendar.dateComponents([.month, .day, .isLeapMonth], from: other.originalDate)

        return normalizedTitle == other.normalizedTitle &&
            category == other.category &&
            lhs.month == rhs.month &&
            lhs.day == rhs.day &&
            lhs.isLeapMonth == rhs.isLeapMonth
    }

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Human-readable countdown string
    var countdownLabel: String {
        switch daysUntil {
        case 0: return String(localized: "countdown.today")
        case 1: return String(localized: "countdown.tomorrow")
        case 2: return String(localized: "countdown.day_after_tomorrow")
        case let d where d > 0:
            return String.localizedStringWithFormat(
                NSLocalizedString("countdown.days.after", comment: "Days until an event"),
                d
            )
        default: return String(localized: "countdown.expired")
        }
    }

    var countdownBadgeText: String {
        switch daysUntil {
        case ..<0: return String(localized: "countdown.expired")
        case 0: return String(localized: "countdown.today")
        case 1: return String(localized: "countdown.tomorrow")
        case 2: return String(localized: "countdown.day_after_tomorrow")
        case let days where days > 999: return String(localized: "countdown.beyond_thousand")
        default: return "\(daysUntil)"
        }
    }

    var shouldShowCountdownUnit: Bool {
        let isChinese = Bundle.main.preferredLocalizations.first?.lowercased().hasPrefix("zh") == true
        return daysUntil > 2 && !(daysUntil > 999 && isChinese)
    }

    var daysLaterLabel: String {
        switch daysUntil {
        case ..<0: return String(localized: "countdown.expired")
        case 0: return String(localized: "countdown.today")
        case 1: return String(localized: "countdown.tomorrow")
        case 2: return String(localized: "countdown.day_after_tomorrow")
        case let d where d > 2:
            return String.localizedStringWithFormat(
                NSLocalizedString("countdown.days.after", comment: "Days until an event"),
                d
            )
        default:
            return String(localized: "countdown.expired")
        }
    }

    var daysLaterUnitLabel: String {
        String.localizedStringWithFormat(
            NSLocalizedString("countdown.days.after.unit", comment: "Unit shown under the countdown number"),
            daysUntil
        )
    }

    /// Urgency color category
    var urgency: UrgencyLevel {
        switch daysUntil {
        case ...0: return .today
        case 1...7: return .soon
        case 8...30: return .upcoming
        default: return .distant
        }
    }
}

private extension EventSource {
    static func legacySource(calendarEventID: String?) -> EventSource {
        calendarEventID == nil ? .local : .appCalendar
    }
}

private extension String {
    var looksLikeLunarAnnualEvent: Bool {
        EventTextClassifier.looksLikeLunarAnnualEvent(self)
    }

    var looksLikeLunarBirthday: Bool {
        EventTextClassifier.looksLikeLunarBirthday(self)
    }
}

private extension CountdownEvent {
    static func nextLunarOccurrence(
        from date: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        var lunarCalendar = EventDateCalendar.lunar.foundationCalendar
        lunarCalendar.timeZone = calendar.timeZone
        let source = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)

        if let exactMatch = lunarOccurrence(
            matching: source,
            from: referenceDay,
            calendar: calendar,
            lunarCalendar: lunarCalendar,
            requireLeapMonth: true,
            searchDays: 800
        ) {
            return exactMatch
        }

        if source.isLeapMonth == true,
           let regularMonthFallback = lunarOccurrence(
               matching: source,
               from: referenceDay,
               calendar: calendar,
               lunarCalendar: lunarCalendar,
               requireLeapMonth: false,
               searchDays: 400
           ) {
            return regularMonthFallback
        }

        return date
    }

    static func lunarOccurrence(
        matching source: DateComponents,
        from referenceDay: Date,
        calendar: Calendar,
        lunarCalendar: Calendar,
        requireLeapMonth: Bool,
        searchDays: Int
    ) -> Date? {
        for offset in 0...searchDays {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: referenceDay) else { continue }
            let candidateComponents = lunarCalendar.dateComponents([.month, .day, .isLeapMonth], from: candidate)
            let leapMonthMatches = requireLeapMonth
                ? (candidateComponents.isLeapMonth == true) == (source.isLeapMonth == true)
                : candidateComponents.isLeapMonth != true

            if candidateComponents.month == source.month,
               candidateComponents.day == source.day,
               leapMonthMatches {
                return calendar.startOfDay(for: candidate)
            }
        }

        return nil
    }
}

enum UrgencyLevel: Sendable {
    case today, soon, upcoming, distant
}
