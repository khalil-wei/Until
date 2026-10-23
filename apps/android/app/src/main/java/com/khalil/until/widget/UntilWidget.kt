package com.khalil.until.widget

import android.content.Context
import android.content.Intent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider as GlanceColorProvider
import com.khalil.until.MainActivity
import com.khalil.until.R
import com.khalil.until.UntilApplication
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import kotlinx.coroutines.flow.first

class UntilWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val app = context.applicationContext as UntilApplication
        val events = app.repository.events.first()
        val settings = WidgetSettingsStore.load(context)
        val orderedEvents = settings.featuredEventId?.let { featuredId ->
            events.firstOrNull { it.id == featuredId }?.let { featured ->
                listOf(featured) + events.filterNot { it.id == featuredId }
            }
        } ?: events
        provideContent { WidgetContent(context, orderedEvents, settings.theme) }
    }
}

class UntilWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = UntilWidget()
}

@androidx.compose.runtime.Composable
private fun WidgetContent(context: Context, events: List<CountdownEvent>, theme: WidgetTheme) {
    val size = LocalSize.current
    val plan = widgetLayoutPlan(size.width.value, size.height.value, context.resources.configuration.fontScale, events.size)
    val appIntent = Intent(context, MainActivity::class.java)
    Box(
        modifier = GlanceModifier.fillMaxSize().appWidgetBackground().cornerRadius(24.dp)
            .background(widgetBackground(theme))
            .clickable(actionStartActivity(appIntent)),
    ) {
        if (events.isEmpty()) {
            Box(modifier = GlanceModifier.fillMaxSize().padding(10.dp), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("＋", style = TextStyle(color = harmonyTeal(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 26f)))
                    Spacer(GlanceModifier.height(6.dp))
                    Text(context.getString(R.string.widget_empty), style = TextStyle(color = ink(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 15f)))
                    Spacer(GlanceModifier.height(4.dp))
                    if (size.height >= 140.dp) Text(context.getString(R.string.widget_add), maxLines = 1, style = TextStyle(color = secondaryInk(), fontSize = widgetSp(context, 11f)))
                }
            }
        } else {
            when (plan.layout) {
                WidgetLayout.LargeSpacious, WidgetLayout.LargeCompact -> LargeWidget(context, events, theme, plan)
                WidgetLayout.Medium -> MediumWidget(context, events, theme, plan)
                WidgetLayout.Small -> SmallWidget(
                    context,
                    events.first(),
                    roomy = size.width >= 180.dp && size.height >= 180.dp,
                )
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun SmallWidget(context: Context, event: CountdownEvent, roomy: Boolean) {
    val days = eventDays(event)
    val intent = eventIntent(context, event)
    val value = countdown(context, days)
    if (!roomy) {
        val height = LocalSize.current.height.value
        val textScale = (height / 110f).coerceIn(.65f, 1f)
        Column(
            modifier = GlanceModifier.fillMaxSize().padding(6.dp).cornerRadius(20.dp).background(heroColor(days))
                .padding(horizontal = 10.dp, vertical = if (height < 90) 4.dp else if (height < 110) 6.dp else 9.dp).clickable(actionStartActivity(intent)),
        ) {
            if (LocalSize.current.height >= 140.dp) Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(categorySymbol(event), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 10f)))
                Spacer(GlanceModifier.width(5.dp))
                Text(categoryName(context, event), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 9f)), modifier = GlanceModifier.defaultWeight())
            }
            Spacer(GlanceModifier.height(3.dp))
            Text(event.title, maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 14f * textScale)))
            Spacer(GlanceModifier.defaultWeight())
            Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    value,
                    maxLines = 1,
                    modifier = GlanceModifier.padding(bottom = 2.dp),
                    style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = countdownSize(context, value, numeric = 24f * textScale, label = 21f * textScale)),
                )
                if (shouldShowUnit(days)) {
                    Spacer(GlanceModifier.width(3.dp))
                    Text(context.getString(R.string.day_unit), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 9f)))
                }
            }
        }
        return
    }
    Column(
        modifier = GlanceModifier.fillMaxSize().padding(9.dp).cornerRadius(22.dp).background(heroColor(days))
            .padding(horizontal = 13.dp, vertical = 12.dp).clickable(actionStartActivity(intent)),
    ) {
        Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(categorySymbol(event), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 11f)))
            Spacer(GlanceModifier.width(6.dp))
            Text(categoryName(context, event), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 10f)), modifier = GlanceModifier.defaultWeight())
            Text("UNTIL", style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 9f)))
        }
        Spacer(GlanceModifier.height(7.dp))
        Text(event.title, maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 15f)))
        Spacer(GlanceModifier.defaultWeight())
        Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(value, maxLines = 1, modifier = GlanceModifier.padding(bottom = 2.dp), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = countdownSize(context, value, numeric = 32f, label = 28f)))
            if (shouldShowUnit(days)) {
                Spacer(GlanceModifier.width(4.dp))
                Text(context.getString(R.string.day_unit), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 11f)))
            }
        }
        Text(dateText(event), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Medium, fontSize = widgetSp(context, 9f)))
    }
}

