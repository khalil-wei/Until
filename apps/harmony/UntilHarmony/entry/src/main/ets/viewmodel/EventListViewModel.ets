import {
  CountdownEvent,
  EventCategory,
  EventSource,
} from '../model/CountdownEvent';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { CountdownEventStore } from '../repository/CountdownEventStore';
import { CountdownCardUpdateService } from '../card/CountdownCardDataSource';
import { ReminderService } from '../services/ReminderService';

export enum EventCategoryFilter {
  All = 'all',
  Birthday = 'birthday',
  Anniversary = 'anniversary',
  Custom = 'custom',
}

export class EventListViewModel {
  private static mutationQueue: Promise<void> = Promise.resolve();
  private store: CountdownEventStore;
  private events: CountdownEvent[] = [];
  private query: string = '';
  private categoryFilter: EventCategoryFilter = EventCategoryFilter.All;
  private hasLoaded: boolean = false;

  constructor(store: CountdownEventStore) {
    this.store = store;
  }

  async load(referenceDate: Date = new Date()): Promise<CountdownEvent[]> {
    const storedEvents = await this.store.load();
    this.events = CountdownCalculator.sortByNextOccurrence(storedEvents, referenceDate);
    this.hasLoaded = true;
    return this.visibleEvents(referenceDate);
  }

  allEvents(): CountdownEvent[] {
    return this.events.slice();
  }

  visibleEvents(referenceDate: Date = new Date()): CountdownEvent[] {
    const normalizedQuery = this.query.trim().toLocaleLowerCase();

    return this.events
      .filter((event: CountdownEvent) => {
        if (this.categoryFilter === EventCategoryFilter.All) {
          return true;
        }

        return event.category === this.categoryForFilter(this.categoryFilter);
      })
      .filter((event: CountdownEvent) => {
        if (normalizedQuery.length === 0) {
          return true;
        }

        return event.title.toLocaleLowerCase().includes(normalizedQuery);
      });
  }

