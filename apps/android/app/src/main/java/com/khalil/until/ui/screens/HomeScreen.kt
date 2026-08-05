package com.khalil.until.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.khalil.until.R
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.EventCategory
import com.khalil.until.ui.components.EventRow
import com.khalil.until.ui.rememberCurrentDate
import com.khalil.until.ui.theme.UrgencyToday
import java.time.LocalTime

private enum class HomeFilter { All, Birthday, Anniversary, Custom }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    events: List<CountdownEvent>,
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    onAdd: () -> Unit,
    onEvent: (String) -> Unit,
    showWidgetActivation: Boolean,
    onWidgetSetup: () -> Unit,
    onDismissWidgetActivation: () -> Unit,
) {
    val context = LocalContext.current
    val referenceDate by rememberCurrentDate()
    var query by remember { mutableStateOf("") }
    var filter by remember { mutableStateOf(HomeFilter.All) }
    val calendarPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { onRefresh() }
    val visible = CountdownCalculator.sorted(events, referenceDate).filter { event ->
        (query.isBlank() || event.title.contains(query, true) || event.notes.orEmpty().contains(query, true)) && when (filter) {
            HomeFilter.All -> true
            HomeFilter.Birthday -> event.category == EventCategory.Birthday
            HomeFilter.Anniversary -> event.category == EventCategory.Anniversary
            HomeFilter.Custom -> event.category == EventCategory.Custom
        }
    }
    val today = visible.filter { CountdownCalculator.daysUntil(CountdownCalculator.nextOccurrence(it, referenceDate), referenceDate) == 0 }
    val upcoming = visible.filterNot { it in today }

    PullToRefreshBox(isRefreshing = isRefreshing, onRefresh = onRefresh, modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            item { HarmonyHeader(onAdd, onWidgetSetup, events.isNotEmpty()) }
            item { HarmonySearch(query, onValueChange = { query = it }) }
            item { FilterBar(filter) { filter = it } }
            if (!calendarPermission) {
                item { PermissionBanner { permissionLauncher.launch(arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)) } }
            }
            if (showWidgetActivation) {
                item { WidgetActivationCard(onWidgetSetup, onDismissWidgetActivation) }
            }
            if (LocalTime.now().hour in 0..4 && events.isNotEmpty()) {
                item {
                    Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                        Text("☾  ", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 14.sp)
                        Text(stringResource(R.string.easter_night), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                    }
                }
            }
            if (visible.isEmpty()) {
                item { EmptyState(query.isNotBlank() || filter != HomeFilter.All, onAdd) }
            } else {
                if (today.isNotEmpty()) {
                    item { SectionTitle(stringResource(R.string.section_today), today.size, true) }
                    items(today, key = { it.id }) { EventRow(it, onClick = { onEvent(it.id) }, referenceDate = referenceDate) }
                }
                if (upcoming.isNotEmpty()) {
                    item { SectionTitle(stringResource(R.string.section_upcoming), upcoming.size, false) }
                    items(upcoming, key = { it.id }) { EventRow(it, onClick = { onEvent(it.id) }, referenceDate = referenceDate) }
                }
            }
        }
    }
}

@Composable
private fun HarmonyHeader(onAdd: () -> Unit, onWidgetSetup: () -> Unit, hasEvents: Boolean) {
    val context = LocalContext.current
    Row(Modifier.fillMaxWidth().padding(bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(stringResource(R.string.home_title), fontSize = 30.sp, lineHeight = 36.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.weight(1f))
        if (hasEvents) {
            Box(
                Modifier.size(40.dp).clip(CircleShape).clickable(onClick = onWidgetSetup)
                    .semantics { contentDescription = context.getString(R.string.widget_setup_title) },
                contentAlignment = Alignment.Center,
            ) { Text("▦", color = MaterialTheme.colorScheme.primary, fontSize = 21.sp, fontWeight = FontWeight.Bold) }
        }
        Box(
            Modifier.size(40.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary).clickable(onClick = onAdd)
                .semantics { contentDescription = context.getString(R.string.accessibility_add) },
            contentAlignment = Alignment.Center,
        ) { Text("＋", color = MaterialTheme.colorScheme.onPrimary, fontSize = 22.sp, lineHeight = 24.sp, fontWeight = FontWeight.Bold) }
    }
}

@Composable
private fun WidgetActivationCard(onSetup: () -> Unit, onDismiss: () -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.primaryContainer) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(stringResource(R.string.widget_activation_title), fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Text(stringResource(R.string.widget_activation_message), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp, lineHeight = 18.sp)
            Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.widget_setup_later), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp, modifier = Modifier.padding(10.dp).clickable(onClick = onDismiss))
                Spacer(Modifier.width(6.dp))
                Surface(onClick = onSetup, shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.primary) {
                    Text(stringResource(R.string.widget_activation_action), color = MaterialTheme.colorScheme.onPrimary, fontSize = 13.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 13.dp, vertical = 9.dp))
                }
            }
        }
    }
}

