import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
  EventDateCalendar,
  EventSource,
  ReminderLeadTime,
} from '../model/CountdownEvent';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { L } from '../utils/LocalizedText';

export interface EventFormState {
  id?: string;
  title: string;
  category: EventCategory;
  dateCalendar: EventDateCalendar;
  dateText: string;
  hasConfirmedDate: boolean;
  notes: string;
  reminderLeadTime: ReminderLeadTime;
  shouldSyncToCalendar: boolean;
}

export interface EventFormValidationResult {
  isValid: boolean;
  message?: string;
}

export class EventFormViewModel {
  static emptyState(category: EventCategory = EventCategory.Birthday): EventFormState {
    return {
      title: '',
      category,
      dateCalendar: EventDateCalendar.Gregorian,
      dateText: EventFormViewModel.dateText(new Date()),
      hasConfirmedDate: false,
      notes: '',
      reminderLeadTime: ReminderLeadTime.OneDay,
      shouldSyncToCalendar: false,
    };
  }

  static stateFromEvent(event: CountdownEvent): EventFormState {
    return {
      id: event.id,
      title: event.title,
      category: event.category,
      dateCalendar: event.dateCalendar,
      dateText: EventFormViewModel.dateText(event.originalDate),
      hasConfirmedDate: true,
      notes: event.notes ?? '',
      reminderLeadTime: event.reminderLeadTime,
      shouldSyncToCalendar: event.source === EventSource.AppCalendar,
    };
  }

  static validate(state: EventFormState): EventFormValidationResult {
    if (state.title.trim().length === 0) {
      return {
        isValid: false,
        message: L.text('validation.title.required'),
      };
    }

    if (!state.hasConfirmedDate) {
      return {
        isValid: false,
        message: L.text('validation.date.required'),
      };
    }

    if (EventFormViewModel.parseDateText(state.dateText) === undefined) {
      return {
        isValid: false,
        message: L.text('validation.date.invalid'),
      };
    }

    return {
      isValid: true,
    };
  }

  static buildEvent(state: EventFormState, existingEvent?: CountdownEvent): CountdownEvent | undefined {
    const validation = EventFormViewModel.validate(state);
    const originalDate = EventFormViewModel.parseDateText(state.dateText);

    if (!validation.isValid || originalDate === undefined) {
      return undefined;
    }

    const source = state.shouldSyncToCalendar ? EventSource.AppCalendar : EventSource.Local;
    const nextOccurrence = CountdownCalculator.nextAnnualOccurrence(
      originalDate,
      state.dateCalendar,
    );

    return CountdownEventFactory.create({
      id: existingEvent?.id ?? state.id,
      title: state.title.trim(),
      originalDate,
      nextOccurrence,
      category: state.category,
      dateCalendar: state.dateCalendar,
      source,
      calendarEventID: existingEvent?.calendarEventID,
      calendarItemID: existingEvent?.calendarItemID,
      notes: state.notes.trim().length > 0 ? state.notes.trim() : undefined,
      reminderLeadTime: state.reminderLeadTime,
    });
  }

  static dateText(date: Date): string {
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  static parseDateText(dateText: string): Date | undefined {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateText.trim());

    if (match === null) {
      return undefined;
    }

    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(year, month - 1, day);

    if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
      return undefined;
    }

    return date;
  }
}
