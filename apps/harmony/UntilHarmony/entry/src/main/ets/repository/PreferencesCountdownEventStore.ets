import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CountdownEvent } from '../model/CountdownEvent';
import { CountdownEventCodec } from './CountdownEventCodec';
import { CountdownEventStore } from './CountdownEventStore';

const STORE_NAME = 'until_countdown_events';
const EVENTS_KEY = 'countdownEvents';
const SAMPLE_EVENT_ID_PREFIX = 'sample-';

export class PreferencesCountdownEventStore implements CountdownEventStore {
  private context: common.Context;
  private store?: preferences.Preferences;
  private cachedEvents?: CountdownEvent[];

  constructor(context: common.Context) {
    this.context = context;
  }

  async load(): Promise<CountdownEvent[]> {
    if (this.cachedEvents !== undefined) {
      return this.copyEvents(this.cachedEvents);
    }

    try {
      const store = await this.preferencesStore();
      const rawValue = await store.get(EVENTS_KEY, '') as string;

      if (rawValue.trim().length === 0) {
        this.cachedEvents = [];
        return this.copyEvents(this.cachedEvents);
      }

      this.cachedEvents = this.removeLegacyDemoEvents(CountdownEventCodec.decode(rawValue));
      return this.copyEvents(this.cachedEvents);
    } catch (error) {
      console.error(`Failed to load countdown events: ${JSON.stringify(error)}`);
      this.cachedEvents = [];
      return this.copyEvents(this.cachedEvents);
    }
  }

  async save(events: CountdownEvent[]): Promise<void> {
    try {
      const store = await this.preferencesStore();
      await store.put(EVENTS_KEY, CountdownEventCodec.encode(events));
      await store.flush();
      this.cachedEvents = this.copyEvents(events);
    } catch (error) {
      console.error(`Failed to save countdown events: ${JSON.stringify(error)}`);
      throw new Error('Failed to save countdown events');
    }
  }

  private async preferencesStore(): Promise<preferences.Preferences> {
    if (this.store === undefined) {
      this.store = await preferences.getPreferences(this.context, STORE_NAME);
    }

    return this.store;
  }

  private copyEvents(events: CountdownEvent[]): CountdownEvent[] {
    return events.map((event: CountdownEvent): CountdownEvent => {
      return {
        id: event.id,
        title: event.title,
        nextOccurrence: new Date(event.nextOccurrence.getTime()),
        originalDate: new Date(event.originalDate.getTime()),
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
  }

  private removeLegacyDemoEvents(events: CountdownEvent[]): CountdownEvent[] {
    return events.filter((event: CountdownEvent) => !event.id.startsWith(SAMPLE_EVENT_ID_PREFIX));
  }
}
