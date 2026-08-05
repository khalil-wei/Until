package com.khalil.until.ui.components

import android.content.Context
import com.khalil.until.R
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.domain.LunarCalendar
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventSource
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

object EventPresentation {
    fun categoryLabel(context: Context, category: EventCategory): String = context.getString(
        when (category) {
            EventCategory.Birthday -> R.string.filter_birthday
            EventCategory.Anniversary -> R.string.filter_anniversary
            EventCategory.Custom -> R.string.filter_custom
        },
    )

    fun categorySymbol(category: EventCategory): String = when (category) {
        EventCategory.Birthday -> "🎂"
        EventCategory.Anniversary -> "❤"
        EventCategory.Custom -> "★"
    }

    fun dateText(event: CountdownEvent, locale: Locale = Locale.getDefault()): String {
        val next = CountdownCalculator.nextOccurrence(event)
        return if (event.dateCalendar == EventDateCalendar.Lunar) {
            val prefix = if (locale.language == "zh") "农历 " else "Lunar "
            prefix + LunarCalendar.formattedMonthDay(event.originalDate, locale.language == "zh")
        } else {
            next.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(locale))
        }
    }

    fun countdownText(context: Context, days: Int): String = when {
        days < 0 -> context.getString(R.string.countdown_today)
        days == 0 -> context.getString(R.string.countdown_today)
        days == 1 -> context.getString(R.string.countdown_tomorrow)
        days == 2 -> context.getString(R.string.countdown_day_after)
        days > 999 -> context.getString(R.string.countdown_distant)
        else -> context.getString(R.string.countdown_days, days)
    }

    fun sourceLabel(context: Context, source: EventSource): String = context.getString(
        when (source) {
            EventSource.Local -> R.string.source_local
            EventSource.AppCalendar -> R.string.source_app_calendar
            EventSource.ImportedCalendar -> R.string.source_imported_calendar
        },
    )

    fun specialMessageRes(days: Int, chinese: Boolean): Int? = when {
        days == 42 -> R.string.easter_42
        days == 365 -> R.string.easter_365
        days == 520 && chinese -> R.string.easter_520
        else -> null
    }
}
