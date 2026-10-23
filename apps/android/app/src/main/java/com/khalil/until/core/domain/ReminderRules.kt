package com.khalil.until.core.domain

import com.khalil.until.core.model.ReminderLeadTime
import com.khalil.until.core.model.CountdownEvent
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

object ReminderRules {
    fun nextTriggerDateTime(event: CountdownEvent, now: LocalDateTime = LocalDateTime.now()): LocalDateTime? {
        if (event.reminderLeadTime == ReminderLeadTime.None) return null
        val earliest = now.toLocalDate().plusDays(event.reminderLeadTime.days.toLong())
        val occurrence = CountdownCalculator.nextOccurrence(event, earliest)
        val trigger = triggerDateTime(occurrence, event.reminderLeadTime) ?: return null
        if (trigger.isAfter(now)) return trigger
        val next = CountdownCalculator.nextOccurrence(event, occurrence.plusDays(1))
        if (!next.isAfter(occurrence)) return null
        return triggerDateTime(next, event.reminderLeadTime)?.takeIf { it.isAfter(now) }
    }

    fun triggerDateTime(occurrence: LocalDate, leadTime: ReminderLeadTime): LocalDateTime? =
        if (leadTime == ReminderLeadTime.None) null
        else LocalDateTime.of(occurrence.minusDays(leadTime.days.toLong()), LocalTime.of(9, 0))
}
