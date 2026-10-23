package com.khalil.until.core.domain

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventRecurrence
import com.khalil.until.core.model.UrgencyLevel
import java.time.LocalDate
import java.time.YearMonth
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
        when (event.recurrence) {
            EventRecurrence.Yearly -> nextAnnualOccurrence(event.originalDate, event.dateCalendar, referenceDate)
            EventRecurrence.Monthly -> nextMonthlyOccurrence(event.originalDate, event.dateCalendar, referenceDate)
            EventRecurrence.Weekly -> nextWeeklyOccurrence(event.originalDate, referenceDate)
        }

    fun nextWeeklyOccurrence(originalDate: LocalDate, referenceDate: LocalDate = LocalDate.now()): LocalDate {
        if (!originalDate.isBefore(referenceDate)) return originalDate
        val elapsed = ChronoUnit.DAYS.between(originalDate, referenceDate)
        return originalDate.plusWeeks((elapsed + 6) / 7)
    }

    fun nextMonthlyOccurrence(
        originalDate: LocalDate,
        calendar: EventDateCalendar = EventDateCalendar.Gregorian,
        referenceDate: LocalDate = LocalDate.now(),
    ): LocalDate {
        if (!originalDate.isBefore(referenceDate)) return originalDate
        if (calendar == EventDateCalendar.Lunar) return LunarCalendar.nextMonthlyOccurrence(originalDate, referenceDate)
        val month = YearMonth.from(referenceDate)
        for (offset in 0L..12L) {
            val candidateMonth = month.plusMonths(offset)
            if (originalDate.dayOfMonth > candidateMonth.lengthOfMonth()) continue
            val candidate = candidateMonth.atDay(originalDate.dayOfMonth)
            if (!candidate.isBefore(referenceDate)) return candidate
        }
        return originalDate
    }

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
        if (lhs.dateCalendar != rhs.dateCalendar || lhs.category != rhs.category || lhs.recurrence != rhs.recurrence) return false
        if (lhs.title.trim().lowercase() != rhs.title.trim().lowercase()) return false
        if (lhs.recurrence == EventRecurrence.Weekly) return lhs.originalDate.dayOfWeek == rhs.originalDate.dayOfWeek
        if (lhs.recurrence == EventRecurrence.Monthly) {
            return if (lhs.dateCalendar == EventDateCalendar.Lunar) {
                val left = LunarCalendar.solarToLunar(lhs.originalDate) ?: return false
                val right = LunarCalendar.solarToLunar(rhs.originalDate) ?: return false
                left.day == right.day
            } else lhs.originalDate.dayOfMonth == rhs.originalDate.dayOfMonth
        }
        return if (lhs.dateCalendar == EventDateCalendar.Lunar) {
            LunarCalendar.sameMonthDay(lhs.originalDate, rhs.originalDate)
        } else {
            lhs.originalDate.monthValue == rhs.originalDate.monthValue && lhs.originalDate.dayOfMonth == rhs.originalDate.dayOfMonth
        }
    }
}
