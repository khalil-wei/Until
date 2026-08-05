package com.khalil.until.platform.calendar

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventSource
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset

class AndroidCalendarService(private val context: Context) {
    private val resolver get() = context.contentResolver

    fun canRead(): Boolean = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
    fun canWrite(): Boolean = ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED

    fun importImportantEvents(existing: List<CountdownEvent>): List<CountdownEvent> {
        if (!canRead()) return existing
        val knownCalendarIds = existing.mapNotNull { it.calendarEventId }.toSet()
        val imported = mutableListOf<CountdownEvent>()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.ALL_DAY,
        )
        val start = LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val end = LocalDate.now().plusYears(2).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val instancesUri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
            ContentUris.appendId(it, start)
            ContentUris.appendId(it, end)
        }.build()
        val seenEventIds = mutableSetOf<String>()
        resolver.query(instancesUri, projection, null, null, CalendarContract.Instances.BEGIN)?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
            val calendarIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)
            val dateIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
            val descriptionIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION)
            val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                if (id in knownCalendarIds || !seenEventIds.add(id)) continue
                val title = cursor.getString(titleIndex)?.trim().orEmpty()
                val category = classify(title) ?: continue
                val zone = if (cursor.getInt(allDayIndex) == 1) ZoneOffset.UTC else ZoneId.systemDefault()
                val originalDate = Instant.ofEpochMilli(cursor.getLong(dateIndex)).atZone(zone).toLocalDate()
                imported += CountdownEvent(
                    id = "calendar-$id-${cursor.getLong(calendarIndex)}",
                    title = title,
                    originalEpochDay = originalDate.toEpochDay(),
                    category = category,
                    dateCalendar = EventDateCalendar.Gregorian,
                    source = EventSource.ImportedCalendar,
                    calendarEventId = id,
                    calendarItemId = cursor.getLong(calendarIndex).toString(),
                    notes = cursor.getString(descriptionIndex),
                )
            }
        }
        val local = existing.filterNot { it.source == EventSource.ImportedCalendar }
        return (local + imported).fold(emptyList()) { result, candidate ->
            if (result.any { CountdownCalculator.matchesSameAnnualEvent(it, candidate) && it.calendarEventId == candidate.calendarEventId }) result
            else result + candidate
        }
    }

    fun sync(event: CountdownEvent): CountdownEvent {
        if (!canWrite() || event.dateCalendar == EventDateCalendar.Lunar) return event.copy(source = EventSource.Local)
        val existingId = event.calendarEventId?.toLongOrNull()
        val values = ContentValues().apply {
            put(CalendarContract.Events.TITLE, event.title)
            put(CalendarContract.Events.DESCRIPTION, event.notes.orEmpty() + "\n[Until:${event.id}]")
            put(CalendarContract.Events.DTSTART, event.originalDate.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli())
            put(CalendarContract.Events.DURATION, "P1D")
            put(CalendarContract.Events.ALL_DAY, 1)
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            put(CalendarContract.Events.RRULE, "FREQ=YEARLY")
        }
        val updatedId = existingId?.takeIf {
            resolver.update(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, it), values, null, null) > 0
        }
        if (existingId != null && updatedId == null && event.source != EventSource.AppCalendar) {
            return event.copy(source = EventSource.Local)
        }
        val eventId = updatedId ?: run {
            val calendarId = writableCalendarId() ?: return event.copy(source = EventSource.Local)
            values.put(CalendarContract.Events.CALENDAR_ID, calendarId)
            resolver.insert(CalendarContract.Events.CONTENT_URI, values)?.lastPathSegment?.toLongOrNull()
                ?: return event.copy(source = EventSource.Local)
        }
        return event.copy(source = EventSource.AppCalendar, calendarEventId = eventId.toString())
    }

    fun deleteCalendarEvent(event: CountdownEvent): Boolean {
        if (!canWrite()) return false
        val id = event.calendarEventId?.toLongOrNull() ?: return false
        return resolver.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id), null, null) > 0
    }

    private fun writableCalendarId(): Long? {
        if (!canRead()) return null
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL}>=? AND ${CalendarContract.Calendars.VISIBLE}=1"
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()),
            "${CalendarContract.Calendars.IS_PRIMARY} DESC",
        )?.use { if (it.moveToFirst()) return it.getLong(0) }
        return null
    }

    private fun classify(title: String): EventCategory? {
        val normalized = title.lowercase()
        return when {
            listOf("生日", "birthday", "诞辰").any(normalized::contains) -> EventCategory.Birthday
            listOf("纪念", "anniversary", "周年").any(normalized::contains) -> EventCategory.Anniversary
            else -> null
        }
    }
}
