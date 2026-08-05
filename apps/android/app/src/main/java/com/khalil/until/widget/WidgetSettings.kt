package com.khalil.until.widget

import android.content.Context

enum class WidgetTheme { Colorful, Indigo, Midnight }

data class WidgetSettings(
    val featuredEventId: String? = null,
    val theme: WidgetTheme = WidgetTheme.Colorful,
)

object WidgetSettingsStore {
    private const val storeName = "until_widget_settings"
    private const val featuredEventKey = "featured_event_id"
    private const val themeKey = "theme"

    fun load(context: Context): WidgetSettings {
        val preferences = context.getSharedPreferences(storeName, Context.MODE_PRIVATE)
        val theme = runCatching {
            WidgetTheme.valueOf(preferences.getString(themeKey, WidgetTheme.Colorful.name).orEmpty())
        }.getOrDefault(WidgetTheme.Colorful)
        return WidgetSettings(
            featuredEventId = preferences.getString(featuredEventKey, null),
            theme = theme,
        )
    }

    fun save(context: Context, settings: WidgetSettings) {
        context.getSharedPreferences(storeName, Context.MODE_PRIVATE).edit()
            .putString(featuredEventKey, settings.featuredEventId)
            .putString(themeKey, settings.theme.name)
            .apply()
    }
}
