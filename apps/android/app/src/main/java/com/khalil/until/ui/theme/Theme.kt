package com.khalil.until.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

private val LightColors = lightColorScheme(
    primary = UntilPrimary,
    onPrimary = UntilSurface,
    primaryContainer = UntilPrimarySoft,
    onPrimaryContainer = UntilText,
    background = UntilBackground,
    onBackground = UntilText,
    surface = UntilSurface,
    onSurface = UntilText,
    surfaceVariant = UntilMaterial,
    onSurfaceVariant = UntilSecondaryText,
    outline = UntilDivider,
    error = UntilDanger,
)

private val DarkColors = darkColorScheme(
    primary = ColorTokens.darkPrimary,
    onPrimary = UntilDarkBackground,
    primaryContainer = ColorTokens.darkPrimaryContainer,
    onPrimaryContainer = UntilDarkText,
    background = UntilDarkBackground,
    onBackground = UntilDarkText,
    surface = UntilDarkSurface,
    onSurface = UntilDarkText,
    surfaceVariant = ColorTokens.darkSurfaceVariant,
    onSurfaceVariant = UntilDarkSecondary,
    outline = UntilDarkDivider,
    error = ColorTokens.darkDanger,
)

private object ColorTokens {
    val darkPrimary = androidx.compose.ui.graphics.Color(0xFF4FD5BD)
    val darkPrimaryContainer = androidx.compose.ui.graphics.Color(0xFF183C35)
    val darkSurfaceVariant = androidx.compose.ui.graphics.Color(0xFF202B27)
    val darkDanger = androidx.compose.ui.graphics.Color(0xFFFF8796)
}

private val UntilTypography = androidx.compose.material3.Typography(
    displaySmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Bold, fontSize = 34.sp, lineHeight = 41.sp),
    titleLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 20.sp, lineHeight = 26.sp),
    titleMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 22.sp),
    titleSmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, lineHeight = 20.sp),
    bodyLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 15.sp, lineHeight = 22.sp),
    bodyMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 14.sp, lineHeight = 20.sp),
    bodySmall = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 12.sp, lineHeight = 17.sp),
    labelLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, lineHeight = 20.sp),
)

@Composable
fun UntilTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(colorScheme = if (darkTheme) DarkColors else LightColors, typography = UntilTypography, content = content)
}
