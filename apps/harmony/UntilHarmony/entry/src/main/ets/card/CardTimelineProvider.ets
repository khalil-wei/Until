import { CountdownEvent } from '../model/CountdownEvent';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';

export interface CountdownCardEntry {
  id: string;
  title: string;
  dateText: string;
  countdownText: string;
  countdownBadgeText: string;
  countdownUnitText: string;
  shouldShowCountdownUnit: boolean;
  categorySymbol: string;
  categoryLabel: string;
  urgencyColor: string;
}

export class CardTimelineProvider {
  static entries(
    events: CountdownEvent[],
    limit: number,
    referenceDate: Date = new Date(),
    featuredEventID?: string,
  ): CountdownCardEntry[] {
    const sortedEvents = CountdownCalculator.sortByNextOccurrence(events, referenceDate);
    const featuredIndex = featuredEventID === undefined
      ? -1
      : sortedEvents.findIndex((event: CountdownEvent) => event.id === featuredEventID);
    const orderedEvents = featuredIndex < 0
      ? sortedEvents
      : [sortedEvents[featuredIndex]].concat(
        sortedEvents.filter((event: CountdownEvent) => event.id !== featuredEventID),
      );

    return orderedEvents
      .slice(0, limit)
      .map((event: CountdownEvent): CountdownCardEntry => {
        const days = CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate);

        return {
          id: event.id,
          title: event.title,
          dateText: EventPresentation.displayDate(event.nextOccurrence, event.dateCalendar),
          countdownText: EventPresentation.countdownText(event, referenceDate),
          countdownBadgeText: EventPresentation.countdownBadgeText(event, referenceDate),
          countdownUnitText: L.text('countdown.future.unit'),
          shouldShowCountdownUnit: EventPresentation.shouldShowCountdownUnit(event, referenceDate),
          categorySymbol: EventPresentation.categorySymbol(event.category),
          categoryLabel: EventPresentation.categoryLabel(event.category),
          urgencyColor: CardTimelineProvider.urgencyColor(days),
        };
      });
  }

  private static urgencyColor(days: number): string {
    if (days <= 0) {
      return '#C44761';
    }

    if (days <= 7) {
      return '#D47A20';
    }

    if (days <= 30) {
      return '#5270C9';
    }

    return '#2F8E75';
  }
}
