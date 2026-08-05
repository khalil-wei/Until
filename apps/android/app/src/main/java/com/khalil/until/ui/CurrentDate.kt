package com.khalil.until.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.produceState
import kotlinx.coroutines.delay
import java.time.Duration
import java.time.LocalDate
import java.time.ZonedDateTime

@Composable
fun rememberCurrentDate(): State<LocalDate> = produceState(initialValue = LocalDate.now()) {
    while (true) {
        val now = ZonedDateTime.now()
        val nextMidnight = now.toLocalDate().plusDays(1).atStartOfDay(now.zone)
        delay(Duration.between(now, nextMidnight).toMillis().coerceAtLeast(1_000L) + 250L)
        value = LocalDate.now()
    }
}
