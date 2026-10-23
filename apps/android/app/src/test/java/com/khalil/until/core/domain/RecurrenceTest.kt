package com.khalil.until.core.domain

import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventRecurrence
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class RecurrenceTest {
    @Test
    fun sharedRecurrenceFixtures() {
        val resource = requireNotNull(javaClass.classLoader?.getResourceAsStream("recurrence-cases.json"))
        val fixtures = resource.bufferedReader().use { Json.parseToJsonElement(it.readText()).jsonArray }
        for (fixture in fixtures) {
            val fields = fixture.jsonObject
            fun field(key: String) = requireNotNull(fields[key]).jsonPrimitive.content
            val event = event(field("originalDate")).copy(
                recurrence = EventRecurrence.entries.first { it.name.equals(field("recurrence"), true) },
                dateCalendar = EventDateCalendar.entries.first { it.name.equals(field("calendar"), true) },
            )
            assertEquals(field("name"), LocalDate.parse(field("expected")), CountdownCalculator.nextOccurrence(event, LocalDate.parse(field("referenceDate"))))
        }
    }

    @Test
    fun oldSavedEventsRemainYearly() {
        val legacy = """{"id":"legacy","title":"Birthday","originalEpochDay":10957,"category":"Birthday"}"""
        val restored = Json.decodeFromString<CountdownEvent>(legacy)
        assertEquals(EventRecurrence.Yearly, restored.recurrence)
        assertEquals(LocalDate.parse("2027-01-01"), CountdownCalculator.nextOccurrence(restored, LocalDate.parse("2026-10-23")))
    }

    @Test
    fun monthlyAndWeeklyRulesSurviveStorageRoundTrip() {
        for (rule in EventRecurrence.entries) {
            val original = event("2026-10-23").copy(recurrence = rule)
            assertEquals(original, Json.decodeFromString<CountdownEvent>(Json.encodeToString(original)))
        }
    }

    @Test
    fun sortingUsesTheSelectedRecurrence() {
        val annual = event("2000-01-01").copy(id = "annual")
        val monthly = event("2000-01-24").copy(id = "monthly", recurrence = EventRecurrence.Monthly)
        val weekly = event("2026-10-16").copy(id = "weekly", recurrence = EventRecurrence.Weekly)
        assertEquals(listOf("weekly", "monthly", "annual"), CountdownCalculator.sorted(listOf(annual, monthly, weekly), LocalDate.parse("2026-10-23")).map { it.id })
    }

    @Test
    fun deduplicationSeparatesDifferentRepeatRules() {
        val annual = event("2000-01-23")
        val monthly = annual.copy(recurrence = EventRecurrence.Monthly)
        assertFalse(CountdownCalculator.matchesSameAnnualEvent(annual, monthly))
        assertTrue(CountdownCalculator.matchesSameAnnualEvent(monthly, monthly.copy(originalEpochDay = LocalDate.parse("2000-02-23").toEpochDay())))
    }

    private fun event(date: String) = CountdownEvent(title = "Repeat", originalEpochDay = LocalDate.parse(date).toEpochDay(), category = EventCategory.Custom)
}
