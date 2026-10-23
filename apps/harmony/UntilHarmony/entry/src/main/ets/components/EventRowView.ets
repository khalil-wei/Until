import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
} from '../model/CountdownEvent';
import { AppTheme } from '../utils/AppTheme';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';
import { CountdownCalculator } from '../services/CountdownCalculator';

@Component
export struct EventRowView {
  @Prop
  event: CountdownEvent = CountdownEventFactory.create({
    title: '',
    originalDate: new Date(),
    category: EventCategory.Custom,
  });
  @Prop
  compact: boolean = false;
  @Prop
  countdownTextOverride: string = '';
  @Prop
  revealsExactCountdown: boolean = false;
  build() {
    Row({ space: 12 }) {
      this.categoryBadge()

      Column({ space: 5 }) {
        Text(this.event.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.compact) {
          Text(this.compactDateText())
            .fontSize(12)
            .fontColor(AppTheme.secondaryText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        } else {
        Row({ space: 6 }) {
          Text(EventPresentation.sourceSymbol(this.event.source))
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(EventPresentation.sourceColor(this.event.source))
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .borderRadius(8)
            .backgroundColor(Color.Transparent)

          Text(`${EventPresentation.displayDate(this.event.nextOccurrence, this.event.dateCalendar)} ${EventPresentation.sourceLabel(this.event.source)}`)
            .fontSize(13)
            .fontColor(AppTheme.secondaryText)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 0 }) {
        Text(this.displayedCountdownText())
          .fontSize(this.countdownFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor(EventPresentation.categoryColor(this.event.category))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)

        if (this.shouldShowCountdownUnit()) {
          Text(L.text('countdown.day.unit'))
            .fontSize(AppTheme.supportingTextSize)
            .fontColor(AppTheme.secondaryText)
        }
      }
      .constraintSize({ minWidth: 64, maxWidth: '36%', minHeight: 50 })
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 15, bottom: 15 })
    .margin({ bottom: 8 })
    .borderRadius(16)
    .backgroundColor(EventPresentation.categoryBackground(this.event.category))
    .accessibilityGroup(true)
    .accessibilityText(EventPresentation.accessibilityLabel(this.event))
    .accessibilityDescription(L.text('event.open_detail.hint'))
  }

  @Builder
  private categoryBadge() {
    Image(EventPresentation.categoryIcon(this.event.category))
      .width(32)
      .height(32)
      .padding(6)
      .fillColor(EventPresentation.categoryColor(this.event.category))
      .borderRadius(12)
      .backgroundColor(AppTheme.cardBackground)
  }

  private compactDateText(): string {
    return EventPresentation.compactDate(this.event.nextOccurrence, this.event.dateCalendar);
  }

  private countdownFontSize(): number {
    const badge = this.displayedCountdownText();
    if (badge.length === 4 && L.isZh()) {
      return 14;
    }

    if (badge.length > 4) {
      return 18;
    }

    if (badge.length > 3) {
      return 23;
    }

    return this.shouldShowCountdownUnit() ? 30 : 16;
  }

  private displayedCountdownText(): string {
    if (this.countdownTextOverride.length > 0) {
      return this.countdownTextOverride;
    }

    if (this.revealsExactCountdown) {
      return `${CountdownCalculator.daysUntil(this.event.nextOccurrence)}`;
    }

    return EventPresentation.countdownBadgeText(this.event);
  }

  private shouldShowCountdownUnit(): boolean {
    if (this.countdownTextOverride.length > 0) {
      return false;
    }

    if (this.revealsExactCountdown) {
      return CountdownCalculator.daysUntil(this.event.nextOccurrence) > 2;
    }

    return EventPresentation.shouldShowCountdownUnit(this.event);
  }
}
