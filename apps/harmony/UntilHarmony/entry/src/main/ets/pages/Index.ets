import { accessibility } from '@kit.AccessibilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { CountdownEvent, EventCategory, EventSource, ReminderLeadTime } from '../model/CountdownEvent';
import { AppEventStore } from '../repository/AppEventStore';
import { AppUserJourneyStore } from '../repository/AppUserJourneyStore';
import { EventListViewModel, EventCategoryFilter } from '../viewmodel/EventListViewModel';
import { EventRowView } from '../components/EventRowView';
import { AppTheme } from '../utils/AppTheme';
import { L } from '../utils/LocalizedText';
import { CountdownCalculator } from '../services/CountdownCalculator';
import { CalendarSyncCoordinator } from '../calendar/CalendarSyncCoordinator';
import { EventPresentation } from '../utils/EventPresentation';
import { ActivationService, ActivationState } from '../services/ActivationService';
import { CardInstallService } from '../services/CardInstallService';
import { ReminderService } from '../services/ReminderService';

@Entry
@Component
struct Index {
  private viewModel: EventListViewModel = new EventListViewModel(AppEventStore.shared());

  @State private events: CountdownEvent[] = [];
  @State private todayEvents: CountdownEvent[] = [];
  @State private upcomingEvents: CountdownEvent[] = [];
  @State private todayEventCount: number = 0;
  @State private upcomingEventCount: number = 0;
  @State private searchText: string = '';
  @State private selectedFilter: EventCategoryFilter = EventCategoryFilter.All;
  @State private isRefreshing: boolean = false;
  @State private hasAnyStoredEvents: boolean = false;
  @State private shouldShowActivationCard: boolean = false;
  @State private cardCount: number = 0;
  @State private listOffsetX: number = 0;
  @State private listOpacity: number = 1;
  @State private shouldShowNightLetter: boolean = false;
  private isPageVisible: boolean = false;
  @StorageLink('countdownEventsRevision') @Watch('handleEventsRevisionChanged')
  private countdownEventsRevision: number = 0;

  onPageShow(): void {
    this.isPageVisible = true;
    this.refreshEvents();
    this.handlePendingCardRoute();
  }

