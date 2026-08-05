import {
  CountdownEvent,
  EventCategory,
  EventDateCalendar,
  ReminderLeadTime,
  EventSource,
  UrgencyLevel,
} from '../model/CountdownEvent';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { LunarCalendar } from '../services/LunarCalendar';
import { AppTheme } from './AppTheme';
import { L } from './LocalizedText';

export class EventPresentation {
  private static readonly NIGHT_LETTER_COOLDOWN_MS: number = 30 * 24 * 60 * 60 * 1000;
  private static readonly NIGHT_LETTER_CADENCE_DAYS: number = 5;

  static accessibilityLabel(event: CountdownEvent): string {
    return `${event.title}，${EventPresentation.displayDate(event.nextOccurrence, event.dateCalendar)}，` +
      `${EventPresentation.countdownText(event)}，${EventPresentation.sourceLabel(event.source)}`;
  }

  static categorySymbol(category: EventCategory): string {
    return L.categorySymbol(category);
  }

  static sourceLabel(source: EventSource): string {
    return L.sourceLabel(source);
  }

  static sourceSymbol(source: EventSource): string {
    return L.sourceSymbol(source);
  }

  static sourceColor(source: EventSource): ResourceColor {
    switch (source) {
      case EventSource.Local:
        return AppTheme.tertiaryText;
      case EventSource.AppCalendar:
        return AppTheme.upcoming;
      case EventSource.ImportedCalendar:
        return AppTheme.warning;
    }
  }

  static categoryLabel(category: EventCategory): string {
    return L.categoryLabel(category);
  }

  static calendarLabel(calendar: EventDateCalendar): string {
    return L.calendarLabel(calendar);
  }

  static reminderLabel(leadTime: ReminderLeadTime): string {
    return L.reminderLabel(leadTime);
  }

  static monthDayText(date: Date, dateCalendar: EventDateCalendar = EventDateCalendar.Gregorian): string {
    if (dateCalendar === EventDateCalendar.Lunar) {
      return LunarCalendar.formattedMonthDay(date, L.isZh());
    }

    if (L.isZh()) {
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}`;
  }

  static displayDate(date: Date, dateCalendar: EventDateCalendar = EventDateCalendar.Gregorian): string {
    const gregorianDate = EventPresentation.monthDayText(date, EventDateCalendar.Gregorian);

    if (dateCalendar === EventDateCalendar.Gregorian) {
      return gregorianDate;
    }

    return L.format('date.lunar_format', EventPresentation.monthDayText(date, EventDateCalendar.Lunar))
      .replace('%@', gregorianDate);
  }

  static yearText(date: Date): string {
    return L.isZh() ? `${date.getFullYear()}年` : `${date.getFullYear()}`;
  }

  static countdownText(event: CountdownEvent, referenceDate: Date = new Date()): string {
    const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);

    if (days < 0) {
      return L.text('countdown.expired');
    }

    if (days === 0) {
      return L.text('countdown.today');
    }

    if (days === 1) {
      return L.text('countdown.tomorrow');
    }

    if (days === 2) {
      return L.text('countdown.day_after_tomorrow');
    }

    return L.isZh() ? `${days}天` : `${days} days`;
  }

  static countdownBadgeText(event: CountdownEvent, referenceDate: Date = new Date()): string {
    const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);

    if (days < 0) {
      return L.text('countdown.expired.short');
    }

    if (days === 0) {
      return L.text('countdown.today');
    }

    if (days === 1) {
      return L.text('countdown.tomorrow');
    }

    if (days === 2) {
      return L.text('countdown.day_after_tomorrow');
    }

    if (days > 999) {
      return L.text('countdown.beyond_thousand');
    }

    return `${days}`;
  }

  static shouldShowCountdownUnit(event: CountdownEvent, referenceDate: Date = new Date()): boolean {
    const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);
    return days > 2 && !(days > 999 && L.isZh());
  }

  static specialNumberKey(daysUntil: number, isChinese: boolean): string | undefined {
    if (daysUntil === 42) {
      return 'easter_egg.special.42';
    }

    if (daysUntil === 365) {
      return 'easter_egg.special.365';
    }

    if (daysUntil === 520 && isChinese) {
      return 'easter_egg.special.520';
    }

    return undefined;
  }

  static canRevealDistantCountdown(daysUntil: number): boolean {
    return daysUntil > 999;
  }

  static canCelebrateArrival(daysUntil: number): boolean {
    return daysUntil === 0;
  }

  static arrivalDayToken(eventID: string, date: Date): string {
    return `${eventID}|${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
  }

  static shouldShowNightLetter(now: Date, lastShownAt: number, hasEvents: boolean): boolean {
    if (!hasEvents || now.getHours() >= 5) {
      return false;
    }

    const elapsed = now.getTime() - lastShownAt;
    if (lastShownAt > 0 && elapsed < EventPresentation.NIGHT_LETTER_COOLDOWN_MS) {
      return false;
    }

    const localDayIndex = Math.floor(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()) / (24 * 60 * 60 * 1000));
    return localDayIndex % EventPresentation.NIGHT_LETTER_CADENCE_DAYS === 0;
  }

  static urgencyColor(event: CountdownEvent, referenceDate: Date = new Date()): ResourceColor {
    const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);
    const urgency = CountdownCalculator.urgency(days);

    switch (urgency) {
      case UrgencyLevel.Today:
        return AppTheme.danger;
      case UrgencyLevel.Soon:
        return AppTheme.warning;
      case UrgencyLevel.Upcoming:
        return AppTheme.upcoming;
      case UrgencyLevel.Distant:
        return AppTheme.distant;
    }
  }

  static urgencySoftColor(event: CountdownEvent, referenceDate: Date = new Date()): ResourceColor {
    const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);
    const urgency = CountdownCalculator.urgency(days);

    switch (urgency) {
      case UrgencyLevel.Today:
        return AppTheme.dangerSoft;
      case UrgencyLevel.Soon:
        return AppTheme.warningSoft;
      case UrgencyLevel.Upcoming:
        return AppTheme.upcomingSoft;
      case UrgencyLevel.Distant:
        return AppTheme.distantSoft;
    }
  }
}
