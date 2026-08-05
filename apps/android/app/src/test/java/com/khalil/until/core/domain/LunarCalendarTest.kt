package com.khalil.until.core.domain

import org.junit.Assert.assertEquals
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
}
