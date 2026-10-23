package com.khalil.until.ui.screens

import android.content.Context
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khalil.until.R
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventSource
import com.khalil.until.core.model.ReminderLeadTime
import com.khalil.until.ui.components.EventPresentation
import com.khalil.until.ui.components.EventRow
import com.khalil.until.ui.rememberCurrentDate
import com.khalil.until.ui.theme.UrgencySoon
import com.khalil.until.ui.theme.UrgencyUpcoming
import kotlinx.coroutines.delay
import java.util.Locale
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun EventDetailScreen(event: CountdownEvent, onDone: () -> Unit, onEdit: () -> Unit, onDelete: (deleteCalendar: Boolean) -> Unit) {
    val context = LocalContext.current
    val referenceDate by rememberCurrentDate()
    val days = CountdownCalculator.daysUntil(CountdownCalculator.nextOccurrence(event, referenceDate), referenceDate)
    var showDelete by remember { mutableStateOf(false) }
    var revealDistant by remember { mutableStateOf(false) }
    var celebrate by remember(event.id, days) { mutableStateOf(false) }
    var didReplayArrivalManually by remember(event.id) { mutableStateOf(false) }
    LaunchedEffect(event.id, days, referenceDate) {
        if (days == 0) {
            val token = "${event.id}|$referenceDate"
            val preferences = context.getSharedPreferences("countdown_easter_eggs", Context.MODE_PRIVATE)
            val key = "arrival_celebrated_${event.id}"
            if (preferences.getString(key, null) != token) {
                preferences.edit().putString(key, token).apply()
                celebrate = true
            }
        }
    }
    LaunchedEffect(celebrate) { if (celebrate) { delay(2800); celebrate = false } }
    LaunchedEffect(revealDistant) { if (revealDistant) { delay(4600); revealDistant = false } }

    Scaffold(containerColor = MaterialTheme.colorScheme.background, topBar = { DetailHeader(onDone, onEdit) }) { insets ->
        Column(
            Modifier.fillMaxSize().padding(insets).verticalScroll(rememberScrollState()).padding(start = 20.dp, end = 20.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            EventRow(
                event = event,
                onClick = {},
                referenceDate = referenceDate,
                countdownTextOverride = if (celebrate) stringResource(R.string.easter_arrived) else null,
                onLongClick = {
                    if (days > 999) revealDistant = true
                    if (days == 0 && !didReplayArrivalManually) {
                        didReplayArrivalManually = true
                        celebrate = true
                    }
                },
            )
            EventPresentation.specialMessageRes(days, Locale.getDefault().language == "zh")?.let {
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(MaterialTheme.colorScheme.primaryContainer).padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("✦", color = MaterialTheme.colorScheme.primary, fontSize = 14.sp); Spacer(Modifier.width(10.dp)); Text(stringResource(it), color = MaterialTheme.colorScheme.primary, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                }
            }
            val sourceSymbol = when (event.source) {
                EventSource.Local -> "●"
                EventSource.AppCalendar -> "✓"
                EventSource.ImportedCalendar -> "↗"
            }
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(MaterialTheme.colorScheme.surface)) {
                DetailInfoRow(stringResource(R.string.type_label), EventPresentation.categoryLabel(context, event.category), EventPresentation.categorySymbol(event.category), MaterialTheme.colorScheme.primary, emoji = true)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.date), EventPresentation.dateText(event), "", MaterialTheme.colorScheme.primary, clock = true)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.year_label), CountdownCalculator.nextOccurrence(event, referenceDate).year.toString(), "#", MaterialTheme.colorScheme.onSurfaceVariant)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.source_label), EventPresentation.sourceLabel(context, event.source), sourceSymbol, if (event.source == EventSource.ImportedCalendar) UrgencySoon else UrgencyUpcoming)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.calendar_label), if (event.dateCalendar == EventDateCalendar.Lunar) stringResource(R.string.lunar) else stringResource(R.string.gregorian), "◇", UrgencySoon)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.recurrence_label), EventPresentation.recurrenceLabel(context, event.recurrence), "↻", MaterialTheme.colorScheme.primary)
                DetailDivider()
                DetailInfoRow(stringResource(R.string.reminder), reminderLabel(event.reminderLeadTime), "◉", UrgencySoon)
            }

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(stringResource(R.string.notes), fontSize = 15.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
                Text(event.notes ?: stringResource(R.string.no_notes), fontSize = 16.sp, color = if (event.notes == null) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface, modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(MaterialTheme.colorScheme.surface).padding(horizontal = 18.dp, vertical = 12.dp))
            }

            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(MaterialTheme.colorScheme.surface)) {
                ActionRow(stringResource(R.string.edit), "✎", MaterialTheme.colorScheme.primary, onEdit)
                DetailDivider()
                ActionRow(stringResource(R.string.delete), "×", MaterialTheme.colorScheme.error) { showDelete = true }
            }
        }
    }

    if (showDelete) {
        AlertDialog(
            onDismissRequest = { showDelete = false },
            shape = RoundedCornerShape(24.dp),
            title = { Text(stringResource(R.string.delete_event_title), fontWeight = FontWeight.Bold) },
            text = { Text(stringResource(R.string.delete_event_message), color = MaterialTheme.colorScheme.onSurfaceVariant) },
            dismissButton = { TextButton(onClick = { showDelete = false }) { Text(stringResource(R.string.cancel)) } },
            confirmButton = {
                Row {
                    if (event.source != EventSource.Local) TextButton(onClick = { showDelete = false; onDelete(false) }) { Text(stringResource(R.string.remove_from_app)) }
                    TextButton(onClick = { showDelete = false; onDelete(event.source != EventSource.Local) }) { Text(if (event.source == EventSource.Local) stringResource(R.string.delete) else stringResource(R.string.delete_from_calendar), color = MaterialTheme.colorScheme.error) }
                }
            },
        )
    }
    AnimatedVisibility(visible = revealDistant, modifier = Modifier.fillMaxSize(), enter = fadeIn(tween(180)), exit = fadeOut(tween(180))) { DistantReveal(days) { revealDistant = false } }
}

