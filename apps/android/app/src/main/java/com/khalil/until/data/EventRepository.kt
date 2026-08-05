package com.khalil.until.data

import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.model.CountdownEvent
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

class EventRepository(private val store: EventStore) {
    val events: Flow<List<CountdownEvent>> = store.events.map(CountdownCalculator::sorted)

    suspend fun event(id: String): CountdownEvent? = store.events.first().firstOrNull { it.id == id }

    suspend fun upsert(event: CountdownEvent) {
        val current = store.events.first().toMutableList()
        val index = current.indexOfFirst { it.id == event.id }
        if (index >= 0) current[index] = event else current += event
        store.save(current)
    }

    suspend fun delete(id: String): CountdownEvent? {
        val current = store.events.first()
        val deleted = current.firstOrNull { it.id == id }
        store.save(current.filterNot { it.id == id })
        return deleted
    }

    suspend fun replaceAll(events: List<CountdownEvent>) = store.save(events)
}
