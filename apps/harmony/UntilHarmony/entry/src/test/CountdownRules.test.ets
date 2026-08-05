import { describe, expect, it } from '@ohos/hypium';
import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
  EventDateCalendar,
  ReminderLeadTime,
} from '../main/ets/model/CountdownEvent';
import { CountdownEventCodec } from '../main/ets/repository/CountdownEventCodec';
import { CountdownCalculator } from '../main/ets/services/CountdownCalculator';
import { ReminderService } from '../main/ets/services/ReminderService';
import { CalendarImportMapper } from '../main/ets/calendar/CalendarImportMapper';
import { InMemoryCountdownEventStore } from '../main/ets/repository/InMemoryCountdownEventStore';
import { EventListViewModel } from '../main/ets/viewmodel/EventListViewModel';
import { EventPresentation } from '../main/ets/utils/EventPresentation';
import { ActivationService, ActivationState } from '../main/ets/services/ActivationService';
import { InMemoryUserJourneyStore } from '../main/ets/repository/UserJourneyStore';
import { EventFormViewModel } from '../main/ets/viewmodel/EventFormViewModel';
import {
  CountdownCardConfigurationRules,
  CountdownCardContentMode,
  CountdownCardTheme,
} from '../main/ets/card/CountdownCardConfiguration';
import { CardTimelineProvider } from '../main/ets/card/CardTimelineProvider';

