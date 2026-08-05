package com.khalil.until.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.khalil.until.R
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.core.model.EventDateCalendar
import com.khalil.until.core.model.EventSource
import com.khalil.until.core.model.ReminderLeadTime
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventFormScreen(existing: CountdownEvent?, isSaving: Boolean, onCancel: () -> Unit, onSave: (CountdownEvent, Boolean) -> Unit) {
    val context = LocalContext.current
    var title by rememberSaveable(existing?.id) { mutableStateOf(existing?.title.orEmpty()) }
    var category by rememberSaveable(existing?.id) { mutableStateOf(existing?.category ?: EventCategory.Birthday) }
    var calendar by rememberSaveable(existing?.id) { mutableStateOf(existing?.dateCalendar ?: EventDateCalendar.Gregorian) }
    var dateEpochDay by rememberSaveable(existing?.id) { mutableStateOf(existing?.originalEpochDay ?: LocalDate.now().toEpochDay()) }
    var notes by rememberSaveable(existing?.id) { mutableStateOf(existing?.notes.orEmpty()) }
    var reminder by rememberSaveable(existing?.id) { mutableStateOf(existing?.reminderLeadTime ?: ReminderLeadTime.None) }
    var syncCalendar by rememberSaveable(existing?.id) { mutableStateOf(existing?.source != null && existing.source != EventSource.Local) }
    var titleError by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }
    val titleFocusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    val notificationPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    val calendarPermissions = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants -> syncCalendar = grants[Manifest.permission.WRITE_CALENDAR] == true }

    LaunchedEffect(titleError) {
        if (titleError) {
            titleFocusRequester.requestFocus()
            keyboard?.show()
        }
    }

    fun submit() {
        val trimmed = title.trim()
        if (trimmed.isEmpty()) { titleError = true; return }
        onSave(
            CountdownEvent(
                id = existing?.id ?: java.util.UUID.randomUUID().toString(),
                title = trimmed,
                originalEpochDay = dateEpochDay,
                category = category,
                dateCalendar = if (category == EventCategory.Custom) EventDateCalendar.Gregorian else calendar,
                source = existing?.source ?: EventSource.Local,
                calendarEventId = existing?.calendarEventId,
                calendarItemId = existing?.calendarItemId,
                notes = notes.trim().ifBlank { null },
                reminderLeadTime = reminder,
            ),
            syncCalendar,
        )
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = { HarmonyFormHeader(existing != null, onCancel) },
        bottomBar = {
            Box(Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.background).imePadding().padding(start = 12.dp, end = 12.dp, top = 8.dp, bottom = 14.dp)) {
                Button(onClick = ::submit, enabled = !isSaving, modifier = Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(18.dp), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)) {
                    Text(if (isSaving) stringResource(R.string.saving) else stringResource(R.string.save), fontSize = 17.sp, fontWeight = FontWeight.Bold)
                }
            }
        },
    ) { insets ->
        Column(
            Modifier.fillMaxSize().padding(insets).verticalScroll(rememberScrollState()).imePadding().padding(start = 20.dp, end = 20.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Surface(
                    shape = RoundedCornerShape(22.dp),
                    color = MaterialTheme.colorScheme.surface,
                    border = if (titleError) BorderStroke(1.dp, MaterialTheme.colorScheme.error.copy(alpha = .65f)) else null,
                ) {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("✦", color = MaterialTheme.colorScheme.primary, fontSize = 22.sp, modifier = Modifier.width(28.dp))
                        BasicTextField(
                            value = title,
                            onValueChange = { title = it; titleError = false },
                            singleLine = true,
                            textStyle = MaterialTheme.typography.titleLarge.copy(fontSize = 20.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface),
                            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                            modifier = Modifier.weight(1f).height(54.dp).focusRequester(titleFocusRequester),
                            decorationBox = { inner -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.CenterStart) { if (title.isEmpty()) Text(stringResource(R.string.title_placeholder), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 18.sp); inner() } },
                        )
                    }
                }
                AnimatedVisibility(
                    visible = titleError,
                    enter = fadeIn() + expandVertically(),
                    exit = fadeOut() + shrinkVertically(),
                ) {
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(MaterialTheme.colorScheme.errorContainer).padding(horizontal = 12.dp, vertical = 9.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Box(Modifier.size(18.dp).clip(CircleShape).background(MaterialTheme.colorScheme.error), contentAlignment = Alignment.Center) {
                            Text("!", color = MaterialTheme.colorScheme.surface, fontWeight = FontWeight.Bold, fontSize = 11.sp)
                        }
                        Text(stringResource(R.string.title_required), color = MaterialTheme.colorScheme.error, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    }
                }
            }

            SegmentedRow(
                options = listOf(EventCategory.Birthday to stringResource(R.string.filter_birthday), EventCategory.Anniversary to stringResource(R.string.filter_anniversary), EventCategory.Custom to stringResource(R.string.filter_custom)),
                selected = category,
            ) { category = it; if (it == EventCategory.Custom) calendar = EventDateCalendar.Gregorian }

            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                Row(
                    Modifier.fillMaxWidth().height(78.dp).clickable { showDatePicker = true }.padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("◷", color = MaterialTheme.colorScheme.primary, fontSize = 25.sp, modifier = Modifier.width(38.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(stringResource(R.string.date), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
                        Text(LocalDate.ofEpochDay(dateEpochDay).format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG)), fontSize = 19.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                    Text("⌄", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 20.sp)
                }
            }

            ReminderCard(reminder) {
                reminder = it
                if (it != ReminderLeadTime.None && android.os.Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
            }

            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                BasicTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    textStyle = MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, color = MaterialTheme.colorScheme.onSurface),
                    cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                    modifier = Modifier.fillMaxWidth().height(66.dp).padding(horizontal = 14.dp),
                    decorationBox = { inner -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.CenterStart) { if (notes.isEmpty()) Text(stringResource(R.string.notes_placeholder), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 16.sp); inner() } },
                )
            }

            if (calendar == EventDateCalendar.Gregorian) {
                Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                    Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("▣", color = MaterialTheme.colorScheme.primary, fontSize = 20.sp, modifier = Modifier.width(34.dp))
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(stringResource(R.string.sync_calendar), fontSize = 16.sp, fontWeight = FontWeight.Medium)
                            Text(stringResource(R.string.sync_calendar_description), fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Switch(
                            checked = syncCalendar,
                            colors = SwitchDefaults.colors(checkedTrackColor = MaterialTheme.colorScheme.primary, checkedThumbColor = MaterialTheme.colorScheme.surface),
                            onCheckedChange = { checked ->
                                if (checked && (ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALENDAR) != PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED)) calendarPermissions.launch(arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)) else syncCalendar = checked
                            },
                        )
                    }
                }
            }
        }
    }

    if (showDatePicker) {
        val selected = LocalDate.ofEpochDay(dateEpochDay).atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
        val pickerState = rememberDatePickerState(initialSelectedDateMillis = selected)
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = { TextButton(onClick = { pickerState.selectedDateMillis?.let { dateEpochDay = Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate().toEpochDay() }; showDatePicker = false }) { Text(stringResource(R.string.done)) } },
            dismissButton = { TextButton(onClick = { showDatePicker = false }) { Text(stringResource(R.string.cancel)) } },
        ) {
            Column {
                if (category != EventCategory.Custom) {
                    SegmentedRow(
                        options = listOf(EventDateCalendar.Gregorian to stringResource(R.string.gregorian), EventDateCalendar.Lunar to stringResource(R.string.lunar)),
                        selected = calendar,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
                    ) { calendar = it; if (it == EventDateCalendar.Lunar) syncCalendar = false }
                }
                DatePicker(state = pickerState)
            }
        }
    }
}

