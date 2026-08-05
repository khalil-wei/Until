export enum EventCategory {
  Birthday = 'birthday',
  Anniversary = 'anniversary',
  Custom = 'custom',
}

export enum EventDateCalendar {
  Gregorian = 'gregorian',
  Lunar = 'lunar',
}

export enum EventSource {
  Local = 'local',
  AppCalendar = 'appCalendar',
  ImportedCalendar = 'importedCalendar',
}

export enum ReminderLeadTime {
  None = -1,
  SameDay = 0,
  OneDay = 1,
  ThreeDays = 3,
  SevenDays = 7,
}

export enum UrgencyLevel {
  Today = 'today',
  Soon = 'soon',
  Upcoming = 'upcoming',
  Distant = 'distant',
}

export interface CountdownEvent {
  id: string;
  title: string;
  nextOccurrence: Date;
  originalDate: Date;
  category: EventCategory;
  dateCalendar: EventDateCalendar;
  source: EventSource;
  isIgnored?: boolean;
  calendarEventID?: string;
  calendarItemID?: string;
  notes?: string;
  reminderLeadTime: ReminderLeadTime;
}

export interface CountdownEventInput {
  id?: string;
  title: string;
  originalDate: Date;
  nextOccurrence?: Date;
  category: EventCategory;
  dateCalendar?: EventDateCalendar;
  source?: EventSource;
  isIgnored?: boolean;
  calendarEventID?: string;
  calendarItemID?: string;
  notes?: string;
  reminderLeadTime?: ReminderLeadTime;
}

export class CountdownEventFactory {
  static create(input: CountdownEventInput): CountdownEvent {
    return {
      id: input.id ?? CountdownEventFactory.createID(),
      title: input.title,
      nextOccurrence: input.nextOccurrence ?? input.originalDate,
      originalDate: input.originalDate,
      category: input.category,
      dateCalendar: input.dateCalendar ?? EventDateCalendar.Gregorian,
      source: input.source ?? EventSource.Local,
      isIgnored: input.isIgnored ?? false,
      calendarEventID: input.calendarEventID,
      calendarItemID: input.calendarItemID,
      notes: input.notes,
      reminderLeadTime: input.reminderLeadTime ?? ReminderLeadTime.None,
    };
  }

  private static createID(): string {
    return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  }
}
