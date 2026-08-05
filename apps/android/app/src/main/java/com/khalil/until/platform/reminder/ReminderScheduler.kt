package com.khalil.until.platform.reminder

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.khalil.until.R
import com.khalil.until.core.domain.CountdownCalculator
import com.khalil.until.core.domain.ReminderRules
import com.khalil.until.core.model.CountdownEvent
import com.khalil.until.core.model.ReminderLeadTime
import java.time.LocalDateTime
import java.time.ZoneId

class ReminderScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply { description = context.getString(R.string.notification_channel_description) }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun canNotify(): Boolean = Build.VERSION.SDK_INT < 33 ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    fun schedule(event: CountdownEvent) {
        cancel(event.id)
        if (event.reminderLeadTime == ReminderLeadTime.None || !canNotify()) return
        val occurrence = CountdownCalculator.nextOccurrence(event)
        var trigger = requireNotNull(ReminderRules.triggerDateTime(occurrence, event.reminderLeadTime))
        if (!trigger.isAfter(LocalDateTime.now())) {
            val next = CountdownCalculator.nextAnnualOccurrence(event.originalDate, event.dateCalendar, occurrence.plusDays(1))
            trigger = requireNotNull(ReminderRules.triggerDateTime(next, event.reminderLeadTime))
        }
        val millis = trigger.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val pendingIntent = reminderPendingIntent(event)
        if (Build.VERSION.SDK_INT < 31 || alarmManager.canScheduleExactAlarms()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pendingIntent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pendingIntent)
        }
    }

    fun cancel(eventId: String) {
        val intent = Intent(context, ReminderReceiver::class.java).setAction(ACTION_REMIND).putExtra(EXTRA_EVENT_ID, eventId)
        val pending = PendingIntent.getBroadcast(context, eventId.hashCode(), intent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE)
        if (pending != null) alarmManager.cancel(pending)
    }

    private fun reminderPendingIntent(event: CountdownEvent): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
            .setAction(ACTION_REMIND)
            .putExtra(EXTRA_EVENT_ID, event.id)
            .putExtra(EXTRA_TITLE, event.title)
        return PendingIntent.getBroadcast(context, event.id.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    companion object {
        const val CHANNEL_ID = "until-important-days"
        const val ACTION_REMIND = "com.khalil.until.REMIND"
        const val EXTRA_EVENT_ID = "event_id"
        const val EXTRA_TITLE = "event_title"
    }
}
