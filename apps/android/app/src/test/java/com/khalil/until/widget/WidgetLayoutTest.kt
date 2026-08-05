package com.khalil.until.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetLayoutTest {
    @Test
    fun `small and OEM borderline sizes stay in safe layout`() {
        assertEquals(WidgetLayout.Small, widgetLayoutFor(110f, 110f))
        assertEquals(WidgetLayout.Small, widgetLayoutFor(220f, 240f))
        assertEquals(WidgetLayout.Small, widgetLayoutFor(239f, 320f))
    }

    @Test
    fun `wide low widgets use medium layout`() {
        assertEquals(WidgetLayout.Medium, widgetLayoutFor(240f, 110f))
        assertEquals(WidgetLayout.Medium, widgetLayoutFor(300f, 220f))
    }

    @Test
    fun `large layouts require safe space on both axes`() {
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(250f, 250f))
        assertEquals(WidgetLayout.LargeCompact, widgetLayoutFor(279f, 320f))
        assertEquals(WidgetLayout.LargeSpacious, widgetLayoutFor(280f, 280f))
        assertEquals(WidgetLayout.LargeSpacious, widgetLayoutFor(360f, 360f))
    }
}
