package com.khalil.until.core.domain

import com.khalil.until.core.model.ReminderLeadTime
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

object ReminderRules {
    fun triggerDateTime(occurrence: LocalDate, leadTime: ReminderLeadTime): LocalDateTime? =
        if (leadTime == ReminderLeadTime.None) null
        else LocalDateTime.of(occurrence.minusDays(leadTime.days.toLong()), LocalTime.of(9, 0))
}