@Composable
private fun DetailHeader(onDone: () -> Unit, onEdit: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(78.dp).padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(80.dp), contentAlignment = Alignment.CenterStart) {
            TextButton(onClick = onDone) { Text(stringResource(R.string.done), color = MaterialTheme.colorScheme.primary, fontSize = 17.sp, fontWeight = FontWeight.Medium) }
        }
        Text(stringResource(R.string.event_detail), fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
        Box(Modifier.width(80.dp), contentAlignment = Alignment.CenterEnd) {
            TextButton(onClick = onEdit) { Text(stringResource(R.string.edit), color = MaterialTheme.colorScheme.primary, fontSize = 17.sp, fontWeight = FontWeight.Medium) }
        }
    }
}

@Composable
private fun DetailInfoRow(label: String, value: String, symbol: String, tint: Color, emoji: Boolean = false, clock: Boolean = false) {
    Row(
        Modifier.fillMaxWidth().height(54.dp).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, fontSize = 15.sp, fontWeight = FontWeight.Medium, modifier = Modifier.width(78.dp))
        Spacer(Modifier.weight(1f))
        Box(Modifier.size(22.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceVariant), contentAlignment = Alignment.Center) {
            if (clock) {
                Canvas(Modifier.size(14.dp)) {
                    val strokeWidth = 1.4.dp.toPx()
                    val center = Offset(size.width / 2f, size.height / 2f)
                    drawCircle(tint, radius = size.minDimension / 2f - strokeWidth / 2f, center = center, style = Stroke(strokeWidth))
                    drawLine(tint, center, Offset(center.x, center.y - size.height * .27f), strokeWidth, StrokeCap.Round)
                    drawLine(tint, center, Offset(center.x + size.width * .24f, center.y + size.height * .08f), strokeWidth, StrokeCap.Round)
                }
            } else {
                Text(symbol, color = tint, fontSize = if (emoji) 12.sp else 11.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            }
        }
        Spacer(Modifier.width(12.dp))
        Text(value, fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.End, maxLines = 2)
    }
}

@Composable private fun DetailDivider() { Box(Modifier.fillMaxWidth().height(1.dp).background(MaterialTheme.colorScheme.outline)) }

