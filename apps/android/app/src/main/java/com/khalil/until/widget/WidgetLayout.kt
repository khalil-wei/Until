package com.khalil.until.widget

import kotlin.math.ceil
import kotlin.math.floor

internal enum class WidgetLayout { Small, Medium, LargeCompact, LargeSpacious }

internal fun widgetLayoutFor(widthDp: Float, heightDp: Float): WidgetLayout = when {
    widthDp >= 280f && heightDp >= 280f -> WidgetLayout.LargeSpacious
    widthDp >= 220f && heightDp >= 240f -> WidgetLayout.LargeCompact
    widthDp >= 240f && heightDp >= 100f -> WidgetLayout.Medium
    else -> WidgetLayout.Small
}

internal fun widgetFontScale(fontScale: Float): Float = fontScale.coerceIn(1f, 1.15f)

internal data class WidgetLayoutPlan(
    val layout: WidgetLayout,
    val upcomingCount: Int,
    val paddingDp: Int,
    val heroHeightDp: Int,
    val rowHeightDp: Int,
    val rowGapDp: Int,
    val reservedHeightDp: Int,
)

/** Height budgets include OEM font leading and a bottom safety margin. */
internal fun widgetLayoutPlan(widthDp: Float, heightDp: Float, fontScale: Float = 1f, eventCount: Int = Int.MAX_VALUE): WidgetLayoutPlan {
    val preferred = widgetLayoutFor(widthDp, heightDp)
    if (preferred == WidgetLayout.Small) return WidgetLayoutPlan(preferred, 0, 6, 0, 0, 0, 0)

    var selected = layoutPlan(WidgetLayout.LargeCompact, heightDp, fontScale, eventCount)
    if (widthDp >= 240f) {
        // Keep the horizontal layout's boundary capacity until a vertical layout
        // can retain those events. Capping at the boundary lets it transition
        // eventually instead of favouring the denser horizontal layout forever.
        val medium = layoutPlan(WidgetLayout.Medium, heightDp.coerceAtMost(240f), fontScale, eventCount)
        if (heightDp < 240f || selected.upcomingCount < medium.upcomingCount) selected = medium
    }
    if (preferred == WidgetLayout.LargeSpacious) {
        val spacious = layoutPlan(preferred, heightDp, fontScale, eventCount)
        if (spacious.upcomingCount >= selected.upcomingCount) selected = spacious
    }
    return selected
}

private fun layoutPlan(layout: WidgetLayout, heightDp: Float, fontScale: Float, eventCount: Int): WidgetLayoutPlan {
    val scale = widgetFontScale(fontScale)
    val spacious = layout == WidgetLayout.LargeSpacious
    val medium = layout == WidgetLayout.Medium
    val padding = if (medium) 8 else if (spacious) 14 else 10
    val gap = if (spacious) 5 else 4
    val hero = if (medium) 0 else ceil((if (spacious) 42f else 36f) * 1.6f * scale + padding * 2 + 4).toInt()
    val header = ceil((if (medium) 11f else if (spacious) 28f else 25f) * 1.6f * scale).toInt()
    val section = if (medium) 0 else ceil((if (spacious) 12f else 11f) * 1.6f * scale).toInt()
    val reserved = padding * 2 + header + hero + section + (if (medium) 4 else if (spacious) 16 else 8) + 8
    val row = ceil((if (medium) 19f else 23f) * 1.6f * scale + 4).toInt()
    val capacity = floor((heightDp - reserved) / (row + gap)).toInt().coerceAtLeast(0)
    return WidgetLayoutPlan(layout, capacity.coerceAtMost((eventCount - 1).coerceAtLeast(0)), padding, hero, row, gap, reserved)
}
