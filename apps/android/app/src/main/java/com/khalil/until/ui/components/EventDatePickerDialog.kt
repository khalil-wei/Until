package com.khalil.until.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.khalil.until.R
import com.khalil.until.core.domain.LunarCalendar
import com.khalil.until.core.domain.LunarDate
import com.khalil.until.core.model.EventDateCalendar
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import androidx.compose.ui.platform.LocalConfiguration

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDatePickerDialog(
    initialDate: LocalDate,
    initialCalendar: EventDateCalendar,
    allowLunar: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (LocalDate, EventDateCalendar) -> Unit,
) {
    var calendar by rememberSaveable { mutableStateOf(initialCalendar) }
    var lunarEpochDay by rememberSaveable { mutableStateOf(initialDate.toEpochDay()) }
    val state = rememberDatePickerState(
        initialSelectedDateMillis = initialDate.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
        yearRange = minOf(1900, initialDate.year)..maxOf(2101, initialDate.year),
    )
    val date = if (calendar == EventDateCalendar.Lunar) LocalDate.ofEpochDay(lunarEpochDay)
    else state.selectedDateMillis?.let { Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate() }
    val valid = date != null && (calendar != EventDateCalendar.Lunar || LunarCalendar.solarToLunar(date) != null)

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(enabled = valid, onClick = { date?.let { onConfirm(it, calendar) } }) {
                Text(stringResource(R.string.done))
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    ) {
        Column {
            if (allowLunar) {
                Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp)) {
                    listOf(EventDateCalendar.Gregorian to R.string.gregorian, EventDateCalendar.Lunar to R.string.lunar).forEach { (value, label) ->
                        TextButton(
                            modifier = Modifier.weight(1f).semantics { selected = calendar == value },
                            onClick = {
                                if (calendar != value) {
                                    // Both modes edit the same actual day; only the calendar representation changes.
                                    date?.let {
                                        lunarEpochDay = it.toEpochDay()
                                        state.selectedDateMillis = it.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
                                        state.displayedMonthMillis = it.withDayOfMonth(1).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
                                    }
                                    calendar = value
                                }
                            },
                        ) {
                            Text(stringResource(label), fontWeight = if (calendar == value) FontWeight.Bold else FontWeight.Normal)
                        }
                    }
                }
            }
            if (calendar == EventDateCalendar.Lunar) {
                LunarDatePicker(LocalDate.ofEpochDay(lunarEpochDay)) { lunarEpochDay = it.toEpochDay() }
            } else {
                DatePicker(state = state)
            }
        }
    }
}

@Composable
private fun LunarDatePicker(date: LocalDate, onDateSelected: (LocalDate) -> Unit) {
    val locale = LocalConfiguration.current.locales[0]
    val chinese = locale.language == "zh"
    val lunar = remember(date) { LunarCalendar.solarToLunar(date) }
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(LunarCalendar.formattedDate(date, chinese), style = MaterialTheme.typography.titleLarge)
        Text(
            stringResource(R.string.corresponding_gregorian, date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(locale))),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (lunar == null) {
            Text(stringResource(R.string.lunar_supported_range), color = MaterialTheme.colorScheme.error)
            TextButton(onClick = {
                val year = if (date.year < LunarCalendar.supportedYears.first) LunarCalendar.supportedYears.first else LunarCalendar.supportedYears.last
                onDateSelected(requireNotNull(LunarCalendar.lunarToSolar(LunarDate(year, 1, 1, false))))
            }) { Text(stringResource(R.string.choose_supported_lunar_date)) }
        } else {
            fun select(candidate: LunarDate) {
                val normalized = requireNotNull(LunarCalendar.normalizeSelection(candidate))
                onDateSelected(requireNotNull(LunarCalendar.lunarToSolar(normalized)))
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                LunarColumn(
                    stringResource(R.string.year_label), LunarCalendar.supportedYears.toList(), lunar.year,
                    { if (chinese) "${it}年" else it.toString() }, Modifier.weight(1f),
                ) { select(lunar.copy(year = it)) }
                LunarColumn(
                    stringResource(R.string.month_label), LunarCalendar.months(lunar.year), lunar.month to lunar.isLeapMonth,
                    { LunarCalendar.monthLabel(it.first, it.second, chinese) }, Modifier.weight(1f),
                ) { select(lunar.copy(month = it.first, isLeapMonth = it.second)) }
                LunarColumn(
                    stringResource(R.string.day_label), (1..requireNotNull(LunarCalendar.daysInMonth(lunar.year, lunar.month, lunar.isLeapMonth))).toList(), lunar.day,
                    { LunarCalendar.dayLabel(it, chinese) }, Modifier.weight(1f),
                ) { select(lunar.copy(day = it)) }
            }
        }
    }
}

@Composable
private fun <T> LunarColumn(label: String, values: List<T>, selectedValue: T, text: (T) -> String, modifier: Modifier, onSelected: (T) -> Unit) {
    val index = values.indexOf(selectedValue).coerceAtLeast(0)
    val state = rememberLazyListState(initialFirstVisibleItemIndex = index)
    LaunchedEffect(index, values) {
        if (state.layoutInfo.visibleItemsInfo.none { it.index == index }) state.scrollToItem(index)
    }
    Column(modifier) {
        Text(label, modifier = Modifier.padding(horizontal = 8.dp), style = MaterialTheme.typography.labelMedium)
        LazyColumn(state = state, modifier = Modifier.height(240.dp)) {
            itemsIndexed(values) { _, value ->
                val isSelected = value == selectedValue
                TextButton(
                    onClick = { onSelected(value) },
                    modifier = Modifier.fillMaxWidth()
                        .background(if (isSelected) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surface)
                        .semantics { selected = isSelected },
                ) { Text(text(value), fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal) }
            }
        }
    }
}
