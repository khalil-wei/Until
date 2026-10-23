import {
  CountdownEvent,
  EventDateCalendar,
  EventRecurrence,
  UrgencyLevel,
} from '../model/CountdownEvent';
import { LunarCalendar } from './LunarCalendar';

export enum CountdownLabelKey {
  Today = 'countdown.today',
  Tomorrow = 'countdown.tomorrow',
  DayAfterTomorrow = 'countdown.day_after_tomorrow',
  DaysAfter = 'countdown.days.after',
  Expired = 'countdown.expired',
}

export class CountdownCalculator {
  static startOfLocalDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  static daysUntil(targetDate: Date, referenceDate: Date = new Date()): number {
    const target = CountdownCalculator.startOfLocalDay(targetDate).getTime();
    const reference = CountdownCalculator.startOfLocalDay(referenceDate).getTime();
    return Math.round((target - reference) / CountdownCalculator.millisecondsPerDay());
  }

  static normalizedForDisplay(event: CountdownEvent, referenceDate: Date = new Date()): CountdownEvent {
    return {
      id: event.id,
      title: event.title,
      nextOccurrence: CountdownCalculator.nextOccurrence(
        event.originalDate,
        event.dateCalendar,
        event.recurrence,
        referenceDate,
      ),
      originalDate: event.originalDate,
      category: event.category,
      dateCalendar: event.dateCalendar,
      recurrence: event.recurrence ?? EventRecurrence.Yearly,
      source: event.source,
      isIgnored: event.isIgnored ?? false,
      calendarEventID: event.calendarEventID,
      calendarItemID: event.calendarItemID,
      notes: event.notes,
      reminderLeadTime: event.reminderLeadTime,
    };
  }

  static nextAnnualOccurrence(
    originalDate: Date,
    dateCalendar: EventDateCalendar = EventDateCalendar.Gregorian,
    referenceDate: Date = new Date(),
  ): Date {
    const referenceDay = CountdownCalculator.startOfLocalDay(referenceDate);
    const originalDay = CountdownCalculator.startOfLocalDay(originalDate);
    if (originalDay.getTime() >= referenceDay.getTime()) {
      return originalDay;
    }

    if (dateCalendar === EventDateCalendar.Lunar) {
      return LunarCalendar.nextOccurrence(originalDate, referenceDate);
    }

    const month = originalDate.getMonth();
    const day = originalDate.getDate();
    const referenceYear = referenceDay.getFullYear();

    // Preserve a future date chosen by the user as the first occurrence. This
    // avoids turning an explicitly selected 2027-07-13 into today's
    // 2026-07-13 while still allowing annual events to repeat afterward.
    for (let year = referenceYear; year <= referenceYear + 12; year += 1) {
      const candidate = new Date(year, month, day);
      const isValidSameMonthDay = candidate.getFullYear() === year &&
        candidate.getMonth() === month &&
        candidate.getDate() === day;

      if (isValidSameMonthDay && candidate.getTime() >= referenceDay.getTime()) {
        return CountdownCalculator.startOfLocalDay(candidate);
      }
    }

    return CountdownCalculator.startOfLocalDay(originalDate);
  }

  static nextOccurrence(
    originalDate: Date,
    dateCalendar: EventDateCalendar = EventDateCalendar.Gregorian,
    recurrence: EventRecurrence = EventRecurrence.Yearly,
    referenceDate: Date = new Date(),
  ): Date {
    const original = CountdownCalculator.startOfLocalDay(originalDate);
    const reference = CountdownCalculator.startOfLocalDay(referenceDate);
    if (original.getTime() >= reference.getTime()) return original;
    if (recurrence === EventRecurrence.Yearly) {
      return CountdownCalculator.nextAnnualOccurrence(original, dateCalendar, reference);
    }
    if (recurrence === EventRecurrence.Weekly) {
      // Count local dates rather than elapsed hours across daylight-saving changes.
      const elapsedDays = Math.round((Date.UTC(reference.getFullYear(), reference.getMonth(), reference.getDate()) -
        Date.UTC(original.getFullYear(), original.getMonth(), original.getDate())) / CountdownCalculator.millisecondsPerDay());
      return new Date(original.getFullYear(), original.getMonth(), original.getDate() + Math.ceil(elapsedDays / 7) * 7);
    }
    if (dateCalendar === EventDateCalendar.Lunar) {
      const source = LunarCalendar.solarToLunar(original);
      if (source !== undefined) {
        for (let offset = 0; offset <= 400; offset += 1) {
          const candidate = new Date(reference.getFullYear(), reference.getMonth(), reference.getDate() + offset);
          if (LunarCalendar.solarToLunar(candidate)?.day === source.day) return candidate;
        }
      }
      return original;
    }
    for (let offset = 0; offset < 24; offset += 1) {
      const monthStart = new Date(reference.getFullYear(), reference.getMonth() + offset, 1);
      const candidate = new Date(monthStart.getFullYear(), monthStart.getMonth(), original.getDate());
      if (candidate.getMonth() === monthStart.getMonth() && candidate.getTime() >= reference.getTime()) return candidate;
    }
    return original;
  }

