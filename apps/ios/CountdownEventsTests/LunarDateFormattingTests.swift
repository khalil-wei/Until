import XCTest

final class LunarDateFormattingTests: XCTestCase {
    func testFormatsChineseLunarMonthAndDayNames() {
        XCTAssertEqual(formattedLunarDate(month: 1, day: 1), "正月初一")
        XCTAssertEqual(formattedLunarDate(month: 1, day: 10), "正月初十")
        XCTAssertEqual(formattedLunarDate(month: 6, day: 11), "六月十一")
        XCTAssertEqual(formattedLunarDate(month: 6, day: 20), "六月二十")
        XCTAssertEqual(formattedLunarDate(month: 6, day: 21), "六月廿一")
        XCTAssertEqual(formattedLunarDate(month: 12, day: 30, year: 2023), "腊月三十")
    }

    func testFormatsLeapMonth() {
        XCTAssertEqual(formattedLunarDate(month: 2, day: 3, isLeapMonth: true, year: 2023), "闰二月初三")
    }

    func testRecognizesCommonLunarBirthdayWording() {
        XCTAssertTrue(EventTextClassifier.looksLikeLunarBirthday("妈妈阴历生日"))
        XCTAssertTrue(EventTextClassifier.looksLikeLunarBirthday("爸爸旧历生辰"))
        XCTAssertTrue(EventTextClassifier.looksLikeLunarBirthday("Grandma Lunar Birthday"))
        XCTAssertFalse(EventTextClassifier.looksLikeLunarBirthday("结婚纪念日"))
        XCTAssertFalse(EventTextClassifier.looksLikeLunarBirthday("结婚农历纪念日"))
    }

    func testRecognizesLunarAnniversaryWording() {
        XCTAssertTrue(EventTextClassifier.looksLikeLunarAnnualEvent("结婚农历纪念日"))
        XCTAssertTrue(EventTextClassifier.looksLikeLunarAnnualEvent("Wedding Lunar Anniversary"))
        XCTAssertFalse(EventTextClassifier.looksLikeLunarAnnualEvent("结婚纪念日"))
    }

    func testSpecialNumberMatchingRespectsLanguage() {
        XCTAssertEqual(CountdownSpecialNumber.match(daysUntil: 42, isChinese: false), .answer)
        XCTAssertEqual(CountdownSpecialNumber.match(daysUntil: 365, isChinese: false), .orbit)
        XCTAssertEqual(CountdownSpecialNumber.match(daysUntil: 520, isChinese: true), .heart)
        XCTAssertNil(CountdownSpecialNumber.match(daysUntil: 520, isChinese: false))
        XCTAssertNil(CountdownSpecialNumber.match(daysUntil: 41, isChinese: true))
    }

    func testNightLetterPolicyRequiresNightEventsCadenceAndCooldown() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 2))!
        let eligibleDate = (0..<5)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: base) }
            .first { date in
                calendar.ordinality(of: .day, in: .era, for: date)?.isMultiple(of: 5) == true
            }!

        XCTAssertTrue(NightLetterPolicy.shouldShow(now: eligibleDate, lastShownAt: nil, hasEvents: true, calendar: calendar))
        XCTAssertFalse(NightLetterPolicy.shouldShow(now: eligibleDate, lastShownAt: nil, hasEvents: false, calendar: calendar))
        XCTAssertFalse(NightLetterPolicy.shouldShow(now: eligibleDate, lastShownAt: eligibleDate, hasEvents: true, calendar: calendar))

        let daytime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: eligibleDate)!
        XCTAssertFalse(NightLetterPolicy.shouldShow(now: daytime, lastShownAt: nil, hasEvents: true, calendar: calendar))
    }

    func testCountdownEasterEggEligibilityAndArrivalToken() {
        XCTAssertTrue(CountdownEasterEggPolicy.canRevealDistantCountdown(daysUntil: 1000))
        XCTAssertFalse(CountdownEasterEggPolicy.canRevealDistantCountdown(daysUntil: 999))
        XCTAssertTrue(CountdownEasterEggPolicy.canCelebrateArrival(daysUntil: 0))
        XCTAssertFalse(CountdownEasterEggPolicy.canCelebrateArrival(daysUntil: 1))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 22))!
        XCTAssertEqual(
            CountdownEasterEggPolicy.arrivalDayToken(eventID: eventID, date: date, calendar: calendar),
            "00000000-0000-0000-0000-000000000042|2026-7-14"
        )
    }

    private func formattedLunarDate(
        month: Int,
        day: Int,
        isLeapMonth: Bool = false,
        year: Int = 2026
    ) -> String {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "zh_Hans")

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.era = 78
        components.year = year - 1983
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth

        let date = calendar.date(from: components)!
        return EventDateCalendar.formattedLunarMonthDay(from: date, locale: Locale(identifier: "zh_Hans"))
    }
}


