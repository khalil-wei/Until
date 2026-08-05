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