export default function countdownRulesTest(): void {
  describe('CountdownRules', () => {
    it('calculates today tomorrow and day after tomorrow', 0, () => {
      const reference = new Date(2026, 5, 30, 15, 30);
      expect(CountdownCalculator.daysUntil(new Date(2026, 5, 30), reference)).assertEqual(0);
      expect(CountdownCalculator.daysUntil(new Date(2026, 6, 1), reference)).assertEqual(1);
      expect(CountdownCalculator.daysUntil(new Date(2026, 6, 2), reference)).assertEqual(2);
    });

    it('skips invalid non leap years for February 29', 0, () => {
      const result = CountdownCalculator.nextAnnualOccurrence(
        new Date(2000, 1, 29),
        EventDateCalendar.Gregorian,
        new Date(2026, 5, 30),
      );

      expect(result.getFullYear()).assertEqual(2028);
      expect(result.getMonth()).assertEqual(1);
      expect(result.getDate()).assertEqual(29);
    });

    it('preserves a future selected date as the first annual occurrence', 0, () => {
      const result = CountdownCalculator.nextAnnualOccurrence(
        new Date(2027, 6, 13),
        EventDateCalendar.Gregorian,
        new Date(2026, 6, 13, 8, 30),
      );

      expect(result.getFullYear()).assertEqual(2027);
      expect(result.getMonth()).assertEqual(6);
      expect(result.getDate()).assertEqual(13);
    });

    it('preserves a future lunar date as the first annual occurrence', 0, () => {
      const originalDate = new Date(2027, 1, 6);
      const result = CountdownCalculator.nextAnnualOccurrence(
        originalDate,
        EventDateCalendar.Lunar,
        new Date(2026, 6, 14, 8, 30),
      );

      expect(result.getFullYear()).assertEqual(2027);
      expect(result.getMonth()).assertEqual(1);
      expect(result.getDate()).assertEqual(6);
    });

    it('caps countdown badges beyond 999 days', 0, () => {
      expect(CountdownCalculator.countdownBadgeText(999)).assertEqual('999');
      expect(CountdownCalculator.countdownBadgeText(1000)).assertEqual('1000+');
    });

    it('matches special numbers with language-aware 520 handling', 0, () => {
      expect(EventPresentation.specialNumberKey(42, false)).assertEqual('easter_egg.special.42');
      expect(EventPresentation.specialNumberKey(365, false)).assertEqual('easter_egg.special.365');
      expect(EventPresentation.specialNumberKey(520, true)).assertEqual('easter_egg.special.520');
      expect(EventPresentation.specialNumberKey(520, false) === undefined).assertTrue();
      expect(EventPresentation.specialNumberKey(41, true) === undefined).assertTrue();
    });

    it('limits the night letter by time events cadence and cooldown', 0, () => {
      const base = new Date(2026, 6, 14, 2, 0, 0);
      let eligibleDate = base;
      for (let offset = 0; offset < 5; offset += 1) {
        const candidate = new Date(2026, 6, 14 + offset, 2, 0, 0);
        if (EventPresentation.shouldShowNightLetter(candidate, 0, true)) {
          eligibleDate = candidate;
          break;
        }
      }

      expect(EventPresentation.shouldShowNightLetter(eligibleDate, 0, true)).assertTrue();
      expect(EventPresentation.shouldShowNightLetter(eligibleDate, 0, false)).assertFalse();
      expect(EventPresentation.shouldShowNightLetter(eligibleDate, eligibleDate.getTime(), true)).assertFalse();

      const daytime = new Date(
        eligibleDate.getFullYear(),
        eligibleDate.getMonth(),
        eligibleDate.getDate(),
        12,
      );
      expect(EventPresentation.shouldShowNightLetter(daytime, 0, true)).assertFalse();
    });

    it('matches distant reveal and arrival celebration rules', 0, () => {
      expect(EventPresentation.canRevealDistantCountdown(1000)).assertTrue();
      expect(EventPresentation.canRevealDistantCountdown(999)).assertFalse();
      expect(EventPresentation.canCelebrateArrival(0)).assertTrue();
      expect(EventPresentation.canCelebrateArrival(1)).assertFalse();

      const token = EventPresentation.arrivalDayToken(
        'event-42',
        new Date(2026, 6, 14, 22, 30),
      );
      expect(token).assertEqual('event-42|2026-7-14');
    });

    it('preserves events written concurrently by different view models', 0, async () => {
      const store = new InMemoryCountdownEventStore();
      const firstViewModel = new EventListViewModel(store);
      const secondViewModel = new EventListViewModel(store);
      const firstEvent = CountdownEventFactory.create({
        id: 'concurrent-first',
        title: 'First',
        originalDate: new Date(2030, 0, 1),
        category: EventCategory.Custom,
      });
      const secondEvent = CountdownEventFactory.create({
        id: 'concurrent-second',
        title: 'Second',
        originalDate: new Date(2030, 0, 2),
        category: EventCategory.Custom,
      });

      await Promise.all([
        firstViewModel.add(firstEvent, false),
        secondViewModel.add(secondEvent, false),
      ]);
      const storedEvents = await store.load();

      expect(storedEvents.length).assertEqual(2);
      expect(storedEvents.some((event) => event.id === firstEvent.id)).assertTrue();
      expect(storedEvents.some((event) => event.id === secondEvent.id)).assertTrue();
    });

    it('imports a regular device calendar event as custom', 0, () => {
      const imported = CalendarImportMapper.map({
        id: 'calendar-1',
        itemID: 'account-1',
        title: 'Three days later',
        startDate: new Date(2026, 6, 16),
      });

      expect(imported !== undefined).assertTrue();
      expect(imported?.category).assertEqual(EventCategory.Custom);
      expect(imported?.calendarEventID).assertEqual('calendar-1');
    });

    it('deduplicates normalized annual events', 0, () => {
      const lhs = CountdownEventFactory.create({
        id: 'lhs',
        title: 'Alice Birthday',
        originalDate: new Date(1998, 5, 30),
        category: EventCategory.Birthday,
      });
      const rhs = CountdownEventFactory.create({
        id: 'rhs',
        title: ' alice birthday ',
        originalDate: new Date(2026, 5, 30),
        category: EventCategory.Birthday,
      });

      expect(CountdownCalculator.matchesSameAnnualEvent(lhs, rhs)).assertTrue();
    });

    it('migrates legacy records with a visible ignored default', 0, () => {
      const legacyRecord: string = '[{"id":"legacy","title":"Legacy Event",' +
        '"nextOccurrence":"2026-07-10T00:00:00.000Z",' +
        '"originalDate":"2000-07-10T00:00:00.000Z","category":"birthday",' +
        '"dateCalendar":"gregorian","source":"local","reminderLeadTime":-1}]';
      const decoded = CountdownEventCodec.decode(legacyRecord);

      expect(decoded.length).assertEqual(1);
      expect(decoded[0].isIgnored === true).assertFalse();
    });

    it('calculates a nine oclock reminder using the selected lead time', 0, () => {
      const event = CountdownEventFactory.create({
        id: 'reminder',
        title: 'Reminder Event',
        originalDate: new Date(2030, 6, 10),
        nextOccurrence: new Date(2030, 6, 10),
        category: EventCategory.Custom,
        reminderLeadTime: ReminderLeadTime.ThreeDays,
      });
      const reminderDate = ReminderService.reminderDate(event);

      expect(reminderDate?.getFullYear()).assertEqual(2030);
      expect(reminderDate?.getMonth()).assertEqual(6);
      expect(reminderDate?.getDate()).assertEqual(7);
      expect(reminderDate?.getHours()).assertEqual(9);
    });

    it('keeps first creation local and requires explicit date confirmation', 0, () => {
      const state = EventFormViewModel.emptyState(EventCategory.Anniversary);
      state.title = 'Anniversary';

      expect(state.shouldSyncToCalendar).assertFalse();
      expect(state.hasConfirmedDate).assertFalse();
      expect(state.reminderLeadTime).assertEqual(ReminderLeadTime.OneDay);
      expect(EventFormViewModel.validate(state).isValid).assertFalse();

      state.hasConfirmedDate = true;
      expect(EventFormViewModel.validate(state).isValid).assertTrue();
    });

    it('derives activation from a usable reminder or desktop card', 0, () => {
      const store = new InMemoryUserJourneyStore();
      const activation = new ActivationService(store);
      const event = CountdownEventFactory.create({
        id: 'activation',
        title: 'Activation Event',
        originalDate: new Date(2030, 6, 10),
        category: EventCategory.Custom,
      });

      expect(activation.state([event], false, 0)).assertEqual(ActivationState.EventOnly);
      expect(activation.state([event], false, 1)).assertEqual(ActivationState.Activated);

      event.reminderLeadTime = ReminderLeadTime.OneDay;
      expect(activation.state([event], true, 0)).assertEqual(ActivationState.Activated);

      event.reminderLeadTime = ReminderLeadTime.None;
      activation.dismissActivationCard(new Date(2026, 6, 16));
      expect(activation.state([event], false, 0, new Date(2026, 6, 17))).assertEqual(ActivationState.Deferred);
    });

    it('shows the first save guide once for exactly one event', 0, () => {
      const activation = new ActivationService(new InMemoryUserJourneyStore());

      expect(activation.shouldShowFirstSaveGuide(0)).assertFalse();
      expect(activation.shouldShowFirstSaveGuide(1)).assertTrue();
      expect(activation.shouldShowFirstSaveGuide(2)).assertFalse();

      activation.markFirstSaveGuideSeen();
      expect(activation.shouldShowFirstSaveGuide(1)).assertFalse();
    });

    it('restores the activation task after the seven day cooldown', 0, () => {
      const activation = new ActivationService(new InMemoryUserJourneyStore());
      const event = CountdownEventFactory.create({
        id: 'cooldown-event',
        title: 'Cooldown Event',
        originalDate: new Date(2030, 6, 10),
        category: EventCategory.Custom,
      });
      const dismissedAt = new Date(2026, 6, 16, 10, 0, 0);
      activation.dismissActivationCard(dismissedAt);

      expect(activation.state(
        [event],
        false,
        0,
        new Date(2026, 6, 23, 9, 59, 59),
      )).assertEqual(ActivationState.Deferred);
      expect(activation.state(
        [event],
        false,
        0,
        new Date(2026, 6, 23, 10, 0, 0),
      )).assertEqual(ActivationState.EventOnly);
    });

    it('prepares the next two annual reminder occurrences', 0, () => {
      const event = CountdownEventFactory.create({
        id: 'recurring-reminder',
        title: 'Recurring Reminder',
        originalDate: new Date(2000, 6, 10),
        category: EventCategory.Birthday,
        reminderLeadTime: ReminderLeadTime.ThreeDays,
      });
      const reminderDates = ReminderService.reminderDates(event, 2, new Date(2026, 0, 1));

      expect(reminderDates.length).assertEqual(2);
      expect(reminderDates[0].getFullYear()).assertEqual(2026);
      expect(reminderDates[0].getMonth()).assertEqual(6);
      expect(reminderDates[0].getDate()).assertEqual(7);
      expect(reminderDates[1].getFullYear()).assertEqual(2027);
      expect(reminderDates[1].getMonth()).assertEqual(6);
      expect(reminderDates[1].getDate()).assertEqual(7);
    });

    it('keeps only the nearest thirty reminder candidates', 0, () => {
      const events: CountdownEvent[] = [];
      for (let day = 1; day <= 16; day += 1) {
        events.push(CountdownEventFactory.create({
          id: `limited-reminder-${day}`,
          title: `Limited Reminder ${day}`,
          originalDate: new Date(2000, 6, day),
          category: EventCategory.Custom,
          reminderLeadTime: ReminderLeadTime.OneDay,
        }));
      }

      const candidates = ReminderService.scheduledCandidates(events, new Date(2026, 0, 1));

      expect(candidates.length).assertEqual(30);
      expect(candidates[0].reminderDate.getFullYear()).assertEqual(2026);
      expect(candidates[0].reminderDate.getMonth()).assertEqual(5);
      expect(candidates[0].reminderDate.getDate()).assertEqual(30);
      expect(candidates[29].reminderDate.getFullYear()).assertEqual(2027);
      expect(candidates[29].reminderDate.getMonth()).assertEqual(6);
      expect(candidates[29].reminderDate.getDate()).assertEqual(13);
    });

    it('migrates legacy card configuration without losing its featured event', 0, () => {
      const migrated = CountdownCardConfigurationRules.migrateInstance({
        id: 'legacy-form',
        featuredEventID: 'birthday-1',
        theme: CountdownCardTheme.Midnight,
      });

      expect(migrated?.id).assertEqual('legacy-form');
      expect(migrated?.contentMode).assertEqual(CountdownCardContentMode.Featured);
      expect(migrated?.featuredEventID).assertEqual('birthday-1');
      expect(migrated?.theme).assertEqual(CountdownCardTheme.Midnight);
    });

    it('falls back to automatic order when the featured event is unavailable', 0, () => {
      const configuration = CountdownCardConfigurationRules.normalizeConfiguration(
        CountdownCardContentMode.Featured,
        'deleted-event',
        CountdownCardTheme.Colorful,
      );

      expect(CountdownCardConfigurationRules.effectiveFeaturedEventID(
        configuration,
        ['remaining-event'],
      ) === undefined).assertTrue();
    });

    it('keeps a fixed card event first and sorts remaining events by date', 0, () => {
      const referenceDate = new Date(2026, 0, 1);
      const nearest = CountdownEventFactory.create({
        id: 'nearest-card-event',
        title: 'Nearest',
        originalDate: new Date(2026, 0, 3),
        category: EventCategory.Custom,
      });
      const fixed = CountdownEventFactory.create({
        id: 'fixed-card-event',
        title: 'Fixed',
        originalDate: new Date(2026, 0, 20),
        category: EventCategory.Custom,
      });
      const middle = CountdownEventFactory.create({
        id: 'middle-card-event',
        title: 'Middle',
        originalDate: new Date(2026, 0, 10),
        category: EventCategory.Custom,
      });

      const entries = CardTimelineProvider.entries(
        [fixed, middle, nearest],
        3,
        referenceDate,
        fixed.id,
      );

      expect(entries[0].id).assertEqual(fixed.id);
      expect(entries[1].id).assertEqual(nearest.id);
      expect(entries[2].id).assertEqual(middle.id);

      const smallEntries = CardTimelineProvider.entries(
        [fixed, middle, nearest],
        1,
        referenceDate,
        fixed.id,
      );
      expect(smallEntries.length).assertEqual(1);
      expect(smallEntries[0].id).assertEqual(fixed.id);

      const deletedFixedEntries = CardTimelineProvider.entries(
        [middle, nearest],
        2,
        referenceDate,
        fixed.id,
      );
      expect(deletedFixedEntries[0].id).assertEqual(nearest.id);
      expect(deletedFixedEntries[1].id).assertEqual(middle.id);
    });
  });
}