extension LunarDateFormattingTests {
    private var recurrenceCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func recurrenceDate(_ value: String, hour: Int = 0) -> Date {
        let parts = value.split(separator: "-").map { Int($0)! }
        return recurrenceCalendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: hour))!
    }

    func testSharedMonthlyAndWeeklyFixtures() {
        let cases: [(String, String, String, EventDateCalendar, EventRecurrence, String)] = [
            ("monthly-last-day-skips-february", "2024-01-31", "2024-02-01", .gregorian, .monthly, "2024-03-31"),
            ("monthly-today", "2000-01-23", "2026-10-23", .gregorian, .monthly, "2026-10-23"),
            ("monthly-passed-day", "2000-01-15", "2026-10-23", .gregorian, .monthly, "2026-11-15"),
            ("monthly-year-boundary", "2000-01-15", "2026-12-16", .gregorian, .monthly, "2027-01-15"),
            ("monthly-february-29-leap-year", "2000-01-29", "2024-02-01", .gregorian, .monthly, "2024-02-29"),
            ("monthly-february-29-common-year", "2000-01-29", "2025-02-01", .gregorian, .monthly, "2025-03-29"),
            ("monthly-future-anchor", "2027-10-23", "2026-10-23", .gregorian, .monthly, "2027-10-23"),
            ("lunar-monthly-includes-leap-month", "2023-02-20", "2023-03-21", .lunar, .monthly, "2023-03-22"),
            ("lunar-monthly-skips-short-months", "2023-03-21", "2023-03-22", .lunar, .monthly, "2023-06-17"),
            ("weekly-today", "2026-10-16", "2026-10-23", .gregorian, .weekly, "2026-10-23"),
            ("weekly-next-week", "2026-10-16", "2026-10-24", .gregorian, .weekly, "2026-10-30"),
            ("weekly-year-boundary", "2026-12-25", "2026-12-26", .gregorian, .weekly, "2027-01-01"),
            ("weekly-future-anchor", "2027-10-23", "2026-10-23", .gregorian, .weekly, "2027-10-23"),
            ("weekly-lunar-is-still-seven-days", "2023-03-22", "2023-03-23", .lunar, .weekly, "2023-03-29"),
        ]
        for (name, original, reference, dateCalendar, recurrence, expected) in cases {
            XCTAssertEqual(CountdownEvent.nextOccurrence(from: recurrenceDate(original), dateCalendar: dateCalendar,
                recurrence: recurrence, referenceDate: recurrenceDate(reference), calendar: recurrenceCalendar),
                recurrenceDate(expected), name)
        }
    }

    func testRecurrencePersistenceAndLegacyDefault() throws {
        let event = CountdownEvent(title: "Repeat", nextOccurrence: recurrenceDate("2026-10-23"),
            originalDate: recurrenceDate("2026-10-16"), category: .custom, recurrence: .weekly)
        let encoded = try JSONEncoder().encode(event)
        XCTAssertEqual(try JSONDecoder().decode(CountdownEvent.self, from: encoded).recurrence, .weekly)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "recurrence")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        XCTAssertEqual(try JSONDecoder().decode(CountdownEvent.self, from: legacy).recurrence, .yearly)
    }

    func testWeeklyRemindersAdvancePastElapsedSevenDayLead() {
        let event = CountdownEvent(title: "Repeat", nextOccurrence: recurrenceDate("2026-10-23"),
            originalDate: recurrenceDate("2026-10-16"), category: .custom, recurrence: .weekly,
            reminderLeadTime: .sevenDays)
        XCTAssertEqual(event.reminderDates(count: 3, referenceDate: recurrenceDate("2026-10-23", hour: 10),
            calendar: recurrenceCalendar), [recurrenceDate("2026-10-30", hour: 9),
                recurrenceDate("2026-11-06", hour: 9), recurrenceDate("2026-11-13", hour: 9)])
    }

    func testWeeklyRecurrenceUsesLocalDatesAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let original = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        XCTAssertEqual(CountdownEvent.nextOccurrence(from: original, recurrence: .weekly,
            referenceDate: reference, calendar: calendar), expected)
    }

    func testNormalizationPreservesRuleAndDistinctEvents() {
        let weekly = CountdownEvent(title: "Repeat", nextOccurrence: recurrenceDate("2026-10-23"),
            originalDate: recurrenceDate("2026-10-16"), category: .custom, recurrence: .weekly)
        let normalized = weekly.normalizedForDisplay(referenceDate: recurrenceDate("2026-10-24"), calendar: recurrenceCalendar)
        XCTAssertEqual(normalized.recurrence, .weekly)
        XCTAssertEqual(normalized.nextOccurrence, recurrenceDate("2026-10-30"))
        var yearly = weekly
        yearly.recurrence = .yearly
        XCTAssertFalse(weekly.matchesSameAnnualEvent(as: yearly, calendar: recurrenceCalendar))
    }

    func testYearlyLeapDayAndFutureAnchor() {
        XCTAssertEqual(CountdownEvent.nextOccurrence(from: recurrenceDate("2000-02-29"),
            referenceDate: recurrenceDate("2026-01-01"), calendar: recurrenceCalendar), recurrenceDate("2028-02-29"))
        XCTAssertEqual(CountdownEvent.nextOccurrence(from: recurrenceDate("2027-10-23"),
            referenceDate: recurrenceDate("2026-10-23"), calendar: recurrenceCalendar), recurrenceDate("2027-10-23"))
    }

    func testCalendarImportRejectsStaleWeeklyAnchorAfterSourceEdit() {
        let source = recurrenceDate("2026-10-24")
        let anchor = CalendarImportRules.validatedAnchor(metadataDate: recurrenceDate("2026-10-16"),
            metadataRecurrence: .weekly, sourceOccurrence: source, dateCalendar: .gregorian,
            recurrence: .weekly, referenceDate: recurrenceDate("2026-10-23"), calendar: recurrenceCalendar)
        XCTAssertEqual(anchor, source)
        XCTAssertEqual(CountdownEvent.nextOccurrence(from: anchor, recurrence: .weekly,
            referenceDate: recurrenceDate("2026-10-25"), calendar: recurrenceCalendar), recurrenceDate("2026-10-31"))
    }

    func testCalendarImportChecksMonthlyYearlyAndChangedFrequency() {
        for (rule, original, source) in [(EventRecurrence.monthly, "2020-01-15", "2026-10-25"),
                                       (.yearly, "2020-10-15", "2026-11-15")] {
            XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: recurrenceDate(original),
                metadataRecurrence: rule, sourceOccurrence: recurrenceDate(source), dateCalendar: .gregorian,
                recurrence: rule, referenceDate: recurrenceDate("2026-10-01"), calendar: recurrenceCalendar), recurrenceDate(source))
        }
        let source = recurrenceDate("2026-10-23")
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: recurrenceDate("2020-10-23"),
            metadataRecurrence: .yearly, sourceOccurrence: source, dateCalendar: .gregorian,
            recurrence: .monthly, referenceDate: source, calendar: recurrenceCalendar), source)
    }

    func testCalendarImportRetainsValidFutureAnchorAndRejectsDelayedSeriesStart() {
        let future = recurrenceDate("2027-10-23")
        let reference = recurrenceDate("2026-10-23")
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: future, metadataRecurrence: .weekly,
            sourceOccurrence: future, dateCalendar: .gregorian, recurrence: .weekly,
            referenceDate: reference, calendar: recurrenceCalendar), future)
        let oldWeekly = recurrenceDate("2026-10-16")
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: oldWeekly, metadataRecurrence: .weekly,
            sourceOccurrence: reference, dateCalendar: .gregorian, recurrence: .weekly,
            referenceDate: reference, calendar: recurrenceCalendar), oldWeekly)
        let monthEnd = recurrenceDate("2024-01-31")
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: monthEnd, metadataRecurrence: .monthly,
            sourceOccurrence: recurrenceDate("2024-03-31"), dateCalendar: .gregorian, recurrence: .monthly,
            referenceDate: recurrenceDate("2024-02-01"), calendar: recurrenceCalendar), monthEnd)
        let delayed = recurrenceDate("2026-11-06")
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: recurrenceDate("2026-10-16"),
            metadataRecurrence: .weekly, sourceOccurrence: delayed, dateCalendar: .gregorian,
            recurrence: .weekly, referenceDate: reference, calendar: recurrenceCalendar), delayed)
        XCTAssertEqual(CalendarImportRules.validatedAnchor(metadataDate: nil, metadataRecurrence: nil,
            sourceOccurrence: delayed, dateCalendar: .gregorian, recurrence: .weekly,
            referenceDate: reference, calendar: recurrenceCalendar), delayed)
    }

    func testNotificationCleanupMatchesLegacyAndCycleIdentifiersOnly() {
        let base = "countdown-event-00000000-0000-0000-0000-000000000001"
        let other = "countdown-event-00000000-0000-0000-0000-000000000002-100"
        let identifiers = [base, base + "-100", base + "-200", other, "unrelated-notification"]
        XCTAssertEqual(EventNotificationIdentifiers.matching(identifiers, eventIdentifiers: [base]),
            [base, base + "-100", base + "-200"])
        XCTAssertEqual(EventNotificationIdentifiers.matching(identifiers), Array(identifiers.prefix(4)))
        XCTAssertEqual(EventNotificationIdentifiers.matching(identifiers, eventIdentifiers: []), [])
    }
}
