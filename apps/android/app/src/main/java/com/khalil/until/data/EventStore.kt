package com.khalil.until.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.khalil.until.core.model.CountdownEvent
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.eventDataStore by preferencesDataStore(name = "until_events")

class EventStore(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val eventsKey = stringPreferencesKey("events_json_v1")

    val events: Flow<List<CountdownEvent>> = context.eventDataStore.data.map { preferences ->
        preferences[eventsKey]?.let { encoded ->
            runCatching { json.decodeFromString<List<CountdownEvent>>(encoded) }.getOrDefault(emptyList())
        } ?: emptyList()
    }

    suspend fun save(events: List<CountdownEvent>) {
        val encoded = json.encodeToString(events)
        context.eventDataStore.edit { it[eventsKey] = encoded }
    }
}