@Composable
private fun ActionRow(title: String, symbol: String, tint: Color, action: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = action).padding(horizontal = 18.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(30.dp).clip(CircleShape).background(if (tint == MaterialTheme.colorScheme.error) MaterialTheme.colorScheme.errorContainer else MaterialTheme.colorScheme.surfaceVariant), contentAlignment = Alignment.Center) {
            Text(symbol, color = tint, fontSize = 17.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        }
        Text(title, color = tint, fontSize = 17.sp, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun reminderLabel(value: ReminderLeadTime): String = when (value) {
    ReminderLeadTime.None -> stringResource(R.string.reminder_none)
    ReminderLeadTime.SameDay -> stringResource(R.string.reminder_same_day)
    ReminderLeadTime.OneDay -> stringResource(R.string.reminder_one_day)
    ReminderLeadTime.ThreeDays -> stringResource(R.string.reminder_three_days)
    ReminderLeadTime.SevenDays -> stringResource(R.string.reminder_seven_days)
}

@Composable
private fun DistantReveal(days: Int, onDismiss: () -> Unit) {
    val progress = remember { Animatable(0f) }
    var showContent by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        progress.animateTo(1f, animationSpec = tween(durationMillis = 1750, easing = FastOutSlowInEasing))
    }
    LaunchedEffect(Unit) {
        delay(1150)
        showContent = true
    }
    val contentProgress by animateFloatAsState(
        targetValue = if (showContent) 1f else 0f,
        animationSpec = tween(300),
        label = "distant-content",
    )
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.linearGradient(listOf(Color(0xFA102A31), Color(0xFA17243D), Color(0xFA241D36))))
            .pointerInput(Unit) { detectTapGestures { onDismiss() } },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val colors = listOf(Color(0xFFA3DED1), Color(0xFFB8C9EB), Color(0xFFEBCFAB))
            repeat(32) { index ->
                val stagger = (index % 8) * .02f
                val localProgress = ((progress.value - stagger) / (1f - stagger)).coerceIn(0f, 1f)
                val eased = FastOutSlowInEasing.transform(localProgress)
                val startX = size.width * ((((index * 37) % 94) + 3) / 100f)
                val startY = size.height * ((((index * 53) % 92) + 4) / 100f)
                val angle = index.toDouble() / 32.0 * PI * 2.0
                val radiusX = (36 + index % 5 * 13).dp.toPx()
                val radiusY = (30 + index % 6 * 12).dp.toPx()
                val targetX = size.width / 2f + cos(angle).toFloat() * radiusX
                val targetY = size.height / 2f + sin(angle).toFloat() * radiusY
                val x = startX + (targetX - startX) * eased
                val y = startY + (targetY - startY) * eased
                val radius = (4.8f + index % 3 * 1.2f) * (1f - .42f * eased)
                val alpha = .82f - .58f * eased
                if (index % 3 == 2) {
                    drawCircle(colors[index % colors.size].copy(alpha = alpha), radius * .62f, Offset(x, y))
                } else {
                    drawFivePointStar(Offset(x, y), radius, colors[index % colors.size], alpha)
                }
            }
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.padding(30.dp).graphicsLayer {
                alpha = contentProgress
                scaleX = .92f + .08f * contentProgress
                scaleY = .92f + .08f * contentProgress
            },
        ) {
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(days.toString(), color = Color.White, fontWeight = FontWeight.Bold, fontSize = 58.sp, lineHeight = 62.sp, style = MaterialTheme.typography.displayLarge.copy(fontFeatureSettings = "tnum"))
                Text(stringResource(R.string.day_unit), color = Color.White.copy(alpha = .8f), fontWeight = FontWeight.Medium, fontSize = 18.sp, modifier = Modifier.padding(bottom = 7.dp))
            }
            Text(stringResource(R.string.easter_distant_message), color = Color.White.copy(alpha = .84f), fontSize = 15.sp, textAlign = TextAlign.Center)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFivePointStar(center: Offset, radius: Float, color: Color, alpha: Float) {
    val path = Path()
    repeat(10) { point ->
        val pointRadius = if (point % 2 == 0) radius else radius * .44f
        val angle = -PI / 2.0 + point * PI / 5.0
        val x = center.x + cos(angle).toFloat() * pointRadius
        val y = center.y + sin(angle).toFloat() * pointRadius
        if (point == 0) path.moveTo(x, y) else path.lineTo(x, y)
    }
    path.close()
    drawPath(path, color.copy(alpha = alpha))
}
