import { CountdownEvent } from '../model/CountdownEvent';
import {
  CalendarPermissionStatus,
  CalendarService,
} from './CalendarService';

export class UnavailableCalendarService implements CalendarService {
  async permissionStatus(): Promise<CalendarPermissionStatus> {
    return {
      canRead: false,
      canWrite: false,
      isRestricted: true,
    };
  }

  async requestWritePermission(): Promise<CalendarPermissionStatus> {
    return this.permissionStatus();
  }

  async createAnnualEvent(event: CountdownEvent): Promise<string | undefined> {
    return undefined;
  }

  async updateAnnualEvent(calendarEventID: string, event: CountdownEvent): Promise<boolean> {
    return false;
  }

  async deleteCalendarEvent(calendarEventID: string): Promise<boolean> {
    return false;
  }
}
