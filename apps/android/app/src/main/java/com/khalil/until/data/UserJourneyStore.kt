package com.khalil.until.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.userJourneyDataStore by preferencesDataStore(name = "until_user_journey")

data class UserJourneyState(
    val hasCompletedWidgetGuide: Boolean = false,
)

class UserJourneyStore(private val context: Context) {
    private val widgetGuideCompleted = booleanPreferencesKey("widget_guide_completed_v1")

    val state: Flow<UserJourneyState> = context.userJourneyDataStore.data.map { preferences ->
        UserJourneyState(hasCompletedWidgetGuide = preferences[widgetGuideCompleted] ?: false)
    }

    suspend fun completeWidgetGuide() {
        context.userJourneyDataStore.edit { it[widgetGuideCompleted] = true }
    }
}
