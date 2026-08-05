package com.khalil.until

import android.app.Application
import com.khalil.until.data.EventRepository
import com.khalil.until.data.EventStore
import com.khalil.until.data.UserJourneyStore
import com.khalil.until.platform.reminder.ReminderScheduler

class UntilApplication : Application() {
    lateinit var repository: EventRepository
        private set
    lateinit var reminderScheduler: ReminderScheduler
        private set
    lateinit var userJourneyStore: UserJourneyStore
        private set

    override fun onCreate() {
        super.onCreate()
        repository = EventRepository(EventStore(this))
        userJourneyStore = UserJourneyStore(this)
        reminderScheduler = ReminderScheduler(this)
        reminderScheduler.createNotificationChannel()
    }
}
