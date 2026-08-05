package com.khalil.until.platform.reminder

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import com.khalil.until.MainActivity
import com.khalil.until.R
import com.khalil.until.UntilApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val eventId = intent.getStringExtra(ReminderScheduler.EXTRA_EVENT_ID).orEmpty()
        val title = intent.getStringExtra(ReminderScheduler.EXTRA_TITLE).orEmpty()
        val canNotify = android.os.Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

        if (canNotify) {
            val openIntent = Intent(context, MainActivity::class.java).apply {
                data = "until://event/$eventId".toUri()
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(context, eventId.hashCode(), openIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val notification = NotificationCompat.Builder(context, ReminderScheduler.CHANNEL_ID)
                .setSmallIcon(R.drawable.app_icon)
                .setContentTitle(context.getString(R.string.notification_title))
                .setContentText(context.getString(R.string.notification_content, title))
                .setAutoCancel(true)
                .setContentIntent(pending)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()
            NotificationManagerCompat.from(context).notify(eventId.hashCode(), notification)
        }

        val result = goAsync()
        val app = context.applicationContext as UntilApplication
        CoroutineScope(Dispatchers.IO).launch {
            try {
                app.repository.event(eventId)?.let(app.reminderScheduler::schedule)
            } finally {
                result.finish()
            }
        }
    }
}