  static countdownLabelKey(daysUntil: number): CountdownLabelKey {
    if (daysUntil < 0) {
      return CountdownLabelKey.Expired;
    }

    if (daysUntil === 0) {
      return CountdownLabelKey.Today;
    }

    if (daysUntil === 1) {
      return CountdownLabelKey.Tomorrow;
    }

    if (daysUntil === 2) {
      return CountdownLabelKey.DayAfterTomorrow;
    }

    return CountdownLabelKey.DaysAfter;
  }

  static countdownBadgeText(daysUntil: number): string {
    if (daysUntil < 0) {
      return CountdownLabelKey.Expired;
    }

    if (daysUntil === 0) {
      return CountdownLabelKey.Today;
    }

    if (daysUntil === 1) {
      return CountdownLabelKey.Tomorrow;
    }

    if (daysUntil === 2) {
      return CountdownLabelKey.DayAfterTomorrow;
    }

    if (daysUntil > 999) {
      return '1000+';
    }

    return `${daysUntil}`;
  }

  static shouldShowCountdownUnit(daysUntil: number): boolean {
    return daysUntil > 2;
  }

  static urgency(daysUntil: number): UrgencyLevel {
    if (daysUntil <= 0) {
      return UrgencyLevel.Today;
    }

    if (daysUntil <= 7) {
      return UrgencyLevel.Soon;
    }

    if (daysUntil <= 30) {
      return UrgencyLevel.Upcoming;
    }

    return UrgencyLevel.Distant;
  }

  static sortByNextOccurrence(
    events: CountdownEvent[],
    referenceDate: Date = new Date(),
  ): CountdownEvent[] {
    return events
      .map((event: CountdownEvent) => CountdownCalculator.normalizedForDisplay(event, referenceDate))
      .sort((lhs: CountdownEvent, rhs: CountdownEvent) => {
        const lhsDays = CountdownCalculator.daysUntil(lhs.nextOccurrence, referenceDate);
        const rhsDays = CountdownCalculator.daysUntil(rhs.nextOccurrence, referenceDate);
        return lhsDays - rhsDays;
      });
  }

  static matchesSameAnnualEvent(lhs: CountdownEvent, rhs: CountdownEvent): boolean {
    if ((lhs.recurrence ?? EventRecurrence.Yearly) !== (rhs.recurrence ?? EventRecurrence.Yearly)) return false;
    if (lhs.dateCalendar !== rhs.dateCalendar || lhs.category !== rhs.category) {
      return false;
    }

    const lhsDate = lhs.originalDate;
    const rhsDate = rhs.originalDate;

    if ((lhs.recurrence ?? EventRecurrence.Yearly) !== EventRecurrence.Yearly) {
      return CountdownCalculator.normalizedTitle(lhs.title) === CountdownCalculator.normalizedTitle(rhs.title) &&
        CountdownCalculator.daysUntil(lhsDate, rhsDate) === 0;
    }

    if (lhs.dateCalendar === EventDateCalendar.Lunar) {
      return CountdownCalculator.normalizedTitle(lhs.title) === CountdownCalculator.normalizedTitle(rhs.title) &&
        LunarCalendar.sameMonthDay(lhsDate, rhsDate);
    }

    return CountdownCalculator.normalizedTitle(lhs.title) === CountdownCalculator.normalizedTitle(rhs.title) &&
      lhsDate.getMonth() === rhsDate.getMonth() &&
      lhsDate.getDate() === rhsDate.getDate();
  }

  private static normalizedTitle(title: string): string {
    return title.trim().toLocaleLowerCase();
  }

  private static millisecondsPerDay(): number {
    return 24 * 60 * 60 * 1000;
  }
}
