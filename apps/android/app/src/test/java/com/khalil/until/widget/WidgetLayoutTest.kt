package com.khalil.until.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLayoutTest {
    @Test
    fun `small and OEM borderline sizes stay in safe layout`() {
        assertEquals(WidgetLayout.Small, widgetLayoutFor(110f, 110f))
        assertEquals(WidgetLayout.Small, widgetLayoutFor(219f, 240f))
        assertEquals(WidgetLayout.Small, widgetLayoutFor(219f, 320f))
    }

    @Test
    fun `wide low widgets use medium layout`() {
        assertEquals(WidgetLayout.Medium, widgetLayoutFor(240f, 110f))
        assertEquals(WidgetLayout.Medium, widgetLayoutFor(300f, 220f))
    }

    @Test
    fun `large layouts require safe space on both axes`() {
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(220f, 240f))
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(239f, 320f))
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(250f, 250f))
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(279f, 320f))
        assertEquals(WidgetLayout.LargeSpacious, widgetLayoutFor(280f, 280f))
        assertEquals(WidgetLayout.LargeSpacious, widgetLayoutFor(360f, 360f))
    }

    @Test
    fun `tall launcher sizes show additional events instead of the old fixed limit`() {
        val short = widgetLayoutPlan(320f, 320f, eventCount = 20)
        val tall = widgetLayoutPlan(320f, 600f, eventCount = 20)
        assertTrue(tall.upcomingCount > short.upcomingCount)
        assertTrue(tall.upcomingCount > 3)
        assertTrue(tall.upcomingCount < 20)
    }

    @Test
    fun `resizing changes capacity at the next complete row boundary`() {
        val initial = widgetLayoutPlan(320f, 600f)
        // Stay above the horizontal-to-vertical transition when checking rows.
        val heightForTenRows = initial.reservedHeightDp + 10 * (initial.rowHeightDp + initial.rowGapDp)
        assertEquals(9, widgetLayoutPlan(320f, heightForTenRows - .1f).upcomingCount)
        assertEquals(10, widgetLayoutPlan(320f, heightForTenRows.toFloat()).upcomingCount)
    }

    @Test
    fun `font enlargement reserves more room and never adds rows`() {
        val normal = widgetLayoutPlan(320f, 500f, 1f)
        val enlarged = widgetLayoutPlan(320f, 500f, 2f)
        assertTrue(enlarged.heroHeightDp > normal.heroHeightDp)
        assertTrue(enlarged.rowHeightDp > normal.rowHeightDp)
        assertTrue(enlarged.upcomingCount <= normal.upcomingCount)
        assertEquals(enlarged, widgetLayoutPlan(320f, 500f, 1.15f))
    }

    @Test
    fun `capacity is limited by real events and empty lists do not produce negative counts`() {
        assertEquals(0, widgetLayoutPlan(320f, 600f, eventCount = 0).upcomingCount)
        assertEquals(0, widgetLayoutPlan(320f, 600f, eventCount = 1).upcomingCount)
        assertEquals(1, widgetLayoutPlan(320f, 600f, eventCount = 2).upcomingCount)
        assertEquals(0, widgetLayoutPlan(110f, 110f, eventCount = 13).upcomingCount)
    }

    @Test
    fun `rows fit inside height budgets across launcher sizes and font settings`() {
        for (width in listOf(220f, 240f, 280f, 360f, 600f)) {
            for (height in 240..1200 step 17) {
                for (scale in listOf(1f, 1.15f, 2f)) {
                    val plan = widgetLayoutPlan(width, height.toFloat(), scale)
                    val used = plan.reservedHeightDp + plan.upcomingCount * (plan.rowHeightDp + plan.rowGapDp)
                    assertTrue("$width x $height, scale=$scale", used <= height)
                    if (plan.layout != WidgetLayout.Medium) assertTrue(height - used < plan.rowHeightDp + plan.rowGapDp)
                }
            }
        }
    }

    @Test
    fun `growing either dimension never hides events across layout boundaries`() {
        for (scale in listOf(1f, 1.15f, 2f)) {
            for (count in listOf(1, 2, 5, 13, 100)) {
                for (width in listOf(219f, 220f, 239f, 240f, 279f, 280f, 320f)) {
                    var previous = 0
                    for (height in 100..1200) {
                        val current = widgetLayoutPlan(width, height.toFloat(), scale, count).upcomingCount
                        assertTrue("height: $width x $height, font=$scale, events=$count", current >= previous)
                        previous = current
                    }
                }
                for (height in listOf(239f, 240f, 279f, 280f, 320f, 400f, 600f)) {
                    var previous = 0
                    for (width in 110..600) {
                        val current = widgetLayoutPlan(width.toFloat(), height, scale, count).upcomingCount
                        assertTrue("width: $width x $height, font=$scale, events=$count", current >= previous)
                        previous = current
                    }
                }
            }
        }
    }

    @Test
    fun `vertical and spacious layouts are used once they retain the list`() {
        assertEquals(WidgetLayout.Medium, widgetLayoutPlan(320f, 240f, eventCount = 13).layout)
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutPlan(320f, 400f, eventCount = 13).layout)
        assertEquals(WidgetLayout.LargeSpacious, widgetLayoutPlan(320f, 600f, eventCount = 5).layout)
        assertEquals(4, widgetLayoutPlan(320f, 240f, eventCount = 13).upcomingCount)
        assertEquals(4, widgetLayoutPlan(320f, 280f, 1.15f, 13).upcomingCount)
    }
}
