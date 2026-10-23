package com.khalil.until.platform.calendar

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventRecurrence
import com.khalil.until.core.model.EventSource
import com.khalil.until.core.model.ReminderLeadTime
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.contentOrNull

class CalendarIntegrationRulesTest {
    private val source = CalendarSnapshot("42", "7", "生日", LocalDate.parse("2000-10-23"), "original", "FREQ=MONTHLY")

    @Test fun sharedCalendarRuleFixtures() {
        val stream = requireNotNull(javaClass.classLoader?.getResourceAsStream("calendar-rule-cases.json"))
        val fixtures = stream.bufferedReader().use { Json.parseToJsonElement(it.readText()).jsonArray }
        for (fixture in fixtures) {
            val fields = fixture.jsonObject
            val rule = requireNotNull(fields["rrule"]).jsonPrimitive.contentOrNull
            val expected = requireNotNull(fields["expected"]).jsonPrimitive.contentOrNull
            assertEquals(requireNotNull(fields["name"]).jsonPrimitive.content, expected, CalendarIntegrationRules.recurrence(source.copy(rrule = rule))?.name)
        }
    }

    @Test fun readsAllThreeSimpleFrequencies() {
        for (recurrence in EventRecurrence.entries) {
            assertEquals(recurrence, CalendarIntegrationRules.recurrence(source.copy(rrule = "FREQ=${recurrence.name.uppercase()}")))
        }
    }

    @Test fun acceptsEquivalentSingleDayConstraints() {
        assertEquals(EventRecurrence.Monthly, CalendarIntegrationRules.recurrence(source.copy(rrule = "FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=23")))
        assertEquals(EventRecurrence.Yearly, CalendarIntegrationRules.recurrence(source.copy(rrule = "FREQ=YEARLY;BYMONTH=10;BYMONTHDAY=23")))
        assertEquals(EventRecurrence.Weekly, CalendarIntegrationRules.recurrence(source.copy(rrule = "FREQ=WEEKLY;WKST=SU;BYDAY=MO")))
    }

    @Test fun rejectsRulesThatWouldLoseConstraints() {
        val rules = listOf(
            "FREQ=WEEKLY;INTERVAL=2", "FREQ=MONTHLY;COUNT=12", "FREQ=YEARLY;UNTIL=20301231T000000Z",
            "FREQ=WEEKLY;BYDAY=MO,FR", "FREQ=MONTHLY;BYDAY=1MO", "FREQ=MONTHLY;BYMONTHDAY=-1",
            "FREQ=MONTHLY;BYMONTHDAY=24", "FREQ=MONTHLY;BYMONTH=10", "FREQ=YEARLY;BYMONTH=11",
            "FREQ=WEEKLY;BYDAY=FR", "FREQ=YEARLY;BYSETPOS=1", "FREQ=DAILY", "FREQ=MONTHLY;BYHOUR=9",
        )
        for (rule in rules) assertNull(rule, CalendarIntegrationRules.recurrence(source.copy(rrule = rule)))
    }

    @Test fun rejectsMissingAndMalformedRulesInsteadOfDefaultingToYearly() {
        for (rule in listOf(null, "", "FREQ=MONTHLY;FREQ=YEARLY", "FREQ=MONTHLY;INTERVAL=0", "FREQ=", "YEARLY", "FREQ=MONTHLY;WKST=XX")) {
            assertNull(rule, CalendarIntegrationRules.recurrence(source.copy(rrule = rule)))
        }
    }

    @Test fun recurrenceDatesAndExceptionsPreventImportAndWriteBack() {
        for (snapshot in listOf(source.copy(rdate = "20261030"), source.copy(exdate = "20261023"), source.copy(exrule = "FREQ=YEARLY"), source.copy(hasExceptions = true))) {
            assertNull(CalendarIntegrationRules.recurrence(snapshot))
            val event = imported()
            assertNull(CalendarIntegrationRules.writePlan(event.copy(notes = "changed"), event, snapshot))
        }
    }

    @Test fun importUsesOriginalStartAndActualRepeatRule() {
        val event = CalendarIntegrationRules.merge(emptyList(), listOf(source)).events.single()
        assertEquals(source.originalDate, event.originalDate)
        assertEquals(EventRecurrence.Monthly, event.recurrence)
        assertEquals(EventSource.ImportedCalendar, event.source)
    }

