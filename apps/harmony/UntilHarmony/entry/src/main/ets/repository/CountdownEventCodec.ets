import {
  CountdownEvent,
  EventCategory,
  EventDateCalendar,
  EventSource,
  ReminderLeadTime,
} from '../model/CountdownEvent';

interface CountdownEventRecord {
  id: string;
  title: string;
  nextOccurrence: string;
  originalDate: string;
  category: string;
  dateCalendar: string;
  source: string;
  isIgnored?: boolean;
  calendarEventID?: string;
  calendarItemID?: string;
  notes?: string;
  reminderLeadTime: number;
}

export class CountdownEventCodec {
  static encode(events: CountdownEvent[]): string {
    const records = events.map((event: CountdownEvent): CountdownEventRecord => {
      return {
        id: event.id,
        title: event.title,
        nextOccurrence: event.nextOccurrence.toISOString(),
        originalDate: event.originalDate.toISOString(),
        category: event.category,
        dateCalendar: event.dateCalendar,
        source: event.source,
        isIgnored: event.isIgnored ?? false,
        calendarEventID: event.calendarEventID,
        calendarItemID: event.calendarItemID,
        notes: event.notes,
        reminderLeadTime: event.reminderLeadTime,
      };
    });

    return JSON.stringify(records);
  }

  static decode(rawValue: string): CountdownEvent[] {
    if (rawValue.trim().length === 0) {
      return [];
    }

    const parsed = JSON.parse(rawValue) as CountdownEventRecord[];
    return parsed.map((record: CountdownEventRecord): CountdownEvent => {
      return {
        id: record.id,
        title: record.title,
        nextOccurrence: new Date(record.nextOccurrence),
        originalDate: new Date(record.originalDate),
        category: record.category as EventCategory,
        dateCalendar: record.dateCalendar as EventDateCalendar,
        source: record.source as EventSource,
        isIgnored: record.isIgnored ?? false,
        calendarEventID: record.calendarEventID,
        calendarItemID: record.calendarItemID,
        notes: record.notes,
        reminderLeadTime: record.reminderLeadTime as ReminderLeadTime,
      };
    });
  }
}
