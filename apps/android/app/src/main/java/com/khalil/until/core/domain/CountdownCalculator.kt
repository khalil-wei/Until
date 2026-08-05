package com.khalil.until.core.domain

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.UrgencyLevel
import java.time.LocalDate
import java.time.temporal.ChronoUnit

object CountdownCalculator {
    fun daysUntil(targetDate: LocalDate, referenceDate: LocalDate = LocalDate.now()): Int =
        ChronoUnit.DAYS.between(referenceDate, targetDate).toInt()

    fun nextAnnualOccurrence(
        originalDate: LocalDate,
        calendar: EventDateCalendar = EventDateCalendar.Gregorian,
        referenceDate: LocalDate = LocalDate.now(),
    ): LocalDate {
        if (!originalDate.isBefore(referenceDate)) return originalDate
        if (calendar == EventDateCalendar.Lunar) return LunarCalendar.nextOccurrence(originalDate, referenceDate)
        for (year in referenceDate.year..referenceDate.year + 12) {
            val candidate = runCatching { LocalDate.of(year, originalDate.monthValue, originalDate.dayOfMonth) }.getOrNull()
            if (candidate != null && !candidate.isBefore(referenceDate)) return candidate
        }
        return originalDate
    }

    fun nextOccurrence(event: CountdownEvent, referenceDate: LocalDate = LocalDate.now()): LocalDate =
        nextAnnualOccurrence(event.originalDate, event.dateCalendar, referenceDate)

    fun sorted(events: List<CountdownEvent>, referenceDate: LocalDate = LocalDate.now()): List<CountdownEvent> =
        events.filterNot { it.isIgnored }.sortedWith(
            compareBy<CountdownEvent> { daysUntil(nextOccurrence(it, referenceDate), referenceDate) }
                .thenBy { it.title.lowercase() }
                .thenBy { it.id },
        )

    fun urgency(days: Int): UrgencyLevel = when {
        days <= 0 -> UrgencyLevel.Today
        days <= 7 -> UrgencyLevel.Soon
        days <= 30 -> UrgencyLevel.Upcoming
        else -> UrgencyLevel.Distant
    }

    fun matchesSameAnnualEvent(lhs: CountdownEvent, rhs: CountdownEvent): Boolean {
        if (lhs.dateCalendar != rhs.dateCalendar || lhs.category != rhs.category) return false
        if (lhs.title.trim().lowercase() != rhs.title.trim().lowercase()) return false
        return if (lhs.dateCalendar == EventDateCalendar.Lunar) {
            LunarCalendar.sameMonthDay(lhs.originalDate, rhs.originalDate)
        } else {
            lhs.originalDate.monthValue == rhs.originalDate.monthValue && lhs.originalDate.dayOfMonth == rhs.originalDate.dayOfMonth
        }
    }
}
