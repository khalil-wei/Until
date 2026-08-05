export interface LunarDateComponents {
  year: number;
  month: number;
  day: number;
  isLeapMonth: boolean;
}

interface LunarMonthInfo {
  month: number;
  days: number;
  isLeapMonth: boolean;
}

export class LunarCalendar {
  private static readonly minYear: number = 1900;
  private static readonly maxYear: number = 2100;
  private static readonly millisecondsPerDay: number = 24 * 60 * 60 * 1000;
  private static readonly baseDate: Date = new Date(1900, 0, 31);
  private static readonly lunarInfo: number[] = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
    0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, 0x052d0, 0x0a9a8, 0x0e950, 0x06aa0,
    0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
    0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
    0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0,
    0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
    0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
    0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
    0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
    0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
    0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
    0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
    0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
    0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
    0x0d520,
  ];

  static solarToLunar(date: Date): LunarDateComponents | undefined {
    let remainingDays = LunarCalendar.daysBetween(
      LunarCalendar.startOfDay(LunarCalendar.baseDate),
      LunarCalendar.startOfDay(date),
    );

    if (remainingDays < 0) {
      return undefined;
    }

    for (let year = LunarCalendar.minYear; year <= LunarCalendar.maxYear; year += 1) {
      const months = LunarCalendar.monthsInYear(year);

      for (let index = 0; index < months.length; index += 1) {
        const lunarMonth = months[index];
        if (remainingDays < lunarMonth.days) {
          return {
            year,
            month: lunarMonth.month,
            day: remainingDays + 1,
            isLeapMonth: lunarMonth.isLeapMonth,
          };
        }

        remainingDays -= lunarMonth.days;
      }
    }

    return undefined;
  }

  static nextOccurrence(originalDate: Date, referenceDate: Date = new Date()): Date {
    const source = LunarCalendar.solarToLunar(originalDate);

    if (source === undefined) {
      return LunarCalendar.startOfDay(originalDate);
    }

    const referenceDay = LunarCalendar.startOfDay(referenceDate);
    const exactMatch = LunarCalendar.findMatchingOccurrence(source, referenceDay, true, 800);

    if (exactMatch !== undefined) {
      return exactMatch;
    }

    if (source.isLeapMonth) {
      const regularFallback = LunarCalendar.findMatchingOccurrence(source, referenceDay, false, 400);
      if (regularFallback !== undefined) {
        return regularFallback;
      }
    }

    return LunarCalendar.startOfDay(originalDate);
  }

  static sameMonthDay(lhs: Date, rhs: Date): boolean {
    const lhsLunar = LunarCalendar.solarToLunar(lhs);
    const rhsLunar = LunarCalendar.solarToLunar(rhs);

    if (lhsLunar === undefined || rhsLunar === undefined) {
      return false;
    }

    return lhsLunar.month === rhsLunar.month &&
      lhsLunar.day === rhsLunar.day &&
      lhsLunar.isLeapMonth === rhsLunar.isLeapMonth;
  }

  static formattedMonthDay(date: Date, isZh: boolean): string {
    const components = LunarCalendar.solarToLunar(date);

    if (components === undefined) {
      return isZh ? `${date.getMonth() + 1}月${date.getDate()}日` : `${date.getMonth() + 1}/${date.getDate()}`;
    }

    if (!isZh) {
      const prefix = components.isLeapMonth ? 'Leap ' : '';
      return `${prefix}${components.month}/${components.day}`;
    }

    const monthNames = ['', '正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];
    const leapPrefix = components.isLeapMonth ? '闰' : '';
    return `${leapPrefix}${monthNames[components.month]}月${LunarCalendar.formattedChineseDay(components.day)}`;
  }

  private static findMatchingOccurrence(
    source: LunarDateComponents,
    referenceDay: Date,
    requireExactLeapState: boolean,
    searchDays: number,
  ): Date | undefined {
    for (let offset = 0; offset <= searchDays; offset += 1) {
      const candidate = new Date(referenceDay.getFullYear(), referenceDay.getMonth(), referenceDay.getDate() + offset);
      const candidateLunar = LunarCalendar.solarToLunar(candidate);

      if (candidateLunar === undefined) {
        continue;
      }

      const leapMatches = requireExactLeapState
        ? candidateLunar.isLeapMonth === source.isLeapMonth
        : !candidateLunar.isLeapMonth;

      if (candidateLunar.month === source.month && candidateLunar.day === source.day && leapMatches) {
        return LunarCalendar.startOfDay(candidate);
      }
    }

    return undefined;
  }

  private static monthsInYear(year: number): LunarMonthInfo[] {
    const months: LunarMonthInfo[] = [];
    const leapMonth = LunarCalendar.leapMonth(year);

    for (let month = 1; month <= 12; month += 1) {
      months.push({
        month,
        days: LunarCalendar.monthDays(year, month),
        isLeapMonth: false,
      });

      if (leapMonth === month) {
        months.push({
          month,
          days: LunarCalendar.leapDays(year),
          isLeapMonth: true,
        });
      }
    }

    return months;
  }

  private static monthDays(year: number, month: number): number {
    return (LunarCalendar.info(year) & (0x10000 >> month)) === 0 ? 29 : 30;
  }

  private static leapMonth(year: number): number {
    return LunarCalendar.info(year) & 0x0f;
  }

  private static leapDays(year: number): number {
    if (LunarCalendar.leapMonth(year) === 0) {
      return 0;
    }

    return (LunarCalendar.info(year) & 0x10000) === 0 ? 29 : 30;
  }

  private static info(year: number): number {
    const index = year - LunarCalendar.minYear;

    if (index < 0 || index >= LunarCalendar.lunarInfo.length) {
      return 0;
    }

    return LunarCalendar.lunarInfo[index];
  }

  private static formattedChineseDay(day: number): string {
    const numerals = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];

    if (day >= 1 && day <= 10) {
      return `初${numerals[day]}`;
    }

    if (day >= 11 && day <= 19) {
      return `十${numerals[day - 10]}`;
    }

    if (day === 20) {
      return '二十';
    }

    if (day >= 21 && day <= 29) {
      return `廿${numerals[day - 20]}`;
    }

    if (day === 30) {
      return '三十';
    }

    return `${day}`;
  }

  private static startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  private static daysBetween(start: Date, end: Date): number {
    return Math.floor((end.getTime() - start.getTime()) / LunarCalendar.millisecondsPerDay);
  }
}
