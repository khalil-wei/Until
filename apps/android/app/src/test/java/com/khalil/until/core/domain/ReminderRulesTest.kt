package com.khalil.until.core.domain

import com.khalil.until.core.model.ReminderLeadTime
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventRecurrence
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime

class ReminderRulesTest {
    private val occurrence = LocalDate.parse("2026-07-10")

    @Test fun reminderFixtures() {
        assertEquals(LocalDateTime.parse("2026-07-10T09:00:00"), ReminderRules.triggerDateTime(occurrence, ReminderLeadTime.SameDay))
        assertEquals(LocalDateTime.parse("2026-07-09T09:00:00"), ReminderRules.triggerDateTime(occurrence, ReminderLeadTime.OneDay))
        assertEquals(LocalDateTime.parse("2026-07-07T09:00:00"), ReminderRules.triggerDateTime(occurrence, ReminderLeadTime.ThreeDays))
        assertEquals(LocalDateTime.parse("2026-07-03T09:00:00"), ReminderRules.triggerDateTime(occurrence, ReminderLeadTime.SevenDays))
        assertNull(ReminderRules.triggerDateTime(occurrence, ReminderLeadTime.None))
    }

    @Test fun weeklyReminderRearmsForNextWeekAfterDelivery() {
        val event = recurring("2026-10-16", EventRecurrence.Weekly, ReminderLeadTime.SameDay)
        assertEquals(LocalDateTime.parse("2026-10-30T09:00:00"), ReminderRules.nextTriggerDateTime(event, LocalDateTime.parse("2026-10-23T09:00:01")))
    }

    @Test fun weeklySevenDayLeadDoesNotRescheduleAnAlreadyPassedAlarm() {
        val event = recurring("2026-10-16", EventRecurrence.Weekly, ReminderLeadTime.SevenDays)
        assertEquals(LocalDateTime.parse("2026-10-30T09:00:00"), ReminderRules.nextTriggerDateTime(event, LocalDateTime.parse("2026-10-23T10:00:00")))
    }

    @Test fun monthlyReminderSkipsInvalidDatesAndKeepsItsLeadTime() {
        val event = recurring("2024-01-31", EventRecurrence.Monthly, ReminderLeadTime.SevenDays)
        assertEquals(LocalDateTime.parse("2024-03-24T09:00:00"), ReminderRules.nextTriggerDateTime(event, LocalDateTime.parse("2024-02-01T10:00:00")))
    }

    @Test fun yearlyReminderAndDisabledReminderStayCompatible() {
        val event = recurring("2000-10-23", EventRecurrence.Yearly, ReminderLeadTime.SameDay)
        assertEquals(LocalDateTime.parse("2027-10-23T09:00:00"), ReminderRules.nextTriggerDateTime(event, LocalDateTime.parse("2026-10-23T10:00:00")))
        assertNull(ReminderRules.nextTriggerDateTime(event.copy(reminderLeadTime = ReminderLeadTime.None)))
    }

    private fun recurring(date: String, recurrence: EventRecurrence, lead: ReminderLeadTime) = CountdownEvent(
        title = "Reminder", originalEpochDay = LocalDate.parse(date).toEpochDay(), category = EventCategory.Custom,
        recurrence = recurrence, reminderLeadTime = lead,
    )
}