  onPageHide(): void {
    this.isPageVisible = false;
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Column() {
        this.header()
        if (this.hasAnyStoredEvents) {
          this.searchBar()
          this.filterBar()
          if (this.cardCount === 0) {
            this.cardCenterEntry()
          }
        }
        this.refreshStatus()
        Stack() {
          this.eventList()
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)
        .translate({ x: this.listOffsetX })
        .opacity(this.listOpacity)
        .gesture(
          SwipeGesture({ direction: SwipeDirection.Horizontal, speed: 180 })
            .onAction((event: GestureEvent) => {
              this.switchFilterBySwipe(event.angle);
            })
        )
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, top: 12 })
      .backgroundColor(AppTheme.pageBackground)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.pageBackground)
    .pullToRefresh(this.hasAnyStoredEvents)
    .onRefreshing(() => {
      this.manualRefresh();
    })
  }

  @Builder
  private refreshStatus() {
    if (this.isRefreshing) {
      Row({ space: 8 }) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(AppTheme.brand)
        Text(L.text('calendar_refresh.syncing'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
      }
      .width('100%')
      .height(30)
      .justifyContent(FlexAlign.Center)
      .accessibilityText(L.text('calendar_refresh.syncing'))
    }
  }

  @Builder
  private header() {
    Row() {
      Column() {
        Text(L.text('app.title'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (this.hasAnyStoredEvents) {
        if (this.cardCount > 0) {
          Button({ type: ButtonType.Normal }) {
            Image($r('app.media.ui_cards'))
              .width(21)
              .height(21)
              .fillColor(AppTheme.brand)
          }
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor(AppTheme.brandSoft)
          .margin({ right: 10 })
          .accessibilityText(`${L.text('card.center.home_title')}，${L.installedCardCount(this.cardCount)}`)
          .onClick(() => {
            router.pushUrl({ url: 'pages/CardCenterPage' });
          })
        }
        Button({ type: ButtonType.Normal }) {
            Image($r('app.media.ui_add'))
              .fillColor(Color.White)
              .width(22)
              .height(22)
          }
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor(AppTheme.brand)
          .accessibilityText(L.text('event.add_day'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/AddEventPage' });
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 14 })
  }

  @Builder
  private searchBar() {
    TextInput({ placeholder: L.text('search.events'), text: this.searchText })
      .height(44)
      .fontSize(14)
      .fontColor(AppTheme.primaryText)
      .placeholderColor(AppTheme.tertiaryText)
      .placeholderFont({
        size: 15,
        weight: FontWeight.Regular,
      })
      .backgroundColor(AppTheme.pageBackground)
      .borderRadius(0)
      .border({ width: { bottom: 1 }, color: AppTheme.separator })
      .padding({ left: 2, right: 2 })
      .onChange((value: string) => {
        this.searchText = value;
        this.viewModel.setSearchQuery(value);
        this.applyVisibleEvents();
      })
      .accessibilityText(L.text('search.events'))
      .margin({ bottom: 14 })
  }

  @Builder
  private filterBar() {
    Row({ space: 4 }) {
      this.filterButton(L.text('filter.all'), EventCategoryFilter.All)
      this.filterButton(L.categoryLabel(EventCategory.Birthday), EventCategoryFilter.Birthday)
      this.filterButton(L.categoryLabel(EventCategory.Anniversary), EventCategoryFilter.Anniversary)
      this.filterButton(L.categoryLabel(EventCategory.Custom), EventCategoryFilter.Custom)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .borderRadius(12)
    .backgroundColor(Color.Transparent)
    .margin({ bottom: 8 })
  }

  @Builder
  private cardCenterEntry() {
    Row({ space: 12 }) {
      Image($r('app.media.ui_cards'))
        .fillColor(AppTheme.brand)
        .padding(10)
        .width(42)
        .height(42)
      .borderRadius(14)
      .backgroundColor(AppTheme.brandSoft)

      Column({ space: 2 }) {
        Text(L.text('card.center.home_title'))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
        Text(this.cardCount > 0 ? L.installedCardCount(this.cardCount) : L.text('card.center.home_add'))
          .fontSize(12)
          .fontColor(this.cardCount > 0 ? AppTheme.secondaryText : AppTheme.brand)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ui_chevron'))
        .width(18).height(18).fillColor(AppTheme.tertiaryText)
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
    .margin({ bottom: 12 })
    .accessibilityText(this.cardCount > 0
      ? `${L.text('card.center.home_title')}，${L.installedCardCount(this.cardCount)}`
      : `${L.text('card.center.home_title')}，${L.text('card.center.home_add')}`)
    .onClick(() => {
      router.pushUrl({ url: 'pages/CardCenterPage' });
    })
  }

  @Builder
  private filterButton(title: string, filter: EventCategoryFilter) {
    Button(title, { type: ButtonType.Normal })
      .fontSize(13)
      .fontWeight(this.selectedFilter === filter ? FontWeight.Bold : FontWeight.Medium)
      .constraintSize({ minHeight: 44 })
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
      .fontColor(this.selectedFilter === filter ? AppTheme.brand : AppTheme.secondaryText)
      .borderRadius(0)
      .border({ width: { bottom: this.selectedFilter === filter ? 2 : 0 }, color: AppTheme.brand })
      .onClick(() => {
        this.selectFilter(filter);
      })
      .accessibilityText(title)
  }

  @Builder
  private eventList() {
    if (this.events.length === 0) {
      if (this.hasAnyStoredEvents) {
        Column({ space: 8 }) {
          Image($r('app.media.ui_search'))
            .width(40).height(40).fillColor(AppTheme.secondaryText)
          Text(L.text('empty.no_matching.title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
          Text(L.text('empty.no_matching.description'))
            .fontSize(14)
            .fontColor(AppTheme.secondaryText)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        this.emptyActivationView()
      }
    } else {
      List({ space: 0 }) {
        if (this.shouldShowActivationCard) {
          ListItem() {
            this.activationTaskCard()
          }
        }

        ListItem() {
          this.featuredEventCard(this.events[0])
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/EventDetailPage', params: { eventID: this.events[0].id } });
        })

        if (this.todayEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id).length > 0) {
          ListItem() {
            this.sectionHeader(L.text('today.section.title'), true)
          }

          ForEach(this.todayEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id), (event: CountdownEvent) => {
            ListItem() {
              EventRowView({ event: event, compact: true })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/EventDetailPage', params: { eventID: event.id } });
            })
            .onMouse((mouseEvent: MouseEvent) => {
              if (mouseEvent.button === MouseButton.Right && mouseEvent.action === MouseAction.Press) {
                this.showDeleteEventDialog(event);
              }
            })
            .gesture(
              LongPressGesture({ repeat: false, duration: 500 })
                .onAction(() => {
                  this.showDeleteEventDialog(event);
                })
            )
          }, (event: CountdownEvent) => this.eventRowKey(event))
        }

        if (this.upcomingEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id).length > 0) {
          ListItem() {
            this.sectionHeader(L.text('today.section.upcoming'), false)
          }

          ForEach(this.upcomingEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id), (event: CountdownEvent) => {
            ListItem() {
              EventRowView({ event: event, compact: true })
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/EventDetailPage', params: { eventID: event.id } });
            })
            .onMouse((mouseEvent: MouseEvent) => {
              if (mouseEvent.button === MouseButton.Right && mouseEvent.action === MouseAction.Press) {
                this.showDeleteEventDialog(event);
              }
            })
            .gesture(
              LongPressGesture({ repeat: false, duration: 500 })
                .onAction(() => {
                  this.showDeleteEventDialog(event);
                })
            )
          }, (event: CountdownEvent) => this.eventRowKey(event))
        }

        if (this.shouldShowNightLetter) {
          ListItem() {
            Row({ space: 8 }) {
              Text('🌙')
                .fontSize(14)
              Text(L.text('easter_egg.night_letter'))
                .fontSize(12)
                .fontColor(AppTheme.secondaryText)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ left: 18, right: 18, top: 18, bottom: 24 })
            .accessibilityText(L.text('easter_egg.night_letter'))
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.pageBackground)
    }
  }

  @Builder
  private featuredEventCard(event: CountdownEvent) {
    Column({ space: 18 }) {
      Row({ space: 7 }) {
        Image(EventPresentation.categoryIcon(event.category))
          .width(16).height(16).fillColor(EventPresentation.categoryColor(event.category))
        Text(EventPresentation.categoryLabel(event.category))
          .fontSize(12).fontWeight(FontWeight.Bold)
          .fontColor(EventPresentation.categoryColor(event.category))
        Blank()
        Text(L.text('today.section.upcoming'))
          .fontSize(12).fontColor(AppTheme.secondaryText)
      }
      .width('100%')

      Row() {
        Column({ space: 8 }) {
          Text(event.title)
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(AppTheme.primaryText)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(EventPresentation.compactDate(event.nextOccurrence, event.dateCalendar))
            .fontSize(13).fontColor(AppTheme.secondaryText)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Column({ space: 0 }) {
          Text(EventPresentation.countdownBadgeText(event))
            .fontSize(46).fontWeight(FontWeight.Bold)
            .fontColor(EventPresentation.categoryColor(event.category))
          if (EventPresentation.shouldShowCountdownUnit(event)) {
            Text(L.text('countdown.day.unit'))
              .fontSize(12).fontColor(EventPresentation.categoryColor(event.category))
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 20 })
    .margin({ bottom: 14 })
    .borderRadius(22)
    .backgroundColor(EventPresentation.categoryBackground(event.category))
    .accessibilityGroup(true)
    .accessibilityText(EventPresentation.accessibilityLabel(event))
  }

  @Builder
  private emptyActivationView() {
    Column({ space: 14 }) {
      Text(L.text('empty.activation.title'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.primaryText)
        .textAlign(TextAlign.Center)

      Text(L.text('empty.activation.description'))
        .fontSize(14)
        .fontColor(AppTheme.secondaryText)
        .textAlign(TextAlign.Center)

      Column({ space: 10 }) {
        this.quickAddButton(L.text('empty.activation.birthday'), EventCategory.Birthday)
        this.quickAddButton(L.text('empty.activation.anniversary'), EventCategory.Anniversary)
        this.quickAddButton(L.text('empty.activation.custom'), EventCategory.Custom)
      }
      .width('100%')

      Row({ space: 8 }) {
        Image($r('app.media.ui_cards'))
          .width(20).height(20).fillColor(AppTheme.brand)
        Text(L.text('empty.activation.card_hint'))
          .fontSize(12)
          .fontColor(AppTheme.secondaryText)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(14)
      .borderRadius(14)
      .backgroundColor(AppTheme.brandSoft)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 8, right: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private quickAddButton(title: string, category: EventCategory) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Image(EventPresentation.categoryIcon(category))
          .width(40)
          .height(40)
          .padding(9)
          .fillColor(EventPresentation.categoryColor(category))
          .borderRadius(12)
          .backgroundColor(EventPresentation.categoryBackground(category))
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.primaryText)
        Blank()
        Image($r('app.media.ui_chevron'))
          .width(18).height(18).fillColor(AppTheme.tertiaryText)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .borderRadius(16)
    .backgroundColor(AppTheme.materialBackground)
    .onClick(() => {
      router.pushUrl({ url: 'pages/AddEventPage', params: { category } });
    })
  }

  @Builder
  private activationTaskCard() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 3 }) {
          Text(L.text('activation.card.title'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
          Text(L.text('activation.card.description'))
            .fontSize(12)
            .fontColor(AppTheme.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button({ type: ButtonType.Normal }) {
          Image($r('app.media.ui_close')).width(20).height(20).fillColor(AppTheme.secondaryText)
        }
          .accessibilityText(L.text('action.close'))
          .width(AppTheme.minimumTouchSize)
          .height(AppTheme.minimumTouchSize)
          .borderRadius(17)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.dismissActivationCard();
          })
      }
      .width('100%')

      Button(L.text('activation.enable_any_reminder'))
        .width('100%')
        .constraintSize({ minHeight: AppTheme.minimumTouchSize })
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor(AppTheme.brand)
        .borderRadius(13)
        .onClick(() => {
          this.enableReminderForNearestEvent();
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(AppTheme.brandSoft)
  }

  @Builder
  private sectionHeader(title: string, isToday: boolean) {
    Row({ space: 8 }) {
      Row()
        .width(7)
        .height(7)
        .borderRadius(4)
        .backgroundColor(isToday ? AppTheme.danger : AppTheme.brand)

      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.secondaryText)

      Blank()

      Text(L.count(isToday
        ? this.todayEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id).length
        : this.upcomingEvents.filter((event: CountdownEvent) => event.id !== this.events[0].id).length))
        .fontSize(12)
        .fontColor(AppTheme.tertiaryText)
    }
    .width('100%')
    .padding({ left: 3, right: 3, top: 10, bottom: 4 })
  }

  private async refreshEvents(): Promise<void> {
    this.viewModel = new EventListViewModel(AppEventStore.shared());
    this.viewModel.setSearchQuery(this.searchText);
    this.viewModel.setCategoryFilter(this.selectedFilter);
    this.events = await this.viewModel.load();
    this.hasAnyStoredEvents = this.viewModel.allEvents().length > 0;
    this.applyVisibleEvents();
    await this.refreshActivationState();
  }

  private async refreshActivationState(): Promise<void> {
    const allEvents = this.viewModel.allEvents();
    const hasPermission = await ReminderService.isAuthorized();
    const cards = await CardInstallService.reconcileCardInstances();
    const cardCount = cards.length;
    this.cardCount = cardCount;
    const activation = new ActivationService(AppUserJourneyStore.shared());
    this.shouldShowActivationCard = activation.state(
      allEvents,
      hasPermission,
      cardCount,
    ) === ActivationState.EventOnly;
  }

  private async enableReminderForNearestEvent(): Promise<void> {
    const nearestEvent = this.viewModel.allEvents()[0];
    if (nearestEvent === undefined) {
      return;
    }

    const recommendedLeadTime = nearestEvent.reminderLeadTime === ReminderLeadTime.None
      ? ReminderLeadTime.OneDay
      : nearestEvent.reminderLeadTime;
    await this.viewModel.update(this.withReminder(nearestEvent, recommendedLeadTime), false);
    const isAuthorized = await ReminderService.ensureAuthorizationAndReschedule(this.viewModel.allEvents());
    if (!isAuthorized) {
      promptAction.showToast({ message: L.text('activation.reminder_permission_denied') });
    } else {
      promptAction.showToast({ message: L.text('activation.reminder_enabled') });
    }
    await this.refreshEvents();
  }

  private dismissActivationCard(): void {
    new ActivationService(AppUserJourneyStore.shared()).dismissActivationCard();
    this.shouldShowActivationCard = false;
  }

  private withReminder(event: CountdownEvent, reminderLeadTime: ReminderLeadTime): CountdownEvent {
    return {
      id: event.id,
      title: event.title,
      nextOccurrence: event.nextOccurrence,
      originalDate: event.originalDate,
      category: event.category,
      dateCalendar: event.dateCalendar,
      recurrence: event.recurrence,
      source: event.source,
      isIgnored: event.isIgnored ?? false,
      calendarEventID: event.calendarEventID,
      calendarItemID: event.calendarItemID,
      notes: event.notes,
      reminderLeadTime,
    };
  }

  private handleEventsRevisionChanged(): void {
    if (this.isPageVisible) {
      this.refreshEvents();
    }
  }

  private async manualRefresh(): Promise<void> {
    this.isRefreshing = true;
    try {
      await this.refreshEvents();
      promptAction.showToast({ message: L.text('calendar_refresh.completed') });
    } catch (error) {
      console.error(`Failed to refresh countdown events: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: L.text('calendar_refresh.failed') });
    } finally {
      this.isRefreshing = false;
    }
  }

  private applyVisibleEvents(): void {
    const referenceDate = new Date();
    const visibleEvents = this.viewModel.visibleEvents();
    this.events = visibleEvents;
    this.todayEvents = visibleEvents
      .filter((event: CountdownEvent) => CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate) === 0);
    this.upcomingEvents = visibleEvents
      .filter((event: CountdownEvent) => CountdownCalculator.daysUntil(event.nextOccurrence, referenceDate) !== 0);
    this.todayEventCount = this.todayEvents.length;
    this.upcomingEventCount = this.upcomingEvents.length;
    this.evaluateNightLetter(referenceDate);
  }

  private evaluateNightLetter(now: Date): void {
    if (this.shouldShowNightLetter) {
      return;
    }

    const lastShownAt = AppStorage.get<number>('lastNightLetterShownAt') ?? 0;
    if (!EventPresentation.shouldShowNightLetter(now, lastShownAt, this.events.length > 0)) {
      return;
    }

    this.shouldShowNightLetter = true;
    AppStorage.setOrCreate('lastNightLetterShownAt', now.getTime());
  }

  private handlePendingCardRoute(): void {
    const target = AppStorage.get<string>('pendingCardRoute') ?? '';
    const eventID = AppStorage.get<string>('pendingCardEventID') ?? '';
    const formID = AppStorage.get<string>('pendingCardFormID') ?? '';

    if (target.length === 0) {
      return;
    }

    AppStorage.setOrCreate('pendingCardRoute', '');
    AppStorage.setOrCreate('pendingCardEventID', '');
    AppStorage.setOrCreate('pendingCardFormID', '');

    setTimeout(() => {
      if (target === 'add') {
        router.pushUrl({ url: 'pages/AddEventPage' });
        return;
      }

      if (target === 'event' && eventID.length > 0) {
        router.pushUrl({ url: 'pages/EventDetailPage', params: { eventID } });
        return;
      }

      if (target === 'configuration' && formID.length > 0) {
        router.pushUrl({ url: 'pages/CardCenterPage', params: { formId: formID } });
      }
    }, 0);
  }

  private eventRowKey(event: CountdownEvent): string {
    return `${event.id}-${event.title}-${event.category}-${event.dateCalendar}-` +
      `${event.nextOccurrence.getTime()}-${event.originalDate.getTime()}-${event.source}`;
  }

  private showDeleteEventDialog(event: CountdownEvent): void {
    AlertDialog.show({
      title: event.source === EventSource.ImportedCalendar
        ? L.text('dialog.delete.imported.title')
        : L.text('dialog.delete.title'),
      message: this.deleteDialogMessage(event),
      primaryButton: {
        value: L.text('action.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: L.text('action.delete'),
        fontColor: AppTheme.danger,
        action: () => {
          this.deleteEventFromList(event);
        },
      },
    });
  }

  private async deleteEventFromList(event: CountdownEvent): Promise<void> {
    if (event.source === EventSource.ImportedCalendar) {
      await this.viewModel.delete(event.id);
    } else if (event.source === EventSource.AppCalendar) {
      const didDelete = await CalendarSyncCoordinator.deleteSyncedEvent(event);
      if (!didDelete) {
        promptAction.showToast({ message: L.text('error.delete_from_calendar') });
        return;
      }
      await this.viewModel.delete(event.id);
    } else {
      await this.viewModel.delete(event.id);
    }
    this.hasAnyStoredEvents = this.viewModel.allEvents().length > 0;
    this.applyVisibleEvents();
  }

  private deleteDialogMessage(event: CountdownEvent): string {
    if (event.source === EventSource.ImportedCalendar) {
      return L.text('dialog.delete.imported.message');
    }

    if (event.source === EventSource.AppCalendar) {
      return L.text('dialog.delete.synced.message');
    }

    return L.text('dialog.delete.local.message');
  }

  private switchFilterBySwipe(angle: number): void {
    const normalizedAngle = ((angle % 360) + 360) % 360;

    if (normalizedAngle <= 45 || normalizedAngle >= 315) {
      this.switchFilter(-1);
      return;
    }

    if (normalizedAngle >= 135 && normalizedAngle <= 225) {
      this.switchFilter(1);
    }
  }

  private switchFilter(step: number): void {
    const filters: EventCategoryFilter[] = [
      EventCategoryFilter.All,
      EventCategoryFilter.Birthday,
      EventCategoryFilter.Anniversary,
      EventCategoryFilter.Custom,
    ];
    const currentIndex = filters.indexOf(this.selectedFilter);
    const nextIndex = (currentIndex + step + filters.length) % filters.length;
    this.selectFilter(filters[nextIndex]);
  }

  private selectFilter(filter: EventCategoryFilter): void {
    if (this.selectedFilter === filter) {
      return;
    }
    const direction = this.filterSwitchDirection(filter);
    this.selectedFilter = filter;
    this.viewModel.setCategoryFilter(filter);
    this.applyVisibleEvents();

    let reduceMotion = true;
    try {
      reduceMotion = accessibility.isAnimationReduceEnabledSync();
    } catch (_) {
      // 无法读取系统偏好时使用无动效降级。
    }
    this.listOffsetX = reduceMotion ? 0 : direction * 16;
    this.listOpacity = 1;
    if (!reduceMotion) {
      this.getUIContext().animateTo({ duration: 160, curve: Curve.EaseOut }, () => {
        this.listOffsetX = 0;
      });
    }
  }

  private filterSwitchDirection(nextFilter: EventCategoryFilter): number {
    const filters: EventCategoryFilter[] = [
      EventCategoryFilter.All,
      EventCategoryFilter.Birthday,
      EventCategoryFilter.Anniversary,
      EventCategoryFilter.Custom,
    ];
    const currentIndex = filters.indexOf(this.selectedFilter);
    const nextIndex = filters.indexOf(nextFilter);

    if (currentIndex < 0 || nextIndex < 0 || currentIndex === nextIndex) {
      return 1;
    }

    const forwardDistance = (nextIndex - currentIndex + filters.length) % filters.length;
    const backwardDistance = (currentIndex - nextIndex + filters.length) % filters.length;
    return forwardDistance <= backwardDistance ? 1 : -1;
  }
}
