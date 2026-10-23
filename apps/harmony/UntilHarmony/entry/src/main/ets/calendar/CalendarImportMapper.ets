import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
  EventDateCalendar,
  EventRecurrence,
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
  recurrence?: EventRecurrence;
}

export class CalendarImportMapper {
  static map(rawEvent: RawCalendarEvent): CountdownEvent | undefined {
    const classification = CalendarEventClassifier.classify(
      rawEvent.title,
      rawEvent.calendarName ?? '',
    );

    const category = classification.category ?? EventCategory.Custom;
    const dateCalendar = rawEvent.isLunar === true ? EventDateCalendar.Lunar : classification.dateCalendar;

    const nextOccurrence = CountdownCalculator.nextOccurrence(
      rawEvent.startDate,
      dateCalendar,
      rawEvent.recurrence,
    );

    return CountdownEventFactory.create({
      title: rawEvent.title,
      originalDate: rawEvent.startDate,
      nextOccurrence,
      category,
      dateCalendar,
      recurrence: rawEvent.recurrence ?? EventRecurrence.Yearly,
      source: EventSource.ImportedCalendar,
      calendarEventID: rawEvent.id,
      calendarItemID: rawEvent.itemID,
      notes: rawEvent.notes,
    });
  }
}