@Composable
private fun HarmonyFormHeader(editing: Boolean, onBack: () -> Unit) {
    Row(Modifier.fillMaxWidth().height(76.dp).padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(42.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surface).clickable(onClick = onBack), contentAlignment = Alignment.Center) { Text("‹", fontSize = 30.sp, lineHeight = 32.sp) }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(if (editing) stringResource(R.string.edit_event) else stringResource(R.string.add_event), fontSize = 26.sp, fontWeight = FontWeight.Bold)
            Text(stringResource(R.string.form_subtitle), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
        }
    }
}

@Composable
private fun <T> SegmentedRow(options: List<Pair<T, String>>, selected: T, outerColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.surfaceVariant, selectedColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.surface, modifier: Modifier = Modifier, onSelected: (T) -> Unit) {
    Row(modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(outerColor).padding(5.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        options.forEach { (value, label) ->
            Surface(onClick = { onSelected(value) }, modifier = Modifier.weight(1f).height(42.dp), shape = RoundedCornerShape(12.dp), color = if (selected == value) selectedColor else outerColor) {
                Box(contentAlignment = Alignment.Center) { Text(label, fontSize = 13.sp, fontWeight = if (selected == value) FontWeight.Bold else FontWeight.Medium, color = if (selected == value) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant) }
            }
        }
    }
}

@Composable
private fun ReminderCard(selected: ReminderLeadTime, onSelected: (ReminderLeadTime) -> Unit) {
    val options = listOf(ReminderLeadTime.None to stringResource(R.string.reminder_none), ReminderLeadTime.SameDay to stringResource(R.string.reminder_same_day), ReminderLeadTime.OneDay to stringResource(R.string.reminder_one_day), ReminderLeadTime.ThreeDays to stringResource(R.string.reminder_three_days), ReminderLeadTime.SevenDays to stringResource(R.string.reminder_seven_days))
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) { Text("◷", color = MaterialTheme.colorScheme.primary, fontSize = 21.sp, modifier = Modifier.width(28.dp)); Text(stringResource(R.string.reminder), fontSize = 16.sp, fontWeight = FontWeight.Bold) }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) { options.take(3).forEach { (v, l) -> ReminderOption(v, l, selected, Modifier.weight(1f), onSelected) } }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(9.dp)) { options.drop(3).forEach { (v, l) -> ReminderOption(v, l, selected, Modifier.weight(1f), onSelected) } }
        }
    }
}

@Composable
private fun ReminderOption(value: ReminderLeadTime, label: String, selected: ReminderLeadTime, modifier: Modifier, onSelected: (ReminderLeadTime) -> Unit) {
    Surface(onClick = { onSelected(value) }, modifier = modifier.height(42.dp), shape = RoundedCornerShape(14.dp), color = if (selected == value) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant) {
        Box(contentAlignment = Alignment.Center) { Text(label, fontSize = 12.sp, fontWeight = if (selected == value) FontWeight.Bold else FontWeight.Medium, color = if (selected == value) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}
