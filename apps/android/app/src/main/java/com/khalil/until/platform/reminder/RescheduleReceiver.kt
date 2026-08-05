package com.khalil.until.platform.reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.updateAll
import com.khalil.until.UntilApplication
import com.khalil.until.widget.UntilWidget
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class RescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in SUPPORTED_ACTIONS) return
        val result = goAsync()
        val app = context.applicationContext as UntilApplication
        CoroutineScope(Dispatchers.IO).launch {
            try {
                app.repository.events.first().forEach(app.reminderScheduler::schedule)
                UntilWidget().updateAll(context)
            } finally {
                result.finish()
            }
        }
    }

    private companion object {
        val SUPPORTED_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )
    }
}
