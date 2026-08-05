package com.khalil.until.core.domain

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class CountdownCalculatorTest {
    private val reference = LocalDate.parse("2026-06-30")

    @Test fun today() = assertEquals(LocalDate.parse("2026-06-30"), next("2000-06-30"))
    @Test fun tomorrow() = assertEquals(LocalDate.parse("2026-07-01"), next("2000-07-01"))
    @Test fun dayAfterTomorrow() = assertEquals(LocalDate.parse("2026-07-02"), next("2000-07-02"))
    @Test fun passedDateMovesToNextYear() = assertEquals(LocalDate.parse("2027-06-01"), next("2000-06-01"))
    @Test fun february29SkipsInvalidYears() = assertEquals(LocalDate.parse("2028-02-29"), next("2000-02-29"))

    @Test fun normalizedSameAnnualEventMatches() {
        val lhs = event("Alice Birthday", "1998-06-30")
        val rhs = event(" alice birthday ", "2026-06-30")
        assertTrue(CountdownCalculator.matchesSameAnnualEvent(lhs, rhs))
        assertFalse(CountdownCalculator.matchesSameAnnualEvent(lhs, event("Alice Birthday", "1998-07-01")))
    }

    private fun next(date: String) = CountdownCalculator.nextAnnualOccurrence(LocalDate.parse(date), EventDateCalendar.Gregorian, reference)
    private fun event(title: String, date: String) = CountdownEvent(title = title, originalEpochDay = LocalDate.parse(date).toEpochDay(), category = EventCategory.Birthday)
}
