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
  countdownTextOverride: string = '';
  @Prop
  revealsExactCountdown: boolean = false;
  build() {
    Row({ space: 12 }) {
      this.categoryBadge()

      Column({ space: 4 }) {
        Text(this.event.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.primaryText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 6 }) {
          Text(EventPresentation.sourceSymbol(this.event.source))
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(EventPresentation.sourceColor(this.event.source))
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .borderRadius(8)
            .backgroundColor(AppTheme.elevatedBackground)

          Text(`${EventPresentation.displayDate(this.event.nextOccurrence, this.event.dateCalendar)} ${EventPresentation.sourceLabel(this.event.source)}`)
            .fontSize(13)
            .fontColor(AppTheme.secondaryText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 0 }) {
        Text(this.displayedCountdownText())
          .fontSize(this.countdownFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(EventPresentation.urgencyColor(this.event))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)

        if (this.shouldShowCountdownUnit()) {
          Text(L.text('countdown.day.unit'))
            .fontSize(11)
            .fontColor(AppTheme.secondaryText)
            .margin({ top: -2 })
        }
      }
      .width(72)
      .height(54)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.End)
      .borderRadius(13)
      .backgroundColor(EventPresentation.urgencySoftColor(this.event))
    }
    .width('100%')
    .padding({ left: 14, right: 12, top: 11, bottom: 11 })
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
    .accessibilityGroup(true)
    .accessibilityText(EventPresentation.accessibilityLabel(this.event))
    .accessibilityDescription(L.text('event.open_detail.hint'))
  }

  @Builder
  private categoryBadge() {
    Text(EventPresentation.categorySymbol(this.event.category))
      .fontSize(23)
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(this.categorySoftColor())
      .textAlign(TextAlign.Center)
  }

  private categorySoftColor(): ResourceColor {
    switch (this.event.category) {
      case EventCategory.Birthday:
        return AppTheme.warningSoft;
      case EventCategory.Anniversary:
        return AppTheme.dangerSoft;
      case EventCategory.Custom:
        return AppTheme.brandSoft;
    }
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

    return this.shouldShowCountdownUnit() ? 28 : 16;
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
