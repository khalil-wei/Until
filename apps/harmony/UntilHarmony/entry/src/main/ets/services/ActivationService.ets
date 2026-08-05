import { CountdownEvent, ReminderLeadTime } from '../model/CountdownEvent';
import { UserJourneyState, UserJourneyStore } from '../repository/UserJourneyStore';

const ACTIVATION_CARD_COOLDOWN = 7 * 24 * 60 * 60 * 1000;

export enum ActivationState {
  Empty = 'empty',
  EventOnly = 'eventOnly',
  Activated = 'activated',
  Deferred = 'deferred',
}

export class ActivationService {
  private store: UserJourneyStore;

  constructor(store: UserJourneyStore) {
    this.store = store;
  }

  state(
    events: CountdownEvent[],
    hasNotificationPermission: boolean,
    registeredCardCount: number,
    now: Date = new Date(),
  ): ActivationState {
    if (events.length === 0) {
      return ActivationState.Empty;
    }

    if (ActivationService.hasActiveReminder(events, hasNotificationPermission) || registeredCardCount > 0) {
      return ActivationState.Activated;
    }

    return this.isActivationCardCoolingDown(this.store.load(), now)
      ? ActivationState.Deferred
      : ActivationState.EventOnly;
  }

  shouldShowFirstSaveGuide(eventCount: number): boolean {
    return eventCount === 1 && !this.store.load().hasSeenFirstSaveGuide;
  }

  markFirstSaveGuideSeen(): void {
    const state = this.store.load();
    this.store.save({
      hasSeenFirstSaveGuide: true,
      activationCardDismissedAt: state.activationCardDismissedAt,
      lastKnownCardCount: state.lastKnownCardCount,
    });
  }

  dismissActivationCard(now: Date = new Date()): void {
    const state = this.store.load();
    this.store.save({
      hasSeenFirstSaveGuide: state.hasSeenFirstSaveGuide,
      activationCardDismissedAt: now.getTime(),
      lastKnownCardCount: state.lastKnownCardCount,
    });
  }

  updateKnownCardCount(count: number): void {
    const state = this.store.load();
    this.store.save({
      hasSeenFirstSaveGuide: state.hasSeenFirstSaveGuide,
      activationCardDismissedAt: state.activationCardDismissedAt,
      lastKnownCardCount: Math.max(0, count),
    });
  }

  registeredCardCount(freshCount: number): number {
    return Math.max(freshCount, this.store.load().lastKnownCardCount);
  }

  static hasSelectedReminder(events: CountdownEvent[]): boolean {
    return events.some((event: CountdownEvent) => event.reminderLeadTime !== ReminderLeadTime.None);
  }

  static hasActiveReminder(events: CountdownEvent[], hasNotificationPermission: boolean): boolean {
    return hasNotificationPermission && ActivationService.hasSelectedReminder(events);
  }

  private isActivationCardCoolingDown(state: UserJourneyState, now: Date): boolean {
    if (state.activationCardDismissedAt <= 0) {
      return false;
    }

    const elapsed = now.getTime() - state.activationCardDismissedAt;
    return elapsed >= 0 && elapsed < ACTIVATION_CARD_COOLDOWN;
  }
}

