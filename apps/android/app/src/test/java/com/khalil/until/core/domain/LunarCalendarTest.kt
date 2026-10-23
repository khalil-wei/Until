package com.khalil.until.core.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class LunarCalendarTest {
    @Test
    fun chineseNewYearMovesToTheMatchingLunarDate() {
        val source = LocalDate.parse("2024-02-10")
        assertEquals(LocalDate.parse("2025-01-29"), LunarCalendar.nextOccurrence(source, LocalDate.parse("2025-01-01")))
    }

    @Test
    fun midAutumnFestivalMovesToTheMatchingLunarDate() {
        val source = LocalDate.parse("2024-09-17")
        assertEquals(LocalDate.parse("2025-10-06"), LunarCalendar.nextOccurrence(source, LocalDate.parse("2025-01-01")))
    }

    @Test
    fun formattedChineseDateMatchesReferenceStyle() {
        assertEquals("正月初一", LunarCalendar.formattedMonthDay(LocalDate.parse("2024-02-10"), chinese = true))
    }

    @Test
    fun pickerConvertsLunarNewYearToItsActualGregorianDay() {
        assertEquals(LocalDate.parse("2024-02-10"), LunarCalendar.lunarToSolar(LunarDate(2024, 1, 1, false)))
        assertEquals("农历 2024年正月初一", LunarCalendar.formattedDate(LocalDate.parse("2024-02-10"), true))
        assertEquals("Lunar 2024/1/1", LunarCalendar.formattedDate(LocalDate.parse("2024-02-10"), false))
    }

    @Test
    fun leapMonthIsASeparatePickerOptionWithItsOwnActualDate() {
        assertTrue(LunarCalendar.months(2023).contains(2 to true))
        assertEquals(LocalDate.parse("2023-03-22"), LunarCalendar.lunarToSolar(LunarDate(2023, 2, 1, true)))
        assertEquals("闰二月初一", LunarCalendar.formattedMonthDay(LocalDate.parse("2023-03-22"), true))
        assertNull(LunarCalendar.lunarToSolar(LunarDate(2024, 2, 1, true)))
    }

    @Test
    fun pickerRejectsInvalidDaysAndYearsRatherThanReinterpretingThemAsGregorian() {
        assertEquals(29, LunarCalendar.daysInMonth(2023, 2, true))
        assertNull(LunarCalendar.lunarToSolar(LunarDate(2023, 2, 30, true)))
        assertNull(LunarCalendar.lunarToSolar(LunarDate(1899, 1, 1, false)))
        assertNull(LunarCalendar.lunarToSolar(LunarDate(2101, 1, 1, false)))
        assertNull(LunarCalendar.lunarToSolar(LunarDate(2024, 13, 1, false)))
        assertEquals("超出农历支持范围", LunarCalendar.formattedMonthDay(LocalDate.parse("1800-01-01"), true))
    }

    @Test
    fun changingYearAndMonthKeepsPickerSelectionValid() {
        assertEquals(LunarDate(2024, 2, 1, false), LunarCalendar.normalizeSelection(LunarDate(2024, 2, 1, true)))
        assertEquals(LunarDate(2023, 2, 29, true), LunarCalendar.normalizeSelection(LunarDate(2023, 2, 30, true)))
        assertNull(LunarCalendar.normalizeSelection(LunarDate(2101, 1, 1, false)))
    }

    @Test
    fun everyMonthBoundaryRoundTripsIncludingSupportedRangeAndLeapYears() {
        for (year in listOf(1900, 2000, 2023, 2024, 2025, 2100)) {
            for ((month, leap) in LunarCalendar.months(year)) {
                for (day in listOf(1, requireNotNull(LunarCalendar.daysInMonth(year, month, leap)))) {
                    val expected = LunarDate(year, month, day, leap)
                    assertEquals(expected, LunarCalendar.solarToLunar(requireNotNull(LunarCalendar.lunarToSolar(expected))))
                }
            }
        }
    }
}
