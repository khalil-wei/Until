import {
  CountdownEvent,
  EventSource,
} from '../model/CountdownEvent';
import { L } from '../utils/LocalizedText';
import { AppCalendarService } from './AppCalendarService';

export class CalendarSyncCoordinator {
  private static operationQueue: Promise<void> = Promise.resolve();

  static async sync(event: CountdownEvent, previousEvent?: CountdownEvent): Promise<CountdownEvent> {
    return CalendarSyncCoordinator.enqueue((): Promise<CountdownEvent> =>
      CalendarSyncCoordinator.syncImmediately(event, previousEvent));
  }

  private static async syncImmediately(
    event: CountdownEvent,
    previousEvent?: CountdownEvent,
  ): Promise<CountdownEvent> {
    const calendarService = AppCalendarService.shared();
    const shouldSync = event.source === EventSource.AppCalendar;
    const managedPreviousEventID = previousEvent?.source === EventSource.AppCalendar
      ? previousEvent.calendarEventID
      : undefined;

    if (previousEvent?.source === EventSource.ImportedCalendar && !shouldSync) {
      return CalendarSyncCoordinator.copyEvent(event, EventSource.Local, undefined, undefined);
    }

    if (!shouldSync) {
      if (managedPreviousEventID !== undefined) {
        const permissionStatus = await calendarService.requestWritePermission();
        if (!permissionStatus.canRead || !permissionStatus.canWrite) {
          throw new Error(L.text('validation.calendar.permission_denied'));
        }

        const didDelete = await calendarService.deleteCalendarEvent(managedPreviousEventID);
        if (!didDelete) {
          throw new Error(L.text('validation.calendar.sync_failed'));
        }
      }

      return CalendarSyncCoordinator.copyEvent(event, EventSource.Local, undefined);
    }

    const permissionStatus = await calendarService.requestWritePermission();

    if (!permissionStatus.canRead || !permissionStatus.canWrite) {
      throw new Error(L.text('validation.calendar.permission_denied'));
    }

    if (managedPreviousEventID !== undefined) {
      const didUpdate = await calendarService.updateAnnualEvent(managedPreviousEventID, event);

      if (didUpdate) {
        return CalendarSyncCoordinator.copyEvent(event, EventSource.AppCalendar, managedPreviousEventID, undefined);
      }
    }

    const calendarEventID = await calendarService.createAnnualEvent(event);

    if (calendarEventID === undefined) {
      throw new Error(L.text('validation.calendar.sync_failed'));
    }

    if (managedPreviousEventID !== undefined && managedPreviousEventID !== calendarEventID) {
      const didDeletePrevious = await calendarService.deleteCalendarEvent(managedPreviousEventID);
      if (!didDeletePrevious) {
        await calendarService.deleteCalendarEvent(calendarEventID);
        throw new Error(L.text('validation.calendar.sync_failed'));
      }
    }

    return CalendarSyncCoordinator.copyEvent(event, EventSource.AppCalendar, calendarEventID, undefined);
  }

  static async deleteSyncedEvent(event: CountdownEvent): Promise<boolean> {
    return CalendarSyncCoordinator.enqueue((): Promise<boolean> =>
      CalendarSyncCoordinator.deleteSyncedEventImmediately(event));
  }

  private static async deleteSyncedEventImmediately(event: CountdownEvent): Promise<boolean> {
    if (event.source !== EventSource.AppCalendar || event.calendarEventID === undefined) {
      return true;
    }

    const calendarService = AppCalendarService.shared();
    const permissionStatus = await calendarService.requestWritePermission();

    if (!permissionStatus.canRead || !permissionStatus.canWrite) {
      return false;
    }

    return calendarService.deleteCalendarEvent(event.calendarEventID);
  }

  private static enqueue<T>(operation: () => Promise<T>): Promise<T> {
    const queuedOperation = CalendarSyncCoordinator.operationQueue.then(operation, operation);
    CalendarSyncCoordinator.operationQueue = queuedOperation.then(
      (): void => {
      },
      (): void => {
      },
    );
    return queuedOperation;
  }

  private static copyEvent(
    event: CountdownEvent,
    source: EventSource,
    calendarEventID: string | undefined,
    calendarItemID: string | undefined = event.calendarItemID,
  ): CountdownEvent {
    return {
      id: event.id,
      title: event.title,
      nextOccurrence: event.nextOccurrence,
      originalDate: event.originalDate,
      category: event.category,
      dateCalendar: event.dateCalendar,
      recurrence: event.recurrence,
      source,
      isIgnored: event.isIgnored ?? false,
      calendarEventID,
      calendarItemID,
      notes: event.notes,
      reminderLeadTime: event.reminderLeadTime,
    };
  }
}
