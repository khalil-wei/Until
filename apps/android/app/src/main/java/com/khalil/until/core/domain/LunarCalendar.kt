package com.khalil.until.core.domain

import java.time.LocalDate
import java.time.temporal.ChronoUnit

data class LunarDate(val year: Int, val month: Int, val day: Int, val isLeapMonth: Boolean)

object LunarCalendar {
    private const val MIN_YEAR = 1900
    private const val MAX_YEAR = 2100
    private val baseDate = LocalDate.of(1900, 1, 31)

    private val lunarInfo = intArrayOf(
        0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
        0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
        0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
        0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
        0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
        0x06ca0,0x0b550,0x15355,0x04da0,0x0a5d0,0x14573,0x052d0,0x0a9a8,0x0e950,0x06aa0,
        0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
        0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,
        0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
        0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,
        0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
        0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
        0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
        0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
        0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
        0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
        0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
        0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
        0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
        0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
        0x0d520,
    )

    fun solarToLunar(date: LocalDate): LunarDate? {
        var remaining = ChronoUnit.DAYS.between(baseDate, date).toInt()
        if (remaining < 0) return null
        for (year in MIN_YEAR..MAX_YEAR) {
            for (month in monthsInYear(year)) {
                if (remaining < month.days) return LunarDate(year, month.month, remaining + 1, month.leap)
                remaining -= month.days
            }
        }
        return null
    }

    fun nextOccurrence(originalDate: LocalDate, referenceDate: LocalDate = LocalDate.now()): LocalDate {
        if (!originalDate.isBefore(referenceDate)) return originalDate
        val source = solarToLunar(originalDate) ?: return originalDate
        findMatch(source, referenceDate, requireExactLeap = true, searchDays = 800)?.let { return it }
        if (source.isLeapMonth) findMatch(source, referenceDate, requireExactLeap = false, searchDays = 400)?.let { return it }
        return originalDate
    }

    fun sameMonthDay(lhs: LocalDate, rhs: LocalDate): Boolean {
        val left = solarToLunar(lhs) ?: return false
        val right = solarToLunar(rhs) ?: return false
        return left.month == right.month && left.day == right.day && left.isLeapMonth == right.isLeapMonth
    }

    fun formattedMonthDay(date: LocalDate, chinese: Boolean): String {
        val lunar = solarToLunar(date) ?: return if (chinese) "${date.monthValue}月${date.dayOfMonth}日" else "${date.monthValue}/${date.dayOfMonth}"
        if (!chinese) return "${if (lunar.isLeapMonth) "Leap " else ""}${lunar.month}/${lunar.day}"
        val months = arrayOf("", "正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊")
        return "${if (lunar.isLeapMonth) "闰" else ""}${months[lunar.month]}月${chineseDay(lunar.day)}"
    }

    private fun findMatch(source: LunarDate, reference: LocalDate, requireExactLeap: Boolean, searchDays: Int): LocalDate? {
        for (offset in 0..searchDays) {
            val candidate = reference.plusDays(offset.toLong())
            val lunar = solarToLunar(candidate) ?: continue
            val leapMatches = if (requireExactLeap) lunar.isLeapMonth == source.isLeapMonth else !lunar.isLeapMonth
            if (lunar.month == source.month && lunar.day == source.day && leapMatches) return candidate
        }
        return null
    }

    private data class MonthInfo(val month: Int, val days: Int, val leap: Boolean)

    private fun monthsInYear(year: Int): List<MonthInfo> = buildList {
        val leapMonth = leapMonth(year)
        for (month in 1..12) {
            add(MonthInfo(month, monthDays(year, month), false))
            if (leapMonth == month) add(MonthInfo(month, leapDays(year), true))
        }
    }

    private fun info(year: Int): Int = lunarInfo.getOrElse(year - MIN_YEAR) { 0 }
    private fun monthDays(year: Int, month: Int) = if (info(year) and (0x10000 shr month) == 0) 29 else 30
    private fun leapMonth(year: Int) = info(year) and 0x0f
    private fun leapDays(year: Int) = if (leapMonth(year) == 0) 0 else if (info(year) and 0x10000 == 0) 29 else 30

    private fun chineseDay(day: Int): String {
        val n = arrayOf("", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十")
        return when (day) {
            in 1..10 -> "初${n[day]}"
            in 11..19 -> "十${n[day - 10]}"
            20 -> "二十"
            in 21..29 -> "廿${n[day - 20]}"
            30 -> "三十"
            else -> day.toString()
        }
    }
}
