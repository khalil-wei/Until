package com.khalil.until.platform.calendar

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventSource
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Locale

class AndroidCalendarService(private val context: Context) {
    private val resolver get() = context.contentResolver

    fun canRead(): Boolean = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
    fun canWrite(): Boolean = ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED

    fun importImportantEvents(existing: List<CountdownEvent>): CalendarImportResult {
        if (!canRead()) return CalendarImportResult(existing)
        return try {
            val exceptions = exceptionParents()
            val snapshots = linkedMapOf<String, CalendarSnapshot>()
            val instancesUri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
                ContentUris.appendId(it, LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli())
                ContentUris.appendId(it, LocalDate.now().plusYears(2).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli())
            }.build()
            val projection = arrayOf(CalendarContract.Instances.EVENT_ID) + SNAPSHOT_COLUMNS
            requireNotNull(resolver.query(instancesUri, projection, null, null, CalendarContract.Instances.BEGIN)).use { cursor ->
                while (cursor.moveToNext()) {
                    snapshot(cursor, CalendarContract.Instances.EVENT_ID, exceptions)?.let { snapshots[it.eventId] = it }
                }
            }
            // Re-read old imports even if there is no instance in the two-year window.
            val knownIds = existing.filter { it.source == EventSource.ImportedCalendar }.mapNotNull { it.calendarEventId }.distinct()
            for (ids in knownIds.chunked(200)) {
                val selection = "${CalendarContract.Events._ID} IN (${ids.joinToString(",") { "?" }})"
                requireNotNull(resolver.query(CalendarContract.Events.CONTENT_URI, arrayOf(CalendarContract.Events._ID) + SNAPSHOT_COLUMNS, selection, ids.toTypedArray(), null)).use { cursor ->
                    while (cursor.moveToNext()) {
                        snapshot(cursor, CalendarContract.Events._ID, exceptions)?.let { snapshots[it.eventId] = it }
                    }
                }
            }
            CalendarIntegrationRules.merge(existing, snapshots.values.toList())
        } catch (_: Exception) {
            // A failed/null provider query must never empty the local store.
            CalendarImportResult(existing, failed = true)
        }
    }

    fun sync(event: CountdownEvent, previous: CountdownEvent? = null): CalendarSyncResult {
        val existingId = event.calendarEventId?.toLongOrNull()
        if (!canWrite() && existingId != null) return CalendarSyncResult(previous ?: event, CalendarSyncBlock.SourceUnavailable)
        if (!canWrite() || event.dateCalendar == EventDateCalendar.Lunar) return CalendarSyncResult(event.copy(source = EventSource.Local))
        var resolved = event
        var replaceSchedule = true
        var source: CalendarSnapshot? = null
        if (existingId != null) {
            source = try {
                if (!canRead()) null else readSource(existingId)
            } catch (_: Exception) { null }
            if (source == null) return CalendarSyncResult(previous ?: event, CalendarSyncBlock.SourceUnavailable)
            val plan = CalendarIntegrationRules.writePlan(event, previous ?: event, source)
                ?: return CalendarSyncResult(previous ?: event, CalendarSyncBlock.UnsupportedRule)
            resolved = plan.event
            replaceSchedule = plan.replaceSchedule
        }
        val values = ContentValues().apply {
            put(CalendarContract.Events.TITLE, resolved.title)
            val marker = if (resolved.source == EventSource.ImportedCalendar) "" else "\n[Until:${resolved.id}]"
            put(CalendarContract.Events.DESCRIPTION, resolved.notes.orEmpty() + marker)
            if (replaceSchedule) {
                put(CalendarContract.Events.DTSTART, resolved.originalDate.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli())
                putNull(CalendarContract.Events.DTEND)
                put(CalendarContract.Events.DURATION, "P1D")
                put(CalendarContract.Events.ALL_DAY, 1)
                put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
                put(CalendarContract.Events.RRULE, "FREQ=${resolved.recurrence.name.uppercase(Locale.ROOT)}")
            }
        }
        return try {
            val calendarId: String
            val eventId: Long
            if (existingId != null) {
                if (resolver.update(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, existingId), values, null, null) <= 0) {
                    return CalendarSyncResult(previous ?: event, CalendarSyncBlock.SourceUnavailable)
                }
                eventId = existingId
                calendarId = requireNotNull(source).calendarId
            } else {
                val writable = writableCalendarId() ?: return CalendarSyncResult(event.copy(source = EventSource.Local))
                values.put(CalendarContract.Events.CALENDAR_ID, writable)
                eventId = resolver.insert(CalendarContract.Events.CONTENT_URI, values)?.lastPathSegment?.toLongOrNull()
                    ?: return CalendarSyncResult(event.copy(source = EventSource.Local))
                calendarId = writable.toString()
            }
            val ownership = if (event.source == EventSource.ImportedCalendar && !replaceSchedule) EventSource.ImportedCalendar else EventSource.AppCalendar
            CalendarSyncResult(resolved.copy(source = ownership, calendarEventId = eventId.toString(), calendarItemId = calendarId))
        } catch (_: Exception) {
            if (existingId != null) CalendarSyncResult(previous ?: event, CalendarSyncBlock.SourceUnavailable)
            else CalendarSyncResult(event.copy(source = EventSource.Local))
        }
    }

    private fun readSource(id: Long): CalendarSnapshot? {
        val exceptions = exceptionParents()
        return requireNotNull(resolver.query(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id), arrayOf(CalendarContract.Events._ID) + SNAPSHOT_COLUMNS, null, null, null)).use { cursor ->
            if (cursor.moveToFirst()) snapshot(cursor, CalendarContract.Events._ID, exceptions) else null
        }
    }

    private fun exceptionParents(): Set<String> =
        requireNotNull(resolver.query(CalendarContract.Events.CONTENT_URI, arrayOf(CalendarContract.Events.ORIGINAL_ID), "${CalendarContract.Events.ORIGINAL_ID} IS NOT NULL", null, null)).use { cursor ->
            buildSet { while (cursor.moveToNext()) add(cursor.getLong(0).toString()) }
        }

    private fun snapshot(cursor: Cursor, idColumn: String, exceptions: Set<String>): CalendarSnapshot? {
        fun index(column: String) = cursor.getColumnIndexOrThrow(column)
        fun text(column: String): String? = cursor.getString(index(column))
        if (cursor.getInt(index(CalendarContract.Events.DELETED)) != 0 || !cursor.isNull(index(CalendarContract.Events.ORIGINAL_ID))) return null
        val id = cursor.getLong(index(idColumn)).toString()
        require(!cursor.isNull(index(CalendarContract.Events.DTSTART)))
        val allDay = cursor.getInt(index(CalendarContract.Events.ALL_DAY)) == 1
        val zone = if (allDay) ZoneOffset.UTC else runCatching { ZoneId.of(text(CalendarContract.Events.EVENT_TIMEZONE)) }.getOrDefault(ZoneId.systemDefault())
        val original = Instant.ofEpochMilli(cursor.getLong(index(CalendarContract.Events.DTSTART))).atZone(zone).toLocalDate()
        return CalendarSnapshot(
            eventId = id,
            calendarId = cursor.getLong(index(CalendarContract.Events.CALENDAR_ID)).toString(),
            title = text(CalendarContract.Events.TITLE)?.trim().orEmpty(),
            originalDate = original,
            description = text(CalendarContract.Events.DESCRIPTION),
            rrule = text(CalendarContract.Events.RRULE), rdate = text(CalendarContract.Events.RDATE),
            exdate = text(CalendarContract.Events.EXDATE), exrule = text(CalendarContract.Events.EXRULE),
            hasExceptions = id in exceptions,
        )
    }

    fun deleteCalendarEvent(event: CountdownEvent): Boolean {
        if (!canWrite()) return false
        val id = event.calendarEventId?.toLongOrNull() ?: return false
        return runCatching { resolver.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id), null, null) > 0 }.getOrDefault(false)
    }

    private fun writableCalendarId(): Long? {
        if (!canRead()) return null
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI, arrayOf(CalendarContract.Calendars._ID),
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL}>=? AND ${CalendarContract.Calendars.VISIBLE}=1",
            arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()), "${CalendarContract.Calendars.IS_PRIMARY} DESC",
        )?.use { if (it.moveToFirst()) return it.getLong(0) }
        return null
    }

    private companion object {
        val SNAPSHOT_COLUMNS = arrayOf(
            CalendarContract.Events.CALENDAR_ID, CalendarContract.Events.TITLE, CalendarContract.Events.DTSTART,
            CalendarContract.Events.DESCRIPTION, CalendarContract.Events.ALL_DAY, CalendarContract.Events.EVENT_TIMEZONE,
            CalendarContract.Events.RRULE, CalendarContract.Events.RDATE, CalendarContract.Events.EXDATE,
            CalendarContract.Events.EXRULE, CalendarContract.Events.ORIGINAL_ID, CalendarContract.Events.DELETED,
        )
    }
}
