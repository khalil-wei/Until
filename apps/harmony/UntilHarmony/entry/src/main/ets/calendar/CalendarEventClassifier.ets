import {
  EventCategory,
  EventDateCalendar,
} from '../model/CountdownEvent';

export interface CalendarClassificationResult {
  category?: EventCategory;
  dateCalendar: EventDateCalendar;
}

export class CalendarEventClassifier {
  static classify(title: string, calendarName: string = ''): CalendarClassificationResult {
    const text = `${title} ${calendarName}`.toLocaleLowerCase();
    const category = CalendarEventClassifier.category(text);
    const dateCalendar = CalendarEventClassifier.looksLikeLunar(text)
      ? EventDateCalendar.Lunar
      : EventDateCalendar.Gregorian;

    return {
      category,
      dateCalendar,
    };
  }

  private static category(text: string): EventCategory | undefined {
    if (
      text.includes('birthday') ||
      text.includes('birthdays') ||
      text.includes('生日')
    ) {
      return EventCategory.Birthday;
    }

    if (
      text.includes('anniversary') ||
      text.includes('anniversaries') ||
      text.includes('纪念日')
    ) {
      return EventCategory.Anniversary;
    }

    return undefined;
  }

  private static looksLikeLunar(text: string): boolean {
    return [
      'lunar birthday',
      'lunar anniversary',
      'chinese birthday',
      'chinese anniversary',
      '农历生日',
      '农历纪念日',
      '农历生辰',
      '阴历生日',
      '阴历纪念日',
      '阴历生辰',
      '旧历生日',
      '旧历纪念日',
      '旧历生辰',
    ].some((keyword: string) => text.includes(keyword));
  }
}
