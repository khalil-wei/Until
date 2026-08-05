import { CountdownEvent } from '../model/CountdownEvent';

export interface CalendarPermissionStatus {
  canRead: boolean;
  canWrite: boolean;
  isRestricted: boolean;
}

export interface CalendarService {
  permissionStatus(): Promise<CalendarPermissionStatus>;
  requestWritePermission(): Promise<CalendarPermissionStatus>;
  createAnnualEvent(event: CountdownEvent): Promise<string | undefined>;
  updateAnnualEvent(calendarEventID: string, event: CountdownEvent): Promise<boolean>;
  deleteCalendarEvent(calendarEventID: string): Promise<boolean>;
}