  todayEvents(referenceDate: Date = new Date()): CountdownEvent[] {
    return this.visibleEvents(referenceDate)
      .filter((event: CountdownEvent) => CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate) === 0);
  }

  upcomingEvents(referenceDate: Date = new Date()): CountdownEvent[] {
    return this.visibleEvents(referenceDate)
      .filter((event: CountdownEvent) => CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate) !== 0);
  }

  setSearchQuery(query: string): void {
    this.query = query;
  }

  searchQuery(): string {
    return this.query;
  }

  setCategoryFilter(filter: EventCategoryFilter): void {
    this.categoryFilter = filter;
  }

  selectedCategoryFilter(): EventCategoryFilter {
    return this.categoryFilter;
  }

  async add(event: CountdownEvent, shouldRescheduleReminders: boolean = true): Promise<CountdownEvent[]> {
    await this.runMutation((events: CountdownEvent[]) => events.concat([event]), shouldRescheduleReminders);
    return this.visibleEvents();
  }

  async update(event: CountdownEvent, shouldRescheduleReminders: boolean = true): Promise<CountdownEvent[]> {
    await this.runMutation(
      (events: CountdownEvent[]) => events.map((current: CountdownEvent) => current.id === event.id ? event : current),
      shouldRescheduleReminders,
    );
    return this.visibleEvents();
  }

  async mergeCalendarSyncResult(
    eventID: string,
    source: EventSource,
    calendarEventID?: string,
    calendarItemID?: string,
    shouldRescheduleReminders: boolean = true,
  ): Promise<CountdownEvent[]> {
    await this.runMutation((events: CountdownEvent[]) => events.map((event: CountdownEvent) => {
        if (event.id !== eventID) {
          return event;
        }

        return {
          id: event.id,
          title: event.title,
          nextOccurrence: event.nextOccurrence,
          originalDate: event.originalDate,
          category: event.category,
          dateCalendar: event.dateCalendar,
          source: source,
          isIgnored: event.isIgnored ?? false,
          calendarEventID: calendarEventID,
          calendarItemID: calendarItemID,
          notes: event.notes,
          reminderLeadTime: event.reminderLeadTime,
        };
      }),
      shouldRescheduleReminders,
    );
    return this.visibleEvents();
  }

  async mergeImportedEvents(importedEvents: CountdownEvent[]): Promise<CountdownEvent[]> {
    await this.ensureLoaded();

    let didChange = false;
    // Remove mirror records produced by older builds that imported events from
    // Until's own system-calendar account back into the app.
    const nextEvents = this.events.filter((event: CountdownEvent) => {
      if (event.source !== EventSource.ImportedCalendar) {
        return true;
      }

      const hasLocalMirror = this.events.some((candidate: CountdownEvent) =>
        candidate.source !== EventSource.ImportedCalendar &&
        this.matchesMirrorEvent(candidate, event));

      if (hasLocalMirror) {
        didChange = true;
        return false;
      }

      return true;
    });

    importedEvents.forEach((importedEvent: CountdownEvent) => {
      const matchedIndex = nextEvents.findIndex((event: CountdownEvent) => {
        if (event.source !== EventSource.ImportedCalendar) {
          return false;
        }

        return event.calendarEventID === importedEvent.calendarEventID &&
          event.calendarItemID === importedEvent.calendarItemID;
      });

      if (matchedIndex >= 0) {
        nextEvents[matchedIndex] = this.copyImportedEvent(importedEvent, nextEvents[matchedIndex]);
        didChange = true;
        return;
      }

      const hasEquivalentEvent = nextEvents.some((event: CountdownEvent) => {
        if (event.source === EventSource.ImportedCalendar) {
          return false;
        }

        return CountdownCalculator.matchesSameAnnualEvent(event, importedEvent) ||
          this.matchesMirrorEvent(event, importedEvent);
      });

      if (!hasEquivalentEvent) {
        nextEvents.push(importedEvent);
        didChange = true;
      }
    });

    if (!didChange) {
      return this.visibleEvents();
    }

    this.events = nextEvents;
    this.sortEvents();
    await this.persist();
    return this.visibleEvents();
  }

  private matchesMirrorEvent(first: CountdownEvent, second: CountdownEvent): boolean {
    const firstTitle = first.title.trim().toLocaleLowerCase();
    const secondTitle = second.title.trim().toLocaleLowerCase();
    return firstTitle === secondTitle &&
      first.nextOccurrence.getMonth() === second.nextOccurrence.getMonth() &&
      first.nextOccurrence.getDate() === second.nextOccurrence.getDate();
  }

  async delete(eventID: string): Promise<CountdownEvent[]> {
    await this.runMutation((events: CountdownEvent[]) =>
      events.filter((event: CountdownEvent) => event.id !== eventID));
    return this.visibleEvents();
  }

  private async runMutation(
    mutation: (events: CountdownEvent[]) => CountdownEvent[],
    shouldRescheduleReminders: boolean = true,
  ): Promise<void> {
    const operation = async (): Promise<void> => {
      const latestEvents = await this.store.load();
      this.events = mutation(latestEvents);
      this.hasLoaded = true;
      this.sortEvents();
      await this.persist(shouldRescheduleReminders);
    };
    const queuedOperation = EventListViewModel.mutationQueue.then(operation, operation);
    EventListViewModel.mutationQueue = queuedOperation.then(
      (): void => {
      },
      (): void => {
      },
    );
    await queuedOperation;
  }

  private async persist(shouldRescheduleReminders: boolean = true): Promise<void> {
    await this.store.save(this.events);
    const revision = (AppStorage.get<number>('countdownEventsRevision') ?? 0) + 1;
    AppStorage.setOrCreate('countdownEventsRevision', revision);
    await CountdownCardUpdateService.refreshAfterEventChange(this.events);
    if (shouldRescheduleReminders) {
      await ReminderService.reschedule(this.events);
    }
  }

  private async ensureLoaded(): Promise<void> {
    if (!this.hasLoaded) {
      await this.load();
    }
  }

  private sortEvents(referenceDate: Date = new Date()): void {
    this.events = CountdownCalculator.sortByNextOccurrence(this.events, referenceDate);
  }

  private categoryForFilter(filter: EventCategoryFilter): EventCategory {
    switch (filter) {
      case EventCategoryFilter.Birthday:
        return EventCategory.Birthday;
      case EventCategoryFilter.Anniversary:
        return EventCategory.Anniversary;
      case EventCategoryFilter.Custom:
        return EventCategory.Custom;
      default:
        return EventCategory.Custom;
    }
  }

  private copyImportedEvent(importedEvent: CountdownEvent, existingEvent: CountdownEvent): CountdownEvent {
    return {
      id: existingEvent.id,
      title: importedEvent.title,
      nextOccurrence: importedEvent.nextOccurrence,
      originalDate: importedEvent.originalDate,
      category: importedEvent.category,
      dateCalendar: importedEvent.dateCalendar,
      source: EventSource.ImportedCalendar,
      isIgnored: false,
      calendarEventID: importedEvent.calendarEventID,
      calendarItemID: importedEvent.calendarItemID,
      notes: importedEvent.notes,
      reminderLeadTime: existingEvent.reminderLeadTime,
    };
  }

}
