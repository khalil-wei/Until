package com.khalil.until.core.model

import kotlinx.serialization.Serializable
import java.time.LocalDate
import java.util.UUID

@Serializable
enum class EventCategory { Birthday, Anniversary, Custom }

@Serializable
enum class EventDateCalendar { Gregorian, Lunar }

@Serializable
enum class EventSource { Local, AppCalendar, ImportedCalendar }

@Serializable
enum class ReminderLeadTime(val days: Int) {
    None(-1), SameDay(0), OneDay(1), ThreeDays(3), SevenDays(7),
}

enum class UrgencyLevel { Today, Soon, Upcoming, Distant }

@Serializable
data class CountdownEvent(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val originalEpochDay: Long,
    val category: EventCategory,
    val dateCalendar: EventDateCalendar = EventDateCalendar.Gregorian,
    val source: EventSource = EventSource.Local,
    val isIgnored: Boolean = false,
    val calendarEventId: String? = null,
    val calendarItemId: String? = null,
    val notes: String? = null,
    val reminderLeadTime: ReminderLeadTime = ReminderLeadTime.None,
    val schemaVersion: Int = 1,
) {
    val originalDate: LocalDate get() = LocalDate.ofEpochDay(originalEpochDay)
}
