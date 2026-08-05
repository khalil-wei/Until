package com.khalil.until.core.domain

import com.khalil.until.core.model.ReminderLeadTime
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
}
