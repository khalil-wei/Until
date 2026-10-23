import {
  abilityAccessCtrl,
  bundleManager,
  common,
  Permissions,
} from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import {
  CountdownEvent,
  EventDateCalendar,
  EventRecurrence,
  ReminderLeadTime,
} from '../model/CountdownEvent';
import {
  CalendarPermissionStatus,
  CalendarService,
} from './CalendarService';
const READ_CALENDAR_PERMISSION: Permissions = 'ohos.permission.READ_CALENDAR';
const WRITE_CALENDAR_PERMISSION: Permissions = 'ohos.permission.WRITE_CALENDAR';
const CALENDAR_ACCOUNT_NAME = 'until-countdown-calendar';
const CALENDAR_ACCOUNT_DISPLAY_NAME = '待到';

export class HarmonyCalendarService implements CalendarService {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async permissionStatus(): Promise<CalendarPermissionStatus> {
    try {
      return {
        canRead: this.hasPermission(READ_CALENDAR_PERMISSION),
        canWrite: this.hasPermission(WRITE_CALENDAR_PERMISSION),
        isRestricted: false,
      };
    } catch (error) {
      return {
        canRead: false,
        canWrite: false,
        isRestricted: true,
      };
    }
  }

  async requestWritePermission(): Promise<CalendarPermissionStatus> {
    const currentStatus = await this.permissionStatus();

    if (currentStatus.canRead && currentStatus.canWrite) {
      return currentStatus;
    }

    const missingPermissions: Permissions[] = [];
    if (!currentStatus.canRead) {
      missingPermissions.push(READ_CALENDAR_PERMISSION);
    }
    if (!currentStatus.canWrite) {
      missingPermissions.push(WRITE_CALENDAR_PERMISSION);
    }
    return this.requestPermissions(missingPermissions);
  }

  private async requestPermissions(permissions: Permissions[]): Promise<CalendarPermissionStatus> {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const result = await manager.requestPermissionsFromUser(this.context, permissions);
      let status = await this.permissionStatus();

      if (this.hasRequestedPermissions(status, permissions)) {
        return status;
      }

      const didShowDialog = result.dialogShownResults?.some((wasShown: boolean) => wasShown) ?? true;

      if (didShowDialog) {
        return status;
      }

      try {
        await manager.requestPermissionOnSetting(this.context, permissions);
        status = await this.permissionStatus();
      } catch (settingError) {
        console.warn(`Secondary calendar authorization unavailable: ${JSON.stringify(settingError)}`);
        status.isRestricted = true;
      }

      return status;
    } catch (error) {
      const status = await this.permissionStatus();
      status.isRestricted = true;
      return status;
    }
  }

  private hasRequestedPermissions(status: CalendarPermissionStatus, permissions: Permissions[]): boolean {
    const hasRead = !permissions.includes(READ_CALENDAR_PERMISSION) || status.canRead;
    const hasWrite = !permissions.includes(WRITE_CALENDAR_PERMISSION) || status.canWrite;
    return hasRead && hasWrite;
  }

  async createAnnualEvent(event: CountdownEvent): Promise<string | undefined> {
    try {
      const calendar = await this.untilCalendar();
      const eventID = await calendar.addEvent(this.calendarEventFromCountdown(event));
      return `${eventID}`;
    } catch (error) {
      return undefined;
    }
  }

  async updateAnnualEvent(calendarEventID: string, event: CountdownEvent): Promise<boolean> {
    try {
      const eventID = Number(calendarEventID);

      if (!Number.isFinite(eventID)) {
        return false;
      }

      const calendar = await this.untilCalendar();
      const calendarEvent = this.calendarEventFromCountdown(event);
      calendarEvent.id = eventID;
      await calendar.updateEvent(calendarEvent);
      return true;
    } catch (error) {
      return false;
    }
  }

  async deleteCalendarEvent(calendarEventID: string): Promise<boolean> {
    try {
      const eventID = Number(calendarEventID);

      if (!Number.isFinite(eventID)) {
        return false;
      }

      const calendar = await this.untilCalendar();
      const existingEvents = await calendar.getEvents(
        calendarManager.EventFilter.filterById([eventID]),
        ['id'],
      );
      if (!existingEvents.some((event: calendarManager.Event) => event.id === eventID)) {
        return true;
      }

      await calendar.deleteEvent(eventID);
      return true;
    } catch (error) {
      return false;
    }
  }

  private async untilCalendar(): Promise<calendarManager.Calendar> {
    const manager = calendarManager.getCalendarManager(this.context);
    const account: calendarManager.CalendarAccount = {
      name: CALENDAR_ACCOUNT_NAME,
      type: calendarManager.CalendarType.LOCAL,
      displayName: CALENDAR_ACCOUNT_DISPLAY_NAME,
    };

    try {
      return await manager.getCalendar(account);
    } catch (error) {
      const calendar = await manager.createCalendar(account);
      await calendar.setConfig({
        enableReminder: true,
        color: '#0EA58B',
      });
      return calendar;
    }
  }

  private hasPermission(permission: Permissions): boolean {
    const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    const tokenID = info.appInfo.accessTokenId;
    const manager = abilityAccessCtrl.createAtManager();
    return manager.checkAccessTokenSync(tokenID, permission) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  private reminderMinutes(reminderLeadTime: ReminderLeadTime): number | undefined {
    if (reminderLeadTime === ReminderLeadTime.None) {
      return undefined;
    }

    return reminderLeadTime * 24 * 60;
  }

  private startOfDay(date: Date): Date {
    const nextDate = new Date(date.getTime());
    nextDate.setHours(0, 0, 0, 0);
    return nextDate;
  }

  private calendarEventFromCountdown(event: CountdownEvent): calendarManager.Event {
    const startTime = this.startOfDay(event.originalDate).getTime();
    const endDay = this.startOfDay(event.originalDate);
    endDay.setDate(endDay.getDate() + 1);
    const endTime = endDay.getTime();
    const calendarEvent: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: event.title,
      startTime,
      endTime,
      isAllDay: true,
      description: event.notes,
      identifier: `until-${event.id}`,
      isLunar: event.dateCalendar === EventDateCalendar.Lunar && event.recurrence !== EventRecurrence.Weekly,
      recurrenceRule: {
        recurrenceFrequency: event.recurrence === EventRecurrence.Monthly
          ? calendarManager.RecurrenceFrequency.MONTHLY
          : event.recurrence === EventRecurrence.Weekly
            ? calendarManager.RecurrenceFrequency.WEEKLY : calendarManager.RecurrenceFrequency.YEARLY,
        interval: 1,
      },
    };
    const reminderMinutes = this.reminderMinutes(event.reminderLeadTime);

    if (reminderMinutes !== undefined) {
      calendarEvent.reminderTime = [reminderMinutes];
    }

    return calendarEvent;
  }
}