    @Test fun refreshingTwiceKeepsTheStableIdAndDoesNotDuplicateOrDropImports() {
        val first = CalendarIntegrationRules.merge(emptyList(), listOf(source, source)).events
        val second = CalendarIntegrationRules.merge(first, listOf(source, source)).events
        assertEquals(first, second)
        assertEquals(1, second.size)
    }

    @Test fun oldIncorrectYearlyImportIsRepairedWithoutLosingLocalReminderOrId() {
        val previous = imported().copy(id = "legacy-stable-id", recurrence = EventRecurrence.Yearly, reminderLeadTime = ReminderLeadTime.ThreeDays)
        val repaired = CalendarIntegrationRules.merge(listOf(previous), listOf(source)).events.single()
        assertEquals(previous.id, repaired.id)
        assertEquals(previous.reminderLeadTime, repaired.reminderLeadTime)
        assertEquals(EventRecurrence.Monthly, repaired.recurrence)
    }

    @Test fun missingInstancesDoNotDeleteExistingImports() {
        val previous = imported()
        assertEquals(listOf(previous), CalendarIntegrationRules.merge(listOf(previous), emptyList()).events)
    }

    @Test fun appOwnedAndLocalEventsAreNotOverwrittenByImport() {
        for (ownership in listOf(EventSource.AppCalendar, EventSource.Local)) {
            val previous = imported().copy(source = ownership, title = "local title")
            assertEquals(listOf(previous), CalendarIntegrationRules.merge(listOf(previous), listOf(source)).events)
        }
    }

    @Test fun unsupportedImportsAreReportedWithoutDroppingUnrelatedEvents() {
        val old = imported()
        val local = old.copy(id = "local", calendarEventId = null, source = EventSource.Local)
        val other = old.copy(id = "other", calendarEventId = "99")
        val result = CalendarIntegrationRules.merge(listOf(old, local, other), listOf(source.copy(rrule = "FREQ=WEEKLY;INTERVAL=2")))
        assertEquals(listOf(local, other), result.events)
        assertEquals(1, result.skippedCount)
        assertFalse(result.failed)
    }

    @Test fun titleRenameDoesNotPreventRepairingAnExistingImport() {
        val repaired = CalendarIntegrationRules.merge(listOf(imported()), listOf(source.copy(title = "Family day"))).events.single()
        assertEquals("Family day", repaired.title)
        assertEquals(EventRecurrence.Monthly, repaired.recurrence)
    }

    @Test fun editingOnlyNotesPreservesTheProviderSchedule() {
        val previous = imported()
        val plan = requireNotNull(CalendarIntegrationRules.writePlan(previous.copy(notes = "new note"), previous, source))
        assertFalse(plan.replaceSchedule)
        assertEquals(EventRecurrence.Monthly, plan.event.recurrence)
        assertEquals("new note", plan.event.notes)
    }

    @Test fun editingOnlyTitleRepairsLegacyRuleFromLiveSourceInsteadOfWritingYearly() {
        val previous = imported().copy(recurrence = EventRecurrence.Yearly, originalEpochDay = LocalDate.parse("2026-10-23").toEpochDay())
        val plan = requireNotNull(CalendarIntegrationRules.writePlan(previous.copy(title = "New title"), previous, source))
        assertFalse(plan.replaceSchedule)
        assertEquals(EventRecurrence.Monthly, plan.event.recurrence)
        assertEquals(source.originalDate, plan.event.originalDate)
    }

    @Test fun changingDateOrFrequencyExplicitlyRequestsANewSchedule() {
        val previous = imported()
        for (draft in listOf(previous.copy(recurrence = EventRecurrence.Weekly), previous.copy(originalEpochDay = previous.originalEpochDay + 1))) {
            val plan = requireNotNull(CalendarIntegrationRules.writePlan(draft, previous, source))
            assertTrue(plan.replaceSchedule)
            assertEquals(draft, plan.event)
        }
    }

    @Test fun providerChangingToAComplexRuleBlocksEvenAnExplicitRuleEdit() {
        val previous = imported()
        assertNull(CalendarIntegrationRules.writePlan(previous.copy(recurrence = EventRecurrence.Weekly), previous, source.copy(rrule = "FREQ=WEEKLY;BYDAY=MO,FR")))
    }

    private fun imported(): CountdownEvent = CalendarIntegrationRules.merge(emptyList(), listOf(source)).events.single()
}
