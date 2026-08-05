package com.khalil.until.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khalil.until.R
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.ui.components.EventPresentation
import com.khalil.until.widget.WidgetSettings
import com.khalil.until.widget.WidgetTheme

@Composable
fun WidgetSetupScreen(
    events: List<CountdownEvent>,
    initialSettings: WidgetSettings,
    onBack: () -> Unit,
    onSave: (WidgetSettings) -> Unit,
) {
    var featuredEventId by remember(initialSettings) { mutableStateOf(initialSettings.featuredEventId) }
    var theme by remember(initialSettings) { mutableStateOf(initialSettings.theme) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Text(stringResource(R.string.widget_setup_title), fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(6.dp))
            Text(stringResource(R.string.widget_setup_description), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 14.sp, lineHeight = 20.sp)
        }
        item { SetupSectionTitle(stringResource(R.string.widget_setup_display)) }
        item {
            SelectionCard(selected = featuredEventId == null, onClick = { featuredEventId = null }) {
                RadioButton(selected = featuredEventId == null, onClick = null)
                Spacer(Modifier.width(10.dp))
                Column {
                    Text(stringResource(R.string.widget_setup_automatic), fontWeight = FontWeight.SemiBold)
                    Text(stringResource(R.string.widget_setup_automatic_description), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                }
            }
        }
        items(events, key = { it.id }) { event ->
            SelectionCard(selected = featuredEventId == event.id, onClick = { featuredEventId = event.id }) {
                RadioButton(selected = featuredEventId == event.id, onClick = null)
                Spacer(Modifier.width(10.dp))
                Text(EventPresentation.categorySymbol(event.category), fontSize = 18.sp)
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text(event.title, fontWeight = FontWeight.SemiBold)
                    Text(stringResource(R.string.widget_setup_featured_description), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                }
            }
        }
        item { SetupSectionTitle(stringResource(R.string.widget_setup_theme)) }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                WidgetTheme.entries.forEach { option ->
                    val selected = theme == option
                    Surface(
                        modifier = Modifier.weight(1f).clickable { theme = option },
                        shape = RoundedCornerShape(16.dp),
                        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
                        tonalElevation = if (selected) 1.dp else 0.dp,
                    ) {
                        Column(Modifier.padding(vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(widgetThemeName(option), fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium, fontSize = 13.sp)
                        }
                    }
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = onBack, modifier = Modifier.weight(1f), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant, contentColor = MaterialTheme.colorScheme.onSurface)) { Text(stringResource(R.string.widget_setup_later)) }
                Button(onClick = { onSave(WidgetSettings(featuredEventId, theme)) }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.widget_setup_save)) }
            }
        }
    }
}

@Composable
private fun SetupSectionTitle(value: String) = Text(value, fontSize = 16.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 8.dp))

@Composable
private fun SelectionCard(selected: Boolean, onClick: () -> Unit, content: @Composable RowScope.() -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(18.dp),
        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
    ) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically, content = content)
    }
}

@Composable
private fun widgetThemeName(theme: WidgetTheme) = stringResource(
    when (theme) {
        WidgetTheme.Colorful -> R.string.widget_theme_colorful
        WidgetTheme.Indigo -> R.string.widget_theme_indigo
        WidgetTheme.Midnight -> R.string.widget_theme_midnight
    },
)
}
