import { router } from '@kit.ArkUI';
import { CalendarSyncCoordinator } from '../calendar/CalendarSyncCoordinator';
import { EventRowView } from '../components/EventRowView';
import {
  CountdownEvent,
  CountdownEventFactory,
  EventCategory,
  EventDateCalendar,
  EventSource,
} from '../model/CountdownEvent';
import { AppEventStore } from '../repository/AppEventStore';
import { AppTheme } from '../utils/AppTheme';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';
import { EventListViewModel } from '../viewmodel/EventListViewModel';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { accessibility } from '@kit.AccessibilityKit';

interface EventRouteParams {
  eventID?: string;
}

@Entry
@Component
struct EventDetailPage {
  private viewModel: EventListViewModel = new EventListViewModel(AppEventStore.shared());
  private currentEventID: string = '';
  private activeRouteTimer: number = -1;
  private loadRevision: number = 0;
  private distantRevealTimer: number = -1;
  private distantConvergenceTimer: number = -1;
  private arrivalCelebrationTimer: number = -1;
  private distantStarIndices: number[] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
    12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
  ];

  @StorageProp('activeCardEventID') @Watch('handleActiveCardRoute') activeCardEventID: string = '';

  @State private event: CountdownEvent = CountdownEventFactory.create({
    title: '',
    originalDate: new Date(),
    category: EventCategory.Custom,
  });
  @State private hasEvent: boolean = false;
  @State private isMutating: boolean = false;
  @State private actionError: string = '';
  @State private isDistantCountdownRevealed: boolean = false;
  @State private areDistantStarsConverged: boolean = false;
  @State private isArrivalCelebrating: boolean = false;
  @State private didReplayArrivalManually: boolean = false;
  @State private reduceMotionEnabled: boolean = false;

  aboutToAppear(): void {
    this.refreshReduceMotionPreference();
    AppStorage.setOrCreate('isEventDetailActive', true);
    this.loadEvent();
    this.activeRouteTimer = setInterval(() => {
      this.consumeActiveCardRoute();
    }, 200);
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate('isEventDetailActive', false);
    if (this.activeRouteTimer >= 0) {
      clearInterval(this.activeRouteTimer);
      this.activeRouteTimer = -1;
    }
    if (this.distantRevealTimer >= 0) {
      clearTimeout(this.distantRevealTimer);
      this.distantRevealTimer = -1;
    }
    if (this.distantConvergenceTimer >= 0) {
      clearTimeout(this.distantConvergenceTimer);
      this.distantConvergenceTimer = -1;
    }
    if (this.arrivalCelebrationTimer >= 0) {
      clearTimeout(this.arrivalCelebrationTimer);
      this.arrivalCelebrationTimer = -1;
    }
  }

  onPageShow(): void {
    this.loadEvent();
  }

  private handleActiveCardRoute(): void {
    this.consumeActiveCardRoute();
  }

  private consumeActiveCardRoute(): void {
    const pendingEventID = AppStorage.get<string>('activeCardEventID') ?? '';
    if (pendingEventID.length === 0) {
      return;
    }

    if (pendingEventID === this.currentEventID) {
      AppStorage.setOrCreate('activeCardEventID', '');
      return;
    }

    this.currentEventID = pendingEventID;
    console.info(`Countdown detail switching to eventID=${pendingEventID}`);
    this.loadEvent();
  }

  build() {
    Stack() {
      Column() {
        this.navigationBar()

        if (!this.hasEvent) {
          Column() {
            Text(L.text('detail.not_found'))
              .fontSize(16)
              .fontColor(AppTheme.secondaryText)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: 14 }) {
              this.detailCountdownRow()
              this.countdownEasterEggFeedback()
              this.specialNumberMessage()
              this.infoSection()
              if (this.hasNotes()) {
                this.notesSection()
              }
              this.actionsSection()
              this.actionErrorMessage()
            }
            .width('100%')
            .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, bottom: 28 })
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.pageBackground)

      if (this.isDistantCountdownRevealed) {
        this.distantStarConvergenceOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private detailCountdownRow() {
    EventRowView({
      event: this.event,
      countdownTextOverride: this.isArrivalCelebrating ? L.text('easter_egg.arrived') : '',
      revealsExactCountdown: false,
    })
      .gesture(
        LongPressGesture({
          repeat: false,
          duration: this.distantRevealEligible() ? 1500 : 1000,
        }).onAction(() => {
          this.handleCountdownLongPress();
        })
      )
      .accessibilityDescription(this.countdownInteractionHint())
  }

  @Builder
  private countdownEasterEggFeedback() {
    if (this.isArrivalCelebrating) {
      Row({ space: 18 }) {
        this.arrivalDecoration()
        Text(L.text('easter_egg.arrived'))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(EventPresentation.urgencyColor(this.event))
        this.arrivalDecoration()
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 11, bottom: 11 })
      .borderRadius(AppTheme.cardRadius)
      .backgroundColor(EventPresentation.urgencySoftColor(this.event))
      .transition(TransitionEffect.OPACITY)
      .accessibilityText(L.text('easter_egg.arrived'))
    }
  }

  @Builder
  private arrivalDecoration() {
    if (this.event.category === EventCategory.Birthday) {
      Column({ space: 0 }) {
        Row()
          .width(14)
          .height(17)
          .borderRadius(8)
          .backgroundColor('#DE7184')
        Row()
          .width(4)
          .height(4)
          .rotate({ angle: 45 })
          .backgroundColor('#C45E73')
        Row()
          .width(1)
          .height(8)
          .rotate({ angle: 12 })
          .backgroundColor('#A9878F')
      }
      .width(18)
      .height(30)
      .alignItems(HorizontalAlign.Center)
      .accessibilityText(L.categoryLabel(EventCategory.Birthday))
    } else {
      Text(this.arrivalSymbol())
        .fontSize(18)
    }
  }

  @Builder
  private distantStarConvergenceOverlay() {
    Stack() {
      ForEach(this.distantStarIndices, (index: number) => {
        Text(this.distantStarSymbol(index))
          .fontSize(6 + index % 5 * 2)
          .fontColor(this.distantStarColor(index))
          .opacity(this.areDistantStarsConverged ? 0.28 : 0.82)
          .scale({ x: this.areDistantStarsConverged ? 0.58 : 1, y: this.areDistantStarsConverged ? 0.58 : 1 })
          .position({
            x: this.distantStarX(index),
            y: this.distantStarY(index),
          })
      }, (index: number) => `${index}`)

      Column({ space: 8 }) {
        Row({ space: 7 }) {
          Text(`${CountdownCalculator.daysUntil(this.event.nextOccurrence)}`)
            .fontSize(58)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(L.text('countdown.day.unit'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#B8D2D2')
        }
        .alignItems(VerticalAlign.Bottom)

        Text(L.text('easter_egg.distant.message'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#C6DBD9')
          .textAlign(TextAlign.Center)
      }
      .opacity(this.areDistantStarsConverged ? 1 : 0)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor('#10282E')
    .onClick(() => {
      this.dismissDistantReveal();
    })
    .accessibilityText(
      `${CountdownCalculator.daysUntil(this.event.nextOccurrence)} ${L.text('countdown.day.unit')}，` +
        L.text('easter_egg.distant.message'),
    )
  }

  @Builder
  private specialNumberMessage() {
    if (this.specialNumberKey() !== undefined) {
      Row({ space: 10 }) {
        Text('✦')
          .fontSize(14)
          .fontColor(AppTheme.brand)

        Text(L.text(this.specialNumberKey() ?? ''))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.brand)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 13, bottom: 13 })
      .borderRadius(AppTheme.cardRadius)
      .backgroundColor(AppTheme.brandSoft)
      .accessibilityText(L.text(this.specialNumberKey() ?? ''))
    }
  }

  @Builder
  private actionErrorMessage() {
    if (this.actionError.length > 0) {
      Text(this.actionError)
        .fontSize(13)
        .fontColor(AppTheme.danger)
        .width('100%')
        .padding({ left: 4, right: 4 })
    }
  }

  @Builder
  private navigationBar() {
    Row({ space: 14 }) {
      Button('\u2039')
        .fontSize(30)
        .fontColor(AppTheme.primaryText)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor(AppTheme.cardBackground)
        .onClick(() => {
          router.back();
        })
        .accessibilityText(L.text('action.done'))

      Column({ space: 2 }) {
        Text(L.text('detail.title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
        Text(L.text('app.subtitle'))
          .fontSize(12)
          .fontColor(AppTheme.tertiaryText)
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Button(L.text('action.edit'))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.hasEvent && !this.isMutating ? AppTheme.brand : AppTheme.disabledText)
        .height(38)
        .padding({ left: 14, right: 14 })
        .borderRadius(19)
        .backgroundColor(this.hasEvent && !this.isMutating ? AppTheme.brandSoft : AppTheme.disabledBackground)
        .enabled(this.hasEvent && !this.isMutating)
        .onClick(() => {
          if (this.hasEvent && !this.isMutating) {
            router.pushUrl({ url: 'pages/EditEventPage', params: { eventID: this.event.id } });
          }
        })
    }
    .width('100%')
    .height(80)
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding })
  }

  @Builder
  private infoSection() {
    Column({ space: 14 }) {
      Column({ space: 8 }) {
        this.infoSectionTitle(L.text('detail.basic_info'))

        Column() {
          this.infoRow(L.text('detail.category'), EventPresentation.categoryLabel(this.event.category))
          this.divider()
          this.infoRow(L.text('detail.original_date'), this.originalDateText(), true)
          this.divider()
          this.infoRow(L.text('detail.next_date'), this.nextOccurrenceText(), true)
          this.divider()
          this.infoRow(L.text('detail.repeat'), L.text('detail.repeat.yearly'))
        }
        .width('100%')
        .borderRadius(AppTheme.cardRadius)
        .backgroundColor(AppTheme.cardBackground)
      }
      .width('100%')

      Column({ space: 8 }) {
        this.infoSectionTitle(L.text('detail.settings'))

        Column() {
          this.infoRow(L.text('detail.reminder'), EventPresentation.reminderLabel(this.event.reminderLeadTime))
          this.divider()
          this.infoRow(L.text('detail.calendar'), EventPresentation.calendarLabel(this.event.dateCalendar))
          this.divider()
          this.infoRow(L.text('detail.source'), EventPresentation.sourceLabel(this.event.source))
        }
        .width('100%')
        .borderRadius(AppTheme.cardRadius)
        .backgroundColor(AppTheme.cardBackground)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private infoSectionTitle(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppTheme.primaryText)
      .width('100%')
      .padding({ left: 2 })
  }

  @Builder
  private notesSection() {
    Column({ space: 8 }) {
      Text(L.text('detail.notes'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.primaryText)
        .padding({ left: 2 })

      Row({ space: 12 }) {
        Image($r('app.media.form_note'))
          .width(36)
          .height(36)
          .padding(9)
          .borderRadius(18)
          .backgroundColor(AppTheme.brandSoft)

        Text(this.event.notes ?? '')
          .fontSize(13)
          .fontColor(AppTheme.secondaryText)
          .layoutWeight(1)
      }
        .width('100%')
        .padding(14)
        .borderRadius(AppTheme.cardRadius)
        .backgroundColor(AppTheme.cardBackground)
    }
    .width('100%')
  }

  @Builder
  private actionsSection() {
    Column() {
      this.actionRow(
        L.text('action.delete'),
        '×',
        AppTheme.danger,
        () => {
        this.showDeleteDialog();
        },
      )
    }
    .width('100%')
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
  }

  @Builder
  private infoRow(
    label: string,
    value: string,
    allowsMultipleLines: boolean = false,
  ) {
    Row({ space: 12 }) {
      this.infoIconView(label)

      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.primaryText)
        .maxLines(1)

      Blank()

      Text(value)
        .fontSize(13)
        .fontColor(AppTheme.secondaryText)
        .textAlign(TextAlign.End)
        .width(allowsMultipleLines ? 166 : 140)
        .maxLines(allowsMultipleLines ? 2 : 1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(allowsMultipleLines ? 66 : 56)
    .padding({ left: 14, right: 14 })
  }

  @Builder
  private infoIconView(label: string) {
    if (label === L.text('detail.category')) {
      Text(EventPresentation.categorySymbol(this.event.category))
        .fontSize(21)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(this.categorySoftColor())
    } else {
      Image(this.infoIcon(label))
        .width(36)
        .height(36)
        .padding(9)
        .borderRadius(18)
        .backgroundColor(AppTheme.brandSoft)
    }
  }

  private infoIcon(label: string): Resource {
    if (label === L.text('detail.reminder')) {
      return $r('app.media.form_bell');
    }
    if (label === L.text('detail.original_date') ||
      label === L.text('detail.next_date') ||
      label === L.text('detail.calendar')) {
      return $r('app.media.form_calendar');
    }
    return $r('app.media.form_sync_calendar');
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

  @Builder
  private actionRow(title: string, symbol: string, tint: ResourceColor, action: () => void) {
    Row({ space: 12 }) {
      Text('\u00D7')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isMutating ? AppTheme.disabledText : tint)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(AppTheme.dangerSoft)

      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isMutating ? AppTheme.disabledText : tint)

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 14, right: 14 })
    .onClick(action)
  }

  @Builder
  private divider() {
    Row()
      .height(1)
      .width('100%')
      .backgroundColor(AppTheme.separator)
  }

  private async loadEvent(): Promise<void> {
    const eventID = this.resolvedEventID();
    const revision = ++this.loadRevision;

    if (eventID === undefined) {
      if (!this.hasEvent) {
        this.hasEvent = false;
      }
      return;
    }

    await this.viewModel.load();

    if (revision !== this.loadRevision) {
      return;
    }

    const matched = this.viewModel.allEvents().find((event: CountdownEvent) => event.id === eventID);

    if (matched === undefined) {
      this.hasEvent = false;
      return;
    }

    if (this.hasEvent && this.event.id !== matched.id) {
      this.resetEasterEggPresentation();
    }
    this.event = matched;
    console.info(`Countdown detail loaded eventID=${matched.id}, title=${matched.title}`);
    this.currentEventID = matched.id;
    this.hasEvent = true;
    this.triggerAutomaticArrivalIfNeeded();
  }
  private showDeleteDialog(): void {
    if (!this.hasEvent || this.isMutating) {
      return;
    }

    AlertDialog.show({
      title: this.event.source === EventSource.ImportedCalendar
        ? L.text('dialog.delete.imported.title')
        : L.text('dialog.delete.title'),
      message: this.deleteDialogMessage(),
      primaryButton: {
        value: L.text('action.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: L.text('action.delete'),
        fontColor: AppTheme.danger,
        action: () => {
          this.performDeleteEvent();
        },
      },
    });
  }

  private async performDeleteEvent(): Promise<void> {
    if (!this.hasEvent || this.isMutating) {
      return;
    }

    this.isMutating = true;
    const deletingEvent = this.event;
    try {
      if (deletingEvent.source === EventSource.ImportedCalendar) {
        await this.viewModel.delete(deletingEvent.id);
      } else if (deletingEvent.source === EventSource.AppCalendar) {
        const didDelete = await CalendarSyncCoordinator.deleteSyncedEvent(deletingEvent);
        if (!didDelete) {
          this.actionError = L.text('error.delete_from_calendar');
          return;
        }
        await this.viewModel.delete(deletingEvent.id);
      } else {
        await this.viewModel.delete(deletingEvent.id);
      }
      router.back();
    } finally {
      this.isMutating = false;
    }
  }

  private deleteDialogMessage(): string {
    if (this.event.source === EventSource.ImportedCalendar) {
      return L.text('dialog.delete.imported.message');
    }

    if (this.event.source === EventSource.AppCalendar) {
      return L.text('dialog.delete.synced.message');
    }

    return L.text('dialog.delete.local.message');
  }

  private nextOccurrenceText(): string {
    if (this.event.dateCalendar === EventDateCalendar.Lunar) {
      const lunarDate = EventPresentation.monthDayText(
        this.event.nextOccurrence,
        EventDateCalendar.Lunar,
      );
      const gregorianDate = EventPresentation.monthDayText(
        this.event.nextOccurrence,
        EventDateCalendar.Gregorian,
      );
      return `${EventPresentation.yearText(this.event.nextOccurrence)} ${L.text('calendar.lunar')} ${lunarDate}\n` +
        gregorianDate;
    }

    return `${EventPresentation.yearText(this.event.nextOccurrence)} ` +
      EventPresentation.displayDate(this.event.nextOccurrence, this.event.dateCalendar);
  }

  private originalDateText(): string {
    if (this.event.dateCalendar === EventDateCalendar.Lunar) {
      const lunarDate = EventPresentation.monthDayText(
        this.event.originalDate,
        EventDateCalendar.Lunar,
      );
      const gregorianDate = EventPresentation.monthDayText(
        this.event.originalDate,
        EventDateCalendar.Gregorian,
      );
      return `${EventPresentation.yearText(this.event.originalDate)} ${L.text('calendar.lunar')} ${lunarDate}\n` +
        gregorianDate;
    }

    const year = EventPresentation.yearText(this.event.originalDate);
    const date = EventPresentation.displayDate(this.event.originalDate, this.event.dateCalendar);
    return `${year} ${date}`;
  }

  private hasNotes(): boolean {
    return this.event.notes !== undefined && this.event.notes.trim().length > 0;
  }

  private specialNumberKey(): string | undefined {
    return EventPresentation.specialNumberKey(
      CountdownCalculator.daysUntil(this.event.nextOccurrence),
      L.isZh(),
    );
  }

  private distantRevealEligible(): boolean {
    return EventPresentation.canRevealDistantCountdown(
      CountdownCalculator.daysUntil(this.event.nextOccurrence),
    );
  }

  private arrivalEligible(): boolean {
    return EventPresentation.canCelebrateArrival(
      CountdownCalculator.daysUntil(this.event.nextOccurrence),
    );
  }

  private countdownInteractionHint(): string {
    if (this.distantRevealEligible()) {
      return L.text('easter_egg.distant.hint');
    }

    if (this.arrivalEligible() && !this.didReplayArrivalManually) {
      return L.text('easter_egg.arrival.replay_hint');
    }

    return '';
  }

  private handleCountdownLongPress(): void {
    if (this.distantRevealEligible()) {
      this.revealDistantCountdown();
      return;
    }

    if (this.arrivalEligible() && !this.didReplayArrivalManually) {
      this.didReplayArrivalManually = true;
      this.startArrivalCelebration();
    }
  }

  private revealDistantCountdown(): void {
    if (this.distantRevealTimer >= 0) {
      clearTimeout(this.distantRevealTimer);
    }
    if (this.distantConvergenceTimer >= 0) {
      clearTimeout(this.distantConvergenceTimer);
    }

    this.areDistantStarsConverged = false;
    this.isDistantCountdownRevealed = true;
    if (this.reduceMotionEnabled) {
      this.areDistantStarsConverged = true;
    } else {
      this.distantConvergenceTimer = setTimeout(() => {
        this.getUIContext().animateTo({ duration: 1750, curve: Curve.EaseInOut }, () => {
          this.areDistantStarsConverged = true;
        });
        this.distantConvergenceTimer = -1;
      }, 30);
    }
    this.distantRevealTimer = setTimeout(() => {
      this.dismissDistantReveal();
    }, 4600);
  }

  private dismissDistantReveal(): void {
    if (this.distantRevealTimer >= 0) {
      clearTimeout(this.distantRevealTimer);
      this.distantRevealTimer = -1;
    }
    if (this.distantConvergenceTimer >= 0) {
      clearTimeout(this.distantConvergenceTimer);
      this.distantConvergenceTimer = -1;
    }

    if (this.reduceMotionEnabled) {
      this.isDistantCountdownRevealed = false;
    } else {
      this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseIn }, () => {
        this.isDistantCountdownRevealed = false;
      });
    }
    this.areDistantStarsConverged = false;
  }

  private triggerAutomaticArrivalIfNeeded(now: Date = new Date()): void {
    if (!this.arrivalEligible()) {
      return;
    }

    const token = EventPresentation.arrivalDayToken(this.event.id, now);
    const rawTokens = AppStorage.get<string>('arrivalCelebrationTokens') ?? '';
    const tokens = rawTokens.length > 0 ? rawTokens.split('\n') : [];
    if (tokens.includes(token)) {
      return;
    }

    tokens.push(token);
    AppStorage.setOrCreate('arrivalCelebrationTokens', tokens.slice(-100).join('\n'));
    this.startArrivalCelebration();
  }

  private startArrivalCelebration(): void {
    if (this.arrivalCelebrationTimer >= 0) {
      clearTimeout(this.arrivalCelebrationTimer);
    }

    if (this.reduceMotionEnabled) {
      this.isArrivalCelebrating = true;
    } else {
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
        this.isArrivalCelebrating = true;
      });
    }
    this.arrivalCelebrationTimer = setTimeout(() => {
      if (this.reduceMotionEnabled) {
        this.isArrivalCelebrating = false;
      } else {
        this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseIn }, () => {
          this.isArrivalCelebrating = false;
        });
      }
      this.arrivalCelebrationTimer = -1;
    }, 2600);
  }

  private arrivalSymbol(): string {
    switch (this.event.category) {
      case EventCategory.Birthday:
        return '';
      case EventCategory.Anniversary:
        return '♥';
      case EventCategory.Custom:
        return '✦';
    }
  }

  private resetEasterEggPresentation(): void {
    if (this.distantRevealTimer >= 0) {
      clearTimeout(this.distantRevealTimer);
      this.distantRevealTimer = -1;
    }
    if (this.distantConvergenceTimer >= 0) {
      clearTimeout(this.distantConvergenceTimer);
      this.distantConvergenceTimer = -1;
    }
    if (this.arrivalCelebrationTimer >= 0) {
      clearTimeout(this.arrivalCelebrationTimer);
      this.arrivalCelebrationTimer = -1;
    }
    this.isDistantCountdownRevealed = false;
    this.areDistantStarsConverged = false;
    this.isArrivalCelebrating = false;
    this.didReplayArrivalManually = false;
  }

  private distantStarX(index: number): string {
    if (this.areDistantStarsConverged) {
      return `${44 + (index * 7) % 13}%`;
    }

    return `${3 + (index * 37) % 94}%`;
  }

  private distantStarY(index: number): string {
    if (this.areDistantStarsConverged) {
      return `${43 + (index * 5) % 15}%`;
    }

    return `${4 + (index * 53) % 92}%`;
  }

  private distantStarSymbol(index: number): string {
    switch (index % 3) {
      case 0:
        return '✦';
      case 1:
        return '★';
      default:
        return '·';
    }
  }

  private distantStarColor(index: number): string {
    switch (index % 3) {
      case 0:
        return '#A3DED1';
      case 1:
        return '#B8C9EA';
      default:
        return '#EACFA9';
    }
  }

  private refreshReduceMotionPreference(): void {
    try {
      this.reduceMotionEnabled = accessibility.isAnimationReduceEnabledSync();
    } catch (error) {
      this.reduceMotionEnabled = false;
    }
  }

  private routeEventID(): string | undefined {
    const params = router.getParams() as EventRouteParams;
    return params?.eventID;
  }

  private resolvedEventID(): string | undefined {
    const activeCardID = AppStorage.get<string>('activeCardEventID') ?? '';
    if (activeCardID.length > 0) {
      AppStorage.setOrCreate('activeCardEventID', '');
      this.currentEventID = activeCardID;
      return activeCardID;
    }

    // Once a detail has been selected (including a newer card click), never
    // allow the original router params to overwrite it on another lifecycle call.
    if (this.currentEventID.length > 0) {
      return this.currentEventID;
    }

    const routeID = this.routeEventID();

    if (routeID !== undefined && routeID.length > 0) {
      this.currentEventID = routeID;
      return routeID;
    }

    if (this.hasEvent) {
      return this.event.id;
    }

    return undefined;
  }

}
