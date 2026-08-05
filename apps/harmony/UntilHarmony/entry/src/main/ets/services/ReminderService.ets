import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { CountdownEvent, ReminderLeadTime } from '../model/CountdownEvent';
import { CountdownCalculator } from './CountdownCalculator';
import { L } from '../utils/LocalizedText';

const APP_BUNDLE_NAME = 'com.khalil.until';
const ENTRY_ABILITY_NAME = 'EntryAbility';
const REMINDER_HOUR = 9;
const MAX_VALID_REMINDERS = 30;

export interface ReminderScheduleCandidate {
  event: CountdownEvent;
  reminderDate: Date;
}

export class ReminderService {
  private static context?: common.UIAbilityContext;

  static configure(context: common.UIAbilityContext): void {
    ReminderService.context = context;
  }

  static async ensureAuthorizationAndReschedule(events: CountdownEvent[]): Promise<boolean> {
    const context = ReminderService.context;

    if (context === undefined) {
      return false;
    }

    const hasActiveReminder = events.some((event: CountdownEvent) =>
      event.reminderLeadTime !== ReminderLeadTime.None);

    if (!hasActiveReminder) {
      await ReminderService.cancelAll();
      return true;
    }

    try {
      const isEnabled = await notificationManager.isNotificationEnabled();

      if (!isEnabled) {
        await notificationManager.requestEnableNotification(context);
      }

      if (!await notificationManager.isNotificationEnabled()) {
        return false;
      }
    } catch (error) {
      console.error(`Failed to request notification permission: ${JSON.stringify(error)}`);
      return false;
    }

    await ReminderService.reschedule(events);
    return true;
  }

  static async isAuthorized(): Promise<boolean> {
    if (ReminderService.context === undefined) {
      return false;
    }

    try {
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      console.error(`Failed to read notification permission: ${JSON.stringify(error)}`);
      return false;
    }
  }

  static async reschedule(events: CountdownEvent[]): Promise<void> {
    if (ReminderService.context === undefined) {
      return;
    }

    try {
      const isEnabled = await notificationManager.isNotificationEnabled();

      if (!isEnabled) {
        return;
      }

      await ReminderService.cancelAll();

      const scheduledCandidates = ReminderService.scheduledCandidates(events);
      for (let index = 0; index < scheduledCandidates.length; index += 1) {
        await ReminderService.publish(
          scheduledCandidates[index].event,
          scheduledCandidates[index].reminderDate,
        );
      }
    } catch (error) {
      console.error(`Failed to reschedule reminders: ${JSON.stringify(error)}`);
    }
  }

  static scheduledCandidates(
    events: CountdownEvent[],
    referenceDate: Date = new Date(),
  ): ReminderScheduleCandidate[] {
    const activeEvents = events.filter((event: CountdownEvent) =>
      event.reminderLeadTime !== ReminderLeadTime.None);
    const candidates: ReminderScheduleCandidate[] = [];
    for (let index = 0; index < activeEvents.length; index += 1) {
      const reminderDates = ReminderService.reminderDates(activeEvents[index], 2, referenceDate);
      for (let reminderIndex = 0; reminderIndex < reminderDates.length; reminderIndex += 1) {
        candidates.push({
          event: activeEvents[index],
          reminderDate: reminderDates[reminderIndex],
        });
      }
    }

    candidates.sort((first: ReminderScheduleCandidate, second: ReminderScheduleCandidate) =>
      first.reminderDate.getTime() - second.reminderDate.getTime());
    return candidates.slice(0, MAX_VALID_REMINDERS);
  }

  static reminderDate(event: CountdownEvent, referenceDate: Date = new Date()): Date | undefined {
    return ReminderService.reminderDates(event, 1, referenceDate)[0];
  }

  static reminderDates(
    event: CountdownEvent,
    occurrenceCount: number = 2,
    referenceDate: Date = new Date(),
  ): Date[] {
    if (event.reminderLeadTime === ReminderLeadTime.None) {
      return [];
    }

    const reminderDates: Date[] = [];
    let occurrenceReference = new Date(referenceDate.getTime());
    const maximumAttempts = Math.max(occurrenceCount + 12, 14);

    for (let attempt = 0; attempt < maximumAttempts && reminderDates.length < occurrenceCount; attempt += 1) {
      const occurrence = CountdownCalculator.nextAnnualOccurrence(
        event.originalDate,
        event.dateCalendar,
        occurrenceReference,
      );
      const reminderDate = new Date(occurrence.getTime());
      reminderDate.setDate(reminderDate.getDate() - event.reminderLeadTime);
      reminderDate.setHours(REMINDER_HOUR, 0, 0, 0);

      if (reminderDate.getTime() > referenceDate.getTime()) {
        reminderDates.push(reminderDate);
      }

      occurrenceReference = new Date(occurrence.getTime());
      occurrenceReference.setDate(occurrenceReference.getDate() + 1);
    }

    return reminderDates;
  }

  private static async publish(event: CountdownEvent, reminderDate: Date): Promise<void> {
    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: reminderDate.getFullYear(),
        month: reminderDate.getMonth() + 1,
        day: reminderDate.getDate(),
        hour: reminderDate.getHours(),
        minute: reminderDate.getMinutes(),
        second: 0,
      },
      wantAgent: {
        pkgName: APP_BUNDLE_NAME,
        abilityName: ENTRY_ABILITY_NAME,
      },
      ringDuration: 1,
      title: L.text('notification.title'),
      content: L.format('notification.content', event.title),
      expiredContent: L.format('notification.content', event.title),
      notificationId: ReminderService.notificationID(`${event.id}-${reminderDate.getTime()}`),
      groupId: event.id,
      tapDismissed: true,
    };

    await reminderAgentManager.publishReminder(request);
  }

  private static async cancelAll(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
    } catch (error) {
      console.error(`Failed to cancel reminders: ${JSON.stringify(error)}`);
    }
  }

  private static notificationID(identifier: string): number {
    let hash = 0;

    for (let index = 0; index < identifier.length; index += 1) {
      hash = ((hash << 5) - hash + identifier.charCodeAt(index)) | 0;
    }

    return Math.abs(hash === 0 ? 1 : hash);
  }
}