@androidx.compose.runtime.Composable
private fun MediumWidget(context: Context, events: List<CountdownEvent>, theme: WidgetTheme, plan: WidgetLayoutPlan) {
    Row(GlanceModifier.fillMaxSize().padding(horizontal = 10.dp, vertical = 8.dp)) {
        Box(GlanceModifier.width(98.dp).fillMaxHeight()) { MediumHeroEvent(context, events.first()) }
        Spacer(GlanceModifier.width(9.dp))
        Column(GlanceModifier.defaultWeight()) {
            Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("UNTIL", maxLines = 1, style = TextStyle(color = widgetBrand(theme), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 10f)))
                Spacer(GlanceModifier.width(6.dp))
                Text(if (java.util.Locale.getDefault().language == "zh") "即将到来" else "COMING UP", maxLines = 1, style = TextStyle(color = secondaryInk(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 11f)), modifier = GlanceModifier.defaultWeight())
                Text(events.size.toString(), maxLines = 1, style = TextStyle(color = secondaryInk(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 10f)))
            }
            Spacer(GlanceModifier.height(4.dp))
            UpcomingEvents(context, events.drop(1).take(plan.upcomingCount), plan)
        }
    }
}

@androidx.compose.runtime.Composable
private fun LargeWidget(context: Context, events: List<CountdownEvent>, theme: WidgetTheme, plan: WidgetLayoutPlan) {
    val spacious = plan.layout == WidgetLayout.LargeSpacious
    val upcoming = events.drop(1).take(plan.upcomingCount)
    Column(GlanceModifier.fillMaxSize().padding(plan.paddingDp.dp)) {
        Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(GlanceModifier.defaultWeight()) {
                Text(if (java.util.Locale.getDefault().language == "zh") "待到 Until" else "Until", maxLines = 1, style = TextStyle(color = widgetBrand(theme), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (spacious) 18f else 16f)))
                Text(if (java.util.Locale.getDefault().language == "zh") "把值得期待的日子放在眼前" else "Keep important days in sight", maxLines = 1, style = TextStyle(color = secondaryInk(), fontWeight = FontWeight.Medium, fontSize = widgetSp(context, if (spacious) 10f else 9f)))
            }
            Text("▦◷", maxLines = 1, style = TextStyle(color = widgetBrand(theme), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (spacious) 18f else 16f)))
        }
        Spacer(GlanceModifier.height(if (spacious) 8.dp else 4.dp))
        LargeHeroEvent(context, events.first(), compact = !spacious, heightDp = plan.heroHeightDp)
        if (upcoming.isNotEmpty()) {
            Spacer(GlanceModifier.height(if (spacious) 8.dp else 4.dp))
            Text(if (java.util.Locale.getDefault().language == "zh") "接下来的日子" else "Coming next", maxLines = 1, style = TextStyle(color = secondaryInk(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (spacious) 12f else 11f)))
            UpcomingEvents(context, upcoming, plan)
        }
    }
}

@androidx.compose.runtime.Composable
private fun MediumHeroEvent(context: Context, event: CountdownEvent) {
    val days = eventDays(event)
    val value = countdown(context, days)
    Column(
        modifier = GlanceModifier.fillMaxSize().cornerRadius(20.dp).background(heroColor(days))
            .padding(8.dp).clickable(actionStartActivity(eventIntent(context, event))),
    ) {
        if (LocalSize.current.height >= 150.dp) Row(GlanceModifier.fillMaxWidth()) {
            Text(categorySymbol(event), style = TextStyle(color = white(), fontSize = widgetSp(context, 12f)))
            Spacer(GlanceModifier.defaultWeight())
            Text(if (java.util.Locale.getDefault().language == "zh") "最近" else "NEXT", style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 8f)))
        }
        Spacer(GlanceModifier.defaultWeight())
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(value, maxLines = 1, modifier = GlanceModifier.padding(bottom = 2.dp), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = countdownSize(context, value, numeric = 27f, label = 24f)))
            if (shouldShowUnit(days)) {
                Spacer(GlanceModifier.width(3.dp))
                Text(context.getString(R.string.day_unit), maxLines = 1, modifier = GlanceModifier.padding(vertical = 3.dp), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 10f)))
            }
        }
        Text(event.title, maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, 11f)))
    }
}

