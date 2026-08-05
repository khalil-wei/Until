import { common } from '@kit.AbilityKit';
import { CalendarService } from './CalendarService';
import { HarmonyCalendarService } from './HarmonyCalendarService';
import { UnavailableCalendarService } from './UnavailableCalendarService';

export class AppCalendarService {
  private static service: CalendarService = new UnavailableCalendarService();

  static configure(context: common.Context): void {
    AppCalendarService.service = new HarmonyCalendarService(context);
  }

  static shared(): CalendarService {
    return AppCalendarService.service;
  }
}
