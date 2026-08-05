package com.khalil.until

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.glance.appwidget.updateAll
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink
import com.khalil.until.core.model.EventSource
import com.khalil.until.platform.calendar.AndroidCalendarService
import com.khalil.until.ui.screens.EventDetailScreen
import com.khalil.until.ui.screens.EventFormScreen
import com.khalil.until.ui.screens.HomeScreen
import com.khalil.until.ui.screens.WidgetSetupScreen
import com.khalil.until.ui.theme.UntilTheme
import com.khalil.until.widget.UntilWidget
import com.khalil.until.widget.WidgetSettingsStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            UntilTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    val app = application as UntilApplication
                    val events by app.repository.events.collectAsStateWithLifecycle(initialValue = emptyList())
                    val journey by app.userJourneyStore.state.collectAsStateWithLifecycle(initialValue = com.khalil.until.data.UserJourneyState())
                    val navController = rememberNavController()
                    val scope = rememberCoroutineScope()
                    val calendarService = remember { AndroidCalendarService(this@MainActivity) }
                    var refreshing by remember { mutableStateOf(false) }
                    var saving by remember { mutableStateOf(false) }

                    suspend fun updateWidget() = UntilWidget().updateAll(this@MainActivity)

                    LaunchedEffect(events) {
                        updateWidget()
                    }

                    NavHost(navController = navController, startDestination = "home") {
                        composable("home") {
                            HomeScreen(
                                events = events,
                                isRefreshing = refreshing,
                                onRefresh = {
                                    scope.launch {
                                        refreshing = true
                                        withContext(Dispatchers.IO) {
                                            val merged = calendarService.importImportantEvents(events)
                                            app.repository.replaceAll(merged)
                                        }
                                        updateWidget()
                                        refreshing = false
                                    }
                                },
                                onAdd = { navController.navigate("add") },
                                onEvent = { navController.navigate("detail/$it") },
                                showWidgetActivation = events.isNotEmpty() && !journey.hasCompletedWidgetGuide,
                                onWidgetSetup = { navController.navigate("widget-setup") },
                                onDismissWidgetActivation = { scope.launch { app.userJourneyStore.completeWidgetGuide() } },
                            )
                        }

                        composable("add", deepLinks = listOf(navDeepLink { uriPattern = "until://add" })) {
                            EventFormScreen(
                                existing = null,
                                isSaving = saving,
                                onCancel = { navController.popBackStack() },
                                onSave = { draft, syncToCalendar ->
                                    scope.launch {
                                        val isFirstEvent = events.isEmpty()
                                        saving = true
                                        val saved = withContext(Dispatchers.IO) {
                                            val synced = if (syncToCalendar) calendarService.sync(draft) else draft.copy(source = EventSource.Local)
                                            app.repository.upsert(synced)
                                            app.reminderScheduler.schedule(synced)
                                            synced
                                        }
                                        updateWidget()
                                        saving = false
                                        if (syncToCalendar && saved.source == EventSource.Local) {
                                            Toast.makeText(this@MainActivity, R.string.calendar_sync_failed, Toast.LENGTH_LONG).show()
                                        }
                                        if (isFirstEvent && !journey.hasCompletedWidgetGuide) {
                                            navController.navigate("widget-setup") { popUpTo("home") }
                                        } else {
                                            navController.navigate("detail/${saved.id}") { popUpTo("home") }
                                        }
                                    }
                                },
                            )
                        }

                        composable("widget-setup") {
                            WidgetSetupScreen(
                                events = events,
                                initialSettings = WidgetSettingsStore.load(this@MainActivity),
                                onBack = {
                                    scope.launch { app.userJourneyStore.completeWidgetGuide() }
                                    navController.popBackStack()
                                },
                                onSave = { settings ->
                                    WidgetSettingsStore.save(this@MainActivity, settings)
                                    scope.launch {
                                        app.userJourneyStore.completeWidgetGuide()
                                        updateWidget()
                                    }
                                    navController.popBackStack()
                                },
                            )
                        }

                        composable(
                            route = "detail/{eventId}",
                            arguments = listOf(navArgument("eventId") { type = NavType.StringType }),
                            deepLinks = listOf(navDeepLink { uriPattern = "until://event/{eventId}" }),
                        ) { entry ->
                            val id = entry.arguments?.getString("eventId")
                            val event = events.firstOrNull { it.id == id }
                            if (event != null) {
                                EventDetailScreen(
                                    event = event,
                                    onDone = { navController.navigate("home") { popUpTo("home") { inclusive = true } } },
                                    onEdit = { navController.navigate("edit/${event.id}") },
                                    onDelete = { deleteCalendar ->
                                        scope.launch {
                                            val deleted = withContext(Dispatchers.IO) {
                                                if (deleteCalendar && !calendarService.deleteCalendarEvent(event)) return@withContext false
                                                app.repository.delete(event.id)
                                                app.reminderScheduler.cancel(event.id)
                                                true
                                            }
                                            if (deleted) {
                                                updateWidget()
                                                navController.navigate("home") { popUpTo("home") { inclusive = true } }
                                            } else {
                                                Toast.makeText(this@MainActivity, R.string.calendar_delete_failed, Toast.LENGTH_LONG).show()
                                            }
                                        }
                                    },
                                )
                            }
                        }

                        composable(
                            route = "edit/{eventId}",
                            arguments = listOf(navArgument("eventId") { type = NavType.StringType }),
                        ) { entry ->
                            val id = entry.arguments?.getString("eventId")
                            val existing = events.firstOrNull { it.id == id }
                            if (existing != null) {
                                EventFormScreen(
                                    existing = existing,
                                    isSaving = saving,
                                    onCancel = { navController.popBackStack() },
                                    onSave = { draft, syncToCalendar ->
                                        scope.launch {
                                            saving = true
                                            val saved = withContext(Dispatchers.IO) {
                                                val synced = if (syncToCalendar) {
                                                    calendarService.sync(draft)
                                                } else {
                                                    val removedFromCalendar = existing.source == EventSource.AppCalendar && calendarService.deleteCalendarEvent(existing)
                                                    draft.copy(
                                                        source = EventSource.Local,
                                                        calendarEventId = if (removedFromCalendar || existing.source == EventSource.Local) null else existing.calendarEventId,
                                                        calendarItemId = if (removedFromCalendar || existing.source == EventSource.Local) null else existing.calendarItemId,
                                                    )
                                                }
                                                app.repository.upsert(synced)
                                                app.reminderScheduler.schedule(synced)
                                                synced
                                            }
                                            updateWidget()
                                            saving = false
                                            if (syncToCalendar && saved.source == EventSource.Local) {
                                                Toast.makeText(this@MainActivity, R.string.calendar_sync_failed, Toast.LENGTH_LONG).show()
                                            }
                                            navController.navigate("detail/${saved.id}") { popUpTo("detail/${saved.id}") { inclusive = true } }
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
