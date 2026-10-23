package com.khalil.until.platform.calendar

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventRecurrence
import com.khalil.until.core.model.EventSource
import java.time.LocalDate
import java.util.Locale

data class CalendarSnapshot(
    val eventId: String,
    val calendarId: String,
    val title: String,
    val originalDate: LocalDate,
    val description: String? = null,
    val rrule: String? = null,
    val rdate: String? = null,
    val exdate: String? = null,
    val exrule: String? = null,
    val hasExceptions: Boolean = false,
)

data class CalendarImportResult(
    val events: List<CountdownEvent>,
    val skippedCount: Int = 0,
    val failed: Boolean = false,
)

enum class CalendarSyncBlock { UnsupportedRule, SourceUnavailable }

data class CalendarSyncResult(val event: CountdownEvent, val blocked: CalendarSyncBlock? = null)

data class CalendarWritePlan(val event: CountdownEvent, val replaceSchedule: Boolean)

/** Only accept rules that the app can reproduce without losing constraints. */
object CalendarIntegrationRules {
    fun recurrence(snapshot: CalendarSnapshot): EventRecurrence? {
        if (snapshot.hasExceptions || !snapshot.rdate.isNullOrBlank() || !snapshot.exdate.isNullOrBlank() || !snapshot.exrule.isNullOrBlank()) return null
        val rule = snapshot.rrule?.trim()?.uppercase(Locale.ROOT)?.removePrefix("RRULE:") ?: return null
        if (rule.isBlank()) return null
        val fields = mutableMapOf<String, String>()
        for (part in rule.split(';')) {
            val pair = part.split('=', limit = 2).map(String::trim)
            if (pair.size != 2 || pair.any(String::isBlank) || fields.put(pair[0], pair[1]) != null) return null
        }
        if (fields.keys.any { it !in setOf("FREQ", "INTERVAL", "WKST", "BYDAY", "BYMONTH", "BYMONTHDAY") }) return null
        if (fields.containsKey("INTERVAL") && fields["INTERVAL"]?.toIntOrNull() != 1) return null
        val weekdays = listOf("MO", "TU", "WE", "TH", "FR", "SA", "SU")
        if (fields.containsKey("WKST") && fields["WKST"] !in weekdays) return null
        val result = when (fields["FREQ"]) {
            "YEARLY" -> EventRecurrence.Yearly
            "MONTHLY" -> EventRecurrence.Monthly
            "WEEKLY" -> EventRecurrence.Weekly
            else -> return null
        }
        when (result) {
            EventRecurrence.Weekly -> {
                if (fields.containsKey("BYMONTH") || fields.containsKey("BYMONTHDAY")) return null
                if (fields.containsKey("BYDAY") && fields["BYDAY"] != weekdays[snapshot.originalDate.dayOfWeek.value - 1]) return null
            }
            EventRecurrence.Monthly, EventRecurrence.Yearly -> {
                if (fields.containsKey("BYDAY")) return null
                if (fields.containsKey("BYMONTHDAY") && fields["BYMONTHDAY"]?.toIntOrNull() != snapshot.originalDate.dayOfMonth) return null
                if (fields.containsKey("BYMONTH")) {
                    if (result != EventRecurrence.Yearly || fields["BYMONTH"]?.toIntOrNull() != snapshot.originalDate.monthValue) return null
                }
            }
        }
        return result
    }

    fun merge(existing: List<CountdownEvent>, snapshots: List<CalendarSnapshot>): CalendarImportResult {
        val merged = existing.toMutableList()
        val ownedIds = existing.filter { it.source != EventSource.ImportedCalendar }.mapNotNull { it.calendarEventId }.toSet()
        val skipped = mutableSetOf<String>()
        for (snapshot in snapshots.distinctBy { it.eventId }) {
            if (snapshot.eventId in ownedIds) continue
            val index = merged.indexOfFirst { it.source == EventSource.ImportedCalendar && it.calendarEventId == snapshot.eventId }
            val category = classify(snapshot.title) ?: merged.getOrNull(index)?.category ?: continue
            val recurrence = recurrence(snapshot)
            if (recurrence == null) {
                skipped += snapshot.eventId
                continue
            }
            val previous = merged.getOrNull(index)
            val event = (previous ?: CountdownEvent(
                id = "calendar-${snapshot.eventId}-${snapshot.calendarId}",
                title = snapshot.title,
                originalEpochDay = snapshot.originalDate.toEpochDay(),
                category = category,
            )).copy(
                title = snapshot.title,
                originalEpochDay = snapshot.originalDate.toEpochDay(),
                category = category,
                dateCalendar = EventDateCalendar.Gregorian,
                source = EventSource.ImportedCalendar,
                calendarEventId = snapshot.eventId,
                calendarItemId = snapshot.calendarId,
                notes = snapshot.description,
                recurrence = recurrence,
            )
            if (index >= 0) merged[index] = event else merged += event
        }
        // Missing snapshots are not proof of deletion: the series may be outside the query window.
        // Explicitly unsupported imports are excluded, with a visible count returned to the caller.
        return CalendarImportResult(merged.filterNot { it.source == EventSource.ImportedCalendar && it.calendarEventId in skipped }, skipped.size)
    }

    fun writePlan(draft: CountdownEvent, previous: CountdownEvent, source: CalendarSnapshot): CalendarWritePlan? {
        val recurrence = recurrence(source) ?: return null
        val scheduleChanged = draft.originalEpochDay != previous.originalEpochDay ||
            draft.recurrence != previous.recurrence || draft.dateCalendar != previous.dateCalendar
        return if (scheduleChanged) CalendarWritePlan(draft, true)
        else CalendarWritePlan(draft.copy(originalEpochDay = source.originalDate.toEpochDay(), recurrence = recurrence), false)
    }

    private fun classify(title: String): EventCategory? {
        val normalized = title.lowercase(Locale.ROOT)
        return when {
            listOf("生日", "birthday", "诞辰").any(normalized::contains) -> EventCategory.Birthday
            listOf("纪念", "anniversary", "周年").any(normalized::contains) -> EventCategory.Anniversary
            else -> null
        }
    }
}