@Composable
private fun HarmonySearch(value: String, onValueChange: (String) -> Unit) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
        modifier = Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(14.dp)).background(MaterialTheme.colorScheme.surfaceVariant),
        decorationBox = { inner ->
            Box(Modifier.fillMaxSize().padding(horizontal = 14.dp), contentAlignment = Alignment.CenterStart) {
                if (value.isEmpty()) Text(stringResource(R.string.search_hint), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 15.sp)
                inner()
            }
        },
    )
}

@Composable
private fun PermissionBanner(onGrant: () -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.primaryContainer) {
        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.size(38.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surface), contentAlignment = Alignment.Center) {
                Text("◇", color = MaterialTheme.colorScheme.primary, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(stringResource(R.string.calendar_permission_title), fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                Text(stringResource(R.string.calendar_permission_message), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp, lineHeight = 15.sp)
            }
            Surface(onClick = onGrant, shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.primary) {
                Text(stringResource(R.string.grant_permission), color = MaterialTheme.colorScheme.onPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 12.dp, vertical = 9.dp))
            }
        }
    }
}

@Composable
private fun FilterBar(selected: HomeFilter, onSelected: (HomeFilter) -> Unit) {
    val options = listOf(HomeFilter.All to stringResource(R.string.filter_all), HomeFilter.Birthday to stringResource(R.string.filter_birthday), HomeFilter.Anniversary to stringResource(R.string.filter_anniversary), HomeFilter.Custom to stringResource(R.string.filter_custom))
    Row(Modifier.fillMaxWidth().height(42.dp).clip(RoundedCornerShape(14.dp)).background(MaterialTheme.colorScheme.surfaceVariant).padding(4.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        options.forEach { (value, label) ->
            Surface(onClick = { onSelected(value) }, modifier = Modifier.weight(1f).height(34.dp), color = if (selected == value) MaterialTheme.colorScheme.surface else MaterialTheme.colorScheme.surfaceVariant, shape = RoundedCornerShape(11.dp), shadowElevation = if (selected == value) 1.dp else 0.dp) {
                Box(contentAlignment = Alignment.Center) {
                    Text(label, fontSize = 13.sp, fontWeight = if (selected == value) FontWeight.Bold else FontWeight.Medium, color = if (selected == value) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String, count: Int, today: Boolean) {
    Row(Modifier.fillMaxWidth().padding(start = 3.dp, end = 3.dp, top = 10.dp, bottom = 4.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.size(7.dp).clip(CircleShape).background(if (today) UrgencyToday else MaterialTheme.colorScheme.primary))
        Text(text, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.weight(1f))
        Text(stringResource(R.string.section_count, count), fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun EmptyState(hasSearch: Boolean, onAdd: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(top = 92.dp, start = 28.dp, end = 28.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(78.dp).clip(CircleShape).background(if (hasSearch) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) {
            Text(if (hasSearch) "⌕" else "＋", color = if (hasSearch) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.primary, fontSize = 34.sp)
        }
        Spacer(Modifier.height(18.dp))
        Text(if (hasSearch) stringResource(R.string.empty_search_title) else stringResource(R.string.empty_title), fontSize = 21.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text(if (hasSearch) stringResource(R.string.empty_search_message) else stringResource(R.string.empty_message), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 14.sp)
        if (!hasSearch) {
            Spacer(Modifier.height(18.dp))
            Button(onClick = onAdd, shape = RoundedCornerShape(14.dp), contentPadding = PaddingValues(horizontal = 18.dp), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary), modifier = Modifier.height(42.dp)) { Text(stringResource(R.string.add_event), fontSize = 15.sp, fontWeight = FontWeight.Medium) }
        }
    }
}
