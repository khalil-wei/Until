package com.khalil.until.ui.components

import android.graphics.Paint
import android.graphics.Typeface
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khalil.until.R
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventSource
import com.khalil.until.core.model.UrgencyLevel
import com.khalil.until.ui.theme.UrgencyDistant
import com.khalil.until.ui.theme.UrgencyDistantSoft
import com.khalil.until.ui.theme.UrgencySoon
import com.khalil.until.ui.theme.UrgencySoonSoft
import com.khalil.until.ui.theme.UrgencyToday
import com.khalil.until.ui.theme.UrgencyTodaySoft
import com.khalil.until.ui.theme.UrgencyUpcoming
import com.khalil.until.ui.theme.UrgencyUpcomingSoft
import java.time.LocalDate

data class UrgencyPalette(val color: Color, val soft: Color)

@Composable
fun urgencyPalette(days: Int): UrgencyPalette {
    val darkTheme = MaterialTheme.colorScheme.background == androidx.compose.ui.graphics.Color(0xFF101513)
    return when (CountdownCalculator.urgency(days)) {
        UrgencyLevel.Today -> UrgencyPalette(if (darkTheme) Color(0xFFFF8796) else UrgencyToday, if (darkTheme) Color(0xFF52252F) else UrgencyTodaySoft)
        UrgencyLevel.Soon -> UrgencyPalette(if (darkTheme) Color(0xFFF0B47B) else UrgencySoon, if (darkTheme) Color(0xFF4D341E) else UrgencySoonSoft)
        UrgencyLevel.Upcoming -> UrgencyPalette(if (darkTheme) Color(0xFFAFC5FF) else UrgencyUpcoming, if (darkTheme) Color(0xFF273552) else UrgencyUpcomingSoft)
        UrgencyLevel.Distant -> UrgencyPalette(if (darkTheme) Color(0xFF75D9BE) else UrgencyDistant, if (darkTheme) Color(0xFF1A4036) else UrgencyDistantSoft)
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun EventRow(
    event: CountdownEvent,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    referenceDate: LocalDate = LocalDate.now(),
    onLongClick: (() -> Unit)? = null,
    countdownTextOverride: String? = null,
) {
    val context = LocalContext.current
    val days = CountdownCalculator.daysUntil(CountdownCalculator.nextOccurrence(event, referenceDate), referenceDate)
    val palette = urgencyPalette(days)
    val countdown = EventPresentation.countdownText(context, days)
    val sourceColor = when (event.source) {
        EventSource.Local -> MaterialTheme.colorScheme.onSurfaceVariant
        EventSource.AppCalendar -> UrgencyUpcoming
        EventSource.ImportedCalendar -> UrgencySoon
    }
    val sourceSymbol = when (event.source) {
        EventSource.Local -> "●"
        EventSource.AppCalendar -> "✓"
        EventSource.ImportedCalendar -> "↗"
    }
    val description = "${event.title}, ${EventPresentation.dateText(event)}, $countdown, ${EventPresentation.sourceLabel(context, event.source)}"

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(MaterialTheme.colorScheme.surface)
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .semantics { contentDescription = description }
            .padding(start = 14.dp, end = 12.dp, top = 11.dp, bottom = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(42.dp).clip(CircleShape).background(palette.soft), contentAlignment = Alignment.Center) {
            Text(EventPresentation.categorySymbol(event.category), color = palette.color, fontWeight = FontWeight.Bold, fontSize = 18.sp, lineHeight = 20.sp)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(event.title, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Medium, fontSize = 16.sp, lineHeight = 20.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Box(Modifier.size(16.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceVariant), contentAlignment = Alignment.Center) {
                    Text(sourceSymbol, color = sourceColor, fontWeight = FontWeight.Bold, fontSize = 9.sp, lineHeight = 10.sp)
                }
                Text(
                    if (event.source == EventSource.ImportedCalendar) "${EventPresentation.dateText(event)}  ${EventPresentation.sourceLabel(context, event.source)}" else EventPresentation.dateText(event),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 13.sp,
                    lineHeight = 16.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Spacer(Modifier.width(12.dp))
        CountdownBadge(days, palette.color, palette.soft, textOverride = countdownTextOverride)
    }
}

@Composable
fun CountdownBadge(days: Int, color: Color, softColor: Color, modifier: Modifier = Modifier, textOverride: String? = null) {
    val context = LocalContext.current
    val badge = textOverride ?: EventPresentation.countdownText(context, days)
    Column(
        modifier = modifier.width(72.dp).height(54.dp).clip(RoundedCornerShape(13.dp)).background(softColor).padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.End,
        verticalArrangement = Arrangement.Center,
    ) {
        if (textOverride != null) {
            Text(badge, color = color, fontWeight = FontWeight.Bold, fontSize = if (badge.length >= 4) 14.sp else 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        } else if (days in 3..999) {
            Text(days.toString(), color = color, fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 28.sp, style = MaterialTheme.typography.titleLarge.copy(fontFeatureSettings = "tnum"))
            val unit = stringResource(R.string.day_unit)
            val unitColor = MaterialTheme.colorScheme.onSurfaceVariant
            val density = LocalDensity.current
            val unitWidth = remember(unit, density.density, density.fontScale) {
                val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    textSize = with(density) { 12.sp.toPx() }
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
                }
                with(density) { (paint.measureText(unit) + 2.dp.toPx()).toDp() }.coerceAtLeast(18.dp)
            }
            Canvas(Modifier.width(unitWidth).height(18.dp)) {
                val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    this.color = unitColor.toArgb()
                    textSize = 12.sp.toPx()
                    textAlign = Paint.Align.RIGHT
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
                }
                val metrics = paint.fontMetrics
                val baseline = size.height / 2f - (metrics.ascent + metrics.descent) / 2f
                drawContext.canvas.nativeCanvas.drawText(unit, size.width, baseline, paint)
            }
        } else if (days == 0) {
            Text(stringResource(R.string.countdown_today), color = color, fontWeight = FontWeight.Bold, fontSize = 16.sp)
        } else {
            Text(badge, color = color, fontWeight = FontWeight.Bold, fontSize = if (days > 999) 14.sp else 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}
