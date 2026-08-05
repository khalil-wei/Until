import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
  EventDateCalendar,
  EventSource,
} from '../model/CountdownEvent';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { CalendarEventClassifier } from './CalendarEventClassifier';

export interface RawCalendarEvent {
  id: string;
  itemID?: string;
  title: string;
  calendarName?: string;
  startDate: Date;
  notes?: string;
  isLunar?: boolean;
}

export class CalendarImportMapper {
  static map(rawEvent: RawCalendarEvent): CountdownEvent | undefined {
    const classification = CalendarEventClassifier.classify(
      rawEvent.title,
      rawEvent.calendarName ?? '',
    );

    const category = classification.category ?? EventCategory.Custom;
    const dateCalendar = rawEvent.isLunar === true ? EventDateCalendar.Lunar : classification.dateCalendar;

    const nextOccurrence = CountdownCalculator.nextAnnualOccurrence(
      rawEvent.startDate,
      dateCalendar,
    );

    return CountdownEventFactory.create({
      title: rawEvent.title,
      originalDate: rawEvent.startDate,
      nextOccurrence,
      category,
      dateCalendar,
      source: EventSource.ImportedCalendar,
      calendarEventID: rawEvent.id,
      calendarItemID: rawEvent.itemID,
      notes: rawEvent.notes,
    });
  }
}
