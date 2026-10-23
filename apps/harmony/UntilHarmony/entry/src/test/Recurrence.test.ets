import { describe, expect, it } from '@ohos/hypium';
import { CountdownEventFactory, EventCategory, EventDateCalendar, EventRecurrence, ReminderLeadTime } from '../main/ets/model/CountdownEvent';
import { CountdownCalculator } from '../main/ets/services/CountdownCalculator';
import { CountdownEventCodec } from '../main/ets/repository/CountdownEventCodec';
import { EventFormViewModel } from '../main/ets/viewmodel/EventFormViewModel';
import { ReminderService } from '../main/ets/services/ReminderService';
import { CardTimelineProvider } from '../main/ets/card/CardTimelineProvider';

export default function recurrenceTest(): void {
  describe('Recurrence', () => {
    it('skips short Gregorian months and keeps the original day', 0, () => {
      const next = CountdownCalculator.nextOccurrence(new Date(2024, 0, 31), EventDateCalendar.Gregorian,
        EventRecurrence.Monthly, new Date(2024, 1, 1));
      expect(next.getMonth()).assertEqual(2);
      expect(next.getDate()).assertEqual(31);
    });

    it('includes leap lunar months and skips months without day thirty', 0, () => {
      const leap = CountdownCalculator.nextOccurrence(new Date(2023, 1, 20), EventDateCalendar.Lunar,
        EventRecurrence.Monthly, new Date(2023, 2, 21));
      expect(EventFormViewModel.dateText(leap)).assertEqual('2023-03-22');
      const thirty = CountdownCalculator.nextOccurrence(new Date(2023, 2, 21), EventDateCalendar.Lunar,
        EventRecurrence.Monthly, new Date(2023, 2, 22));
      expect(EventFormViewModel.dateText(thirty)).assertEqual('2023-06-17');
    });

    it('repeats weekly on local dates across year boundaries', 0, () => {
      const next = CountdownCalculator.nextOccurrence(new Date(2026, 11, 25), EventDateCalendar.Lunar,
        EventRecurrence.Weekly, new Date(2026, 11, 26));
      expect(EventFormViewModel.dateText(next)).assertEqual('2027-01-01');
    });

    it('preserves future first occurrences for all rules', 0, () => {
      const original = new Date(2027, 9, 23);
      const rules: EventRecurrence[] = [EventRecurrence.Yearly, EventRecurrence.Monthly, EventRecurrence.Weekly];
      rules.forEach((rule: EventRecurrence) => {
        expect(CountdownCalculator.nextOccurrence(original, EventDateCalendar.Lunar, rule,
          new Date(2026, 9, 23)).getTime()).assertEqual(original.getTime());
      });
    });

    it('persists recurrence and defaults legacy records to yearly', 0, () => {
      const event = CountdownEventFactory.create({ title: 'Repeat', originalDate: new Date(2026, 9, 16),
        category: EventCategory.Custom, recurrence: EventRecurrence.Weekly });
      const encoded = CountdownEventCodec.encode([event]);
      expect(CountdownEventCodec.decode(encoded)[0].recurrence).assertEqual(EventRecurrence.Weekly);
      const legacy = encoded.replace(',"recurrence":"weekly"', '');
      expect(CountdownEventCodec.decode(legacy)[0].recurrence).assertEqual(EventRecurrence.Yearly);
    });

    it('keeps the rule through editing and card date normalization', 0, () => {
      const event = CountdownEventFactory.create({ title: 'Repeat', originalDate: new Date(2026, 9, 16),
        category: EventCategory.Custom, recurrence: EventRecurrence.Weekly });
      const state = EventFormViewModel.stateFromEvent(event);
      expect(state.recurrence).assertEqual(EventRecurrence.Weekly);
      expect(EventFormViewModel.buildEvent(state, event)?.recurrence).assertEqual(EventRecurrence.Weekly);
      const normalized = CountdownCalculator.normalizedForDisplay(event, new Date(2026, 9, 24));
      expect(EventFormViewModel.dateText(normalized.nextOccurrence)).assertEqual('2026-10-30');
      expect(CardTimelineProvider.entries([event], 1, new Date(2026, 9, 24))[0].countdownBadgeText).assertEqual('6');
    });

    it('advances weekly seven day reminders past elapsed notification times', 0, () => {
      const event = CountdownEventFactory.create({ title: 'Repeat', originalDate: new Date(2026, 9, 16),
        category: EventCategory.Custom, recurrence: EventRecurrence.Weekly, reminderLeadTime: ReminderLeadTime.SevenDays });
      const dates = ReminderService.reminderDates(event, 3, new Date(2026, 9, 23, 10));
      expect(dates.length).assertEqual(3);
      expect(EventFormViewModel.dateText(dates[0])).assertEqual('2026-10-30');
      expect(EventFormViewModel.dateText(dates[1])).assertEqual('2026-11-06');
      expect(dates[0].getHours()).assertEqual(9);
    });

    it('does not merge yearly and weekly events sharing a title and date', 0, () => {
      const yearly = CountdownEventFactory.create({ title: 'Repeat', originalDate: new Date(2026, 9, 16), category: EventCategory.Custom });
      const weekly = CountdownEventFactory.create({ title: 'Repeat', originalDate: yearly.originalDate,
        category: EventCategory.Custom, recurrence: EventRecurrence.Weekly });
      expect(CountdownCalculator.matchesSameAnnualEvent(yearly, weekly)).assertFalse();
    });

    it('merges reminder series lazily without changing the nearest thirty results', 0, () => {
      const reference = new Date(2026, 9, 23, 10);
      const events = [
        CountdownEventFactory.create({ id: 'annual', title: 'Annual', originalDate: new Date(2000, 0, 31),
          category: EventCategory.Birthday, dateCalendar: EventDateCalendar.Lunar, reminderLeadTime: ReminderLeadTime.OneDay }),
        CountdownEventFactory.create({ id: 'weekly', title: 'Weekly', originalDate: new Date(2026, 9, 16),
          category: EventCategory.Custom, recurrence: EventRecurrence.Weekly, reminderLeadTime: ReminderLeadTime.SevenDays }),
        CountdownEventFactory.create({ id: 'monthly', title: 'Monthly', originalDate: new Date(2000, 0, 30),
          category: EventCategory.Custom, recurrence: EventRecurrence.Monthly, reminderLeadTime: ReminderLeadTime.ThreeDays }),
      ];
      const expected: string[] = [];
      const allDates: number[] = [];
      events.forEach((event) => {
        ReminderService.reminderDates(event, 30, reference).forEach((date: Date) => allDates.push(date.getTime()));
      });
      allDates.sort((first: number, second: number) => first - second);
      allDates.slice(0, 30).forEach((time: number) => expected.push(`${time}`));
      const actual = ReminderService.scheduledCandidates(events, reference);
      expect(actual.length).assertEqual(30);
      expect(actual.map((candidate) => `${candidate.reminderDate.getTime()}`).join(',')).assertEqual(expected.join(','));
    });

    it('does not duplicate exhausted lunar series or disabled reminders', 0, () => {
      const invalid = CountdownEventFactory.create({ title: 'Outside lunar range', originalDate: new Date(1800, 0, 1),
        category: EventCategory.Birthday, dateCalendar: EventDateCalendar.Lunar, reminderLeadTime: ReminderLeadTime.OneDay });
      const disabled = CountdownEventFactory.create({ title: 'Disabled', originalDate: new Date(2026, 9, 16),
        category: EventCategory.Custom, recurrence: EventRecurrence.Weekly, reminderLeadTime: ReminderLeadTime.None });
      expect(ReminderService.scheduledCandidates([invalid, disabled], new Date(2026, 9, 23)).length).assertEqual(0);
      const future = CountdownEventFactory.create({ title: 'Future lunar range', originalDate: new Date(2090, 0, 31),
        category: EventCategory.Birthday, dateCalendar: EventDateCalendar.Lunar, reminderLeadTime: ReminderLeadTime.OneDay });
      const dates = ReminderService.reminderDates(future, 30, new Date(2026, 9, 23));
      expect(dates.length > 0 && dates.length < 30).assertTrue();
      for (let index = 1; index < dates.length; index += 1) {
        expect(dates[index].getTime() > dates[index - 1].getTime()).assertTrue();
      }
    });
  });
}