@androidx.compose.runtime.Composable
private fun LargeHeroEvent(context: Context, event: CountdownEvent, compact: Boolean, heightDp: Int) {
    val days = eventDays(event)
    val value = countdown(context, days)
    Row(
        GlanceModifier.fillMaxWidth().height(heightDp.dp).cornerRadius(22.dp).background(heroColor(days)).padding(if (compact) 10.dp else 14.dp)
            .clickable(actionStartActivity(eventIntent(context, event))),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(GlanceModifier.defaultWeight()) {
            Text("${categorySymbol(event)}  ${categoryName(context, event)}", maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (compact) 10f else 11f)))
            Spacer(GlanceModifier.height(if (compact) 3.dp else 5.dp))
            Text(event.title, maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (compact) 16f else 18f)))
            Text(dateText(event), maxLines = 1, style = TextStyle(color = white(), fontWeight = FontWeight.Medium, fontSize = widgetSp(context, if (compact) 9f else 10f)))
        }
        Spacer(GlanceModifier.width(14.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                value,
                maxLines = 1,
                modifier = GlanceModifier.padding(bottom = 2.dp),
                style = TextStyle(
                    color = white(),
                    fontWeight = FontWeight.Bold,
                    fontSize = countdownSize(context, value, numeric = if (compact) 36f else 42f, label = if (compact) 31f else 35f),
                ),
            )
            if (shouldShowUnit(days)) {
                Spacer(GlanceModifier.width(4.dp))
                Text(context.getString(R.string.day_unit), maxLines = 1, modifier = GlanceModifier.padding(vertical = 4.dp), style = TextStyle(color = white(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (compact) 10f else 11f)))
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun UpcomingEvents(context: Context, events: List<CountdownEvent>, plan: WidgetLayoutPlan) {
    // Glance Column supports at most ten direct children. Group rows without spacer children.
    Column(GlanceModifier.fillMaxWidth()) {
        events.chunked(8).forEach { group ->
            Column(GlanceModifier.fillMaxWidth()) {
                group.forEach { event ->
                    Box(GlanceModifier.fillMaxWidth().padding(top = plan.rowGapDp.dp)) {
                        UpcomingEvent(context, event, large = plan.layout != WidgetLayout.Medium, rowHeightDp = plan.rowHeightDp)
                    }
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun UpcomingEvent(context: Context, event: CountdownEvent, large: Boolean, rowHeightDp: Int) {
    val days = eventDays(event)
    val accent = urgencyAccent(days)
    Row(
        GlanceModifier.fillMaxWidth()
            .height(rowHeightDp.dp)
            .cornerRadius(13.dp).background(ColorProvider(Color.White, Color.White))
            .padding(horizontal = if (large) 10.dp else 7.dp)
            .clickable(actionStartActivity(eventIntent(context, event))),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            GlanceModifier.size(if (large) 26.dp else 18.dp).cornerRadius(if (large) 13.dp else 9.dp).background(urgencySoft(days)),
            contentAlignment = Alignment.Center,
        ) {
            Text(categorySymbol(event), style = TextStyle(color = ColorProvider(accent, accent), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (large) 11f else 10f)))
        }
        Spacer(GlanceModifier.width(if (large) 10.dp else 7.dp))
        Column(GlanceModifier.defaultWeight()) {
            Text(event.title, maxLines = 1, style = TextStyle(color = ink(), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (large) 13f else 11f)))
            Text(dateText(event), maxLines = 1, style = TextStyle(color = secondaryInk(), fontWeight = FontWeight.Medium, fontSize = widgetSp(context, if (large) 10f else 8f)))
        }
        Text(
            daysLater(context, days),
            maxLines = 1,
            modifier = GlanceModifier.padding(bottom = 1.dp),
            style = TextStyle(color = ColorProvider(accent, accent), fontWeight = FontWeight.Bold, fontSize = widgetSp(context, if (large) 12f else 11f)),
        )
    }
}

private fun countdown(context: Context, days: Int): String = when (days) {
    0 -> context.getString(R.string.countdown_today)
    1 -> context.getString(R.string.countdown_tomorrow)
    2 -> context.getString(R.string.countdown_day_after)
    else -> if (days > 999) context.getString(R.string.countdown_distant) else days.coerceAtLeast(0).toString()
}

private fun shouldShowUnit(days: Int): Boolean = days in 3..999

/**
 * Launcher widgets have a fixed host viewport while OEM launchers still apply the
 * system font scale. Capping only the widget's effective scale prevents glyphs
 * from being cropped without changing the app's accessibility font behavior.
 */
private fun widgetSp(context: Context, value: Float) = run {
    val fontScale = context.resources.configuration.fontScale.coerceAtLeast(0.5f)
    val safeScale = widgetFontScale(fontScale)
    (value * safeScale / fontScale).sp
}

private fun countdownSize(context: Context, value: String, numeric: Float, label: Float) = widgetSp(
    context,
    when {
        value.all(Char::isDigit) -> numeric
        value.length <= 2 -> label
        value.length <= 5 -> label * .72f
        else -> label * .56f
    },
)

private fun daysLater(context: Context, days: Int): String = when {
    days <= 2 -> countdown(context, days)
    days > 999 -> context.getString(R.string.countdown_distant)
    java.util.Locale.getDefault().language == "zh" -> "${days}天后"
    else -> "${days}d"
}

private fun eventDays(event: CountdownEvent): Int =
    CountdownCalculator.daysUntil(CountdownCalculator.nextOccurrence(event))

private fun eventIntent(context: Context, event: CountdownEvent): Intent =
    Intent(context, MainActivity::class.java).apply { data = "until://event/${event.id}".toUri() }

private fun urgencyAccent(days: Int): Color = when {
    days <= 0 -> Color(0xFFC44761)
    days <= 7 -> Color(0xFFD47A20)
    days <= 30 -> Color(0xFF5270C9)
    else -> Color(0xFF2F8E75)
}

private fun heroColor(days: Int): GlanceColorProvider {
    val accent = urgencyAccent(days)
    return ColorProvider(accent, accent)
}

private fun urgencySoft(days: Int): GlanceColorProvider = when {
    days <= 0 -> ColorProvider(Color(0xFFF8E5EA), Color(0xFFF8E5EA))
    days <= 7 -> ColorProvider(Color(0xFFFFF0D9), Color(0xFFFFF0D9))
    days <= 30 -> ColorProvider(Color(0xFFE9EEFC), Color(0xFFE9EEFC))
    else -> ColorProvider(Color(0xFFE3F2ED), Color(0xFFE3F2ED))
}

private fun dateText(event: CountdownEvent): String {
    val locale = java.util.Locale.getDefault()
    val chinese = locale.language == "zh"
    val next = CountdownCalculator.nextOccurrence(event)
    val solar = if (chinese) "${next.monthValue}月${next.dayOfMonth}日" else next.format(java.time.format.DateTimeFormatter.ofPattern("MMM d", locale))
    if (event.dateCalendar != com.khalil.until.core.model.EventDateCalendar.Lunar) return solar
    val lunarDate = if (event.recurrence == com.khalil.until.core.model.EventRecurrence.Yearly) event.originalDate else next
    val lunar = com.khalil.until.core.domain.LunarCalendar.formattedMonthDay(lunarDate, chinese)
    return if (chinese) "农历 $lunar · $solar" else "Lunar $lunar · $solar"
}
private fun categorySymbol(event: CountdownEvent) = when (event.category.name) { "Birthday" -> "🎂"; "Anniversary" -> "❤"; else -> "★" }
private fun categoryName(context: Context, event: CountdownEvent) = when (event.category.name) {
    "Birthday" -> context.getString(R.string.filter_birthday)
    "Anniversary" -> context.getString(R.string.filter_anniversary)
    else -> context.getString(R.string.filter_custom)
}
private fun harmonyTeal() = ColorProvider(Color(0xFF0A9B86), Color(0xFF0A9B86))
private fun widgetBrand(theme: WidgetTheme) = when (theme) {
    WidgetTheme.Colorful -> harmonyTeal()
    WidgetTheme.Indigo -> ColorProvider(Color(0xFF4B66C1), Color(0xFF4B66C1))
    WidgetTheme.Midnight -> ColorProvider(Color(0xFF1E2945), Color(0xFF1E2945))
}
private fun widgetBackground(theme: WidgetTheme) = when (theme) {
    WidgetTheme.Colorful -> ColorProvider(Color(0xFFF5F7FA), Color(0xFFF5F7FA))
    WidgetTheme.Indigo -> ColorProvider(Color(0xFFF1F3FB), Color(0xFFF1F3FB))
    WidgetTheme.Midnight -> ColorProvider(Color(0xFFECEFF5), Color(0xFFECEFF5))
}
private fun ink() = ColorProvider(Color(0xFF1C1C1E), Color(0xFF1C1C1E))
private fun secondaryInk() = ColorProvider(Color(0xFF6F7B77), Color(0xFF6F7B77))
private fun white() = ColorProvider(Color.White, Color.White)
