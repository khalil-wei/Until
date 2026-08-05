import { promptAction, router } from '@kit.ArkUI';
import { CalendarSyncCoordinator } from '../calendar/CalendarSyncCoordinator';
import { EventFormView } from '../components/EventFormView';
import { CountdownEvent, EventCategory, EventSource, ReminderLeadTime } from '../model/CountdownEvent';
import { AppEventStore } from '../repository/AppEventStore';
import { AppUserJourneyStore } from '../repository/AppUserJourneyStore';
import { ActivationService } from '../services/ActivationService';
import { CardInstallService } from '../services/CardInstallService';
import { ReminderService } from '../services/ReminderService';
import { AppTheme } from '../utils/AppTheme';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';
import {
  EventFormState,
  EventFormViewModel,
} from '../viewmodel/EventFormViewModel';
import { EventListViewModel } from '../viewmodel/EventListViewModel';

interface AddEventRouteParams {
  category?: string;
}

@Entry
@Component
struct AddEventPage {
  private viewModel: EventListViewModel = new EventListViewModel(AppEventStore.shared());

  @State private formState: EventFormState = EventFormViewModel.emptyState();
  @State private validationMessage: string = '';
  @State private isSaving: boolean = false;
  @State private showActivationGuide: boolean = false;
  @State private savedEventTitle: string = '';
  @State private savedCountdownText: string = '';
  private initialFormSignature: string = '';

  aboutToAppear(): void {
    if (this.initialFormSignature.length === 0) {
      const params = router.getParams() as AddEventRouteParams;
      this.formState = EventFormViewModel.emptyState(this.categoryFrom(params?.category));
      this.initialFormSignature = this.formSignature(this.formState);
    }
  }

  onBackPress(): boolean {
    if (this.showActivationGuide) {
      this.deferActivation();
      return true;
    }

    if (this.isSaving) {
      return true;
    }

    if (this.hasUnsavedChanges()) {
      this.showDiscardDialog();
      return true;
    }

    return false;
  }

  build() {
    Stack() {
      Column() {
        this.navigationBar()

        Scroll() {
          Column({ space: 18 }) {
            EventFormView({ state: $formState, validationMessage: $validationMessage })
          }
          .width('100%')
          .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, bottom: 20 })
        }
        .layoutWeight(1)

        this.primarySaveButton()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.pageBackground)

      if (this.showActivationGuide) {
        this.activationGuide()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private activationGuide() {
    Column() {
      Blank()

      Column({ space: 14 }) {
        Text('✅')
          .fontSize(28)
          .width(62)
          .height(62)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppTheme.brandSoft)
          .borderRadius(31)

        Text(L.format('activation.saved_title', this.savedEventTitle))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
          .textAlign(TextAlign.Center)

        Text(L.format('activation.saved_countdown', this.savedCountdownText))
          .fontSize(15)
          .fontColor(AppTheme.secondaryText)
          .textAlign(TextAlign.Center)

        Text(L.text('activation.next_step'))
          .fontSize(14)
          .fontColor(AppTheme.secondaryText)
          .textAlign(TextAlign.Center)

        Button(L.text('activation.add_card'))
          .width('100%')
          .height(AppTheme.primaryActionHeight)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AppTheme.brand)
          .borderRadius(AppTheme.primaryActionRadius)
          .onClick(() => {
            this.openCardManager();
          })

        Button(L.text('activation.later'))
          .fontSize(14)
          .fontColor(AppTheme.secondaryText)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.deferActivation();
          })
      }
      .width('100%')
      .padding(24)
      .borderRadius({ topLeft: 28, topRight: 28 })
      .backgroundColor(AppTheme.cardBackground)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }

  @Builder
  private navigationBar() {
    Row({ space: 14 }) {
        Button('‹')
          .fontSize(30)
          .fontColor(AppTheme.primaryText)
          .width(42)
          .height(42)
          .borderRadius(21)
          .backgroundColor(AppTheme.cardBackground)
          .onClick(() => {
            this.requestClose();
          })
          .accessibilityText(L.text('action.cancel'))

        Column({ space: 2 }) {
          Text(L.text('add.title'))
            .fontSize(AppTheme.navigationTitleSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
          Text(L.text('app.subtitle'))
            .fontSize(12)
            .fontColor(AppTheme.tertiaryText)
        }
        .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(AppTheme.navigationHeight)
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding })
  }

  @Builder
  private primarySaveButton() {
    Row() {
      Button(this.isSaving ? L.text('action.saving') : L.text('action.save'))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .height(AppTheme.primaryActionHeight)
          .borderRadius(AppTheme.primaryActionRadius)
          .backgroundColor(this.isSaving ? AppTheme.disabledText : AppTheme.brand)
          .enabled(!this.isSaving)
          .onClick(() => {
            this.save();
          })
          .accessibilityText(this.isSaving ? L.text('action.saving') : L.text('action.save'))
    }
    .width('100%')
    .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, bottom: 16, top: 10 })
  }

  private async save(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    const validation = EventFormViewModel.validate(this.formState);

    if (!validation.isValid) {
      this.showValidationError(validation.message ?? L.text('validation.form.invalid'));
      return;
    }

    const event = EventFormViewModel.buildEvent(this.formState);

    if (event === undefined) {
      this.showValidationError(L.text('validation.form.invalid'));
      return;
    }

    this.isSaving = true;
    const locallySavedEvent = this.withSyncState(event, EventSource.Local, undefined, undefined);
    let existingCards = CardInstallService.cardInstances();

    try {
      await this.viewModel.load();
      existingCards = await CardInstallService.reconcileCardInstances();
      await this.viewModel.add(locallySavedEvent, false);
    } catch (error) {
      this.isSaving = false;
      this.validationMessage = error instanceof Error ? error.message : L.text('validation.calendar.sync_failed');
      promptAction.showToast({ message: this.validationMessage });
      return;
    }

    let didSyncCalendar = true;
    if (event.source === EventSource.AppCalendar) {
      didSyncCalendar = await this.syncCalendarAfterSave(event);
    }

    let isReminderReady = false;
    if (event.reminderLeadTime !== ReminderLeadTime.None) {
      isReminderReady = await ReminderService.ensureAuthorizationAndReschedule(this.viewModel.allEvents());
    }

    this.isSaving = false;
    this.validationMessage = '';
    const activation = new ActivationService(AppUserJourneyStore.shared());
    const needsFirstSaveGuide = existingCards.length === 0 &&
      activation.shouldShowFirstSaveGuide(this.viewModel.allEvents().length);
    if (needsFirstSaveGuide) {
      activation.markFirstSaveGuideSeen();
      this.savedEventTitle = event.title;
      this.savedCountdownText = EventPresentation.countdownText(event);
      this.showActivationGuide = true;
      if (!didSyncCalendar) {
        promptAction.showToast({ message: L.text('validation.saved_calendar_failed') });
      } else if (event.reminderLeadTime !== ReminderLeadTime.None && !isReminderReady) {
        promptAction.showToast({ message: L.text('activation.saved_reminder_permission_denied') });
      }
      return;
    }

    const toastMessage = !didSyncCalendar
      ? L.text('validation.saved_calendar_failed')
      : event.reminderLeadTime !== ReminderLeadTime.None && !isReminderReady
        ? L.text('activation.saved_reminder_permission_denied')
        : L.text('validation.saved');
    promptAction.showToast({ message: toastMessage });
    this.returnHome();
  }

  private returnHome(): void {
    router.back({ url: 'pages/Index' });
  }

  private showValidationError(message: string): void {
    this.validationMessage = message;
    promptAction.showToast({ message });
  }

  private async syncCalendarAfterSave(event: CountdownEvent): Promise<boolean> {
    try {
      const syncedEvent = await CalendarSyncCoordinator.sync(event);
      await this.viewModel.mergeCalendarSyncResult(
        syncedEvent.id,
        syncedEvent.source,
        syncedEvent.calendarEventID,
        syncedEvent.calendarItemID,
        false,
      );
      if (!this.viewModel.allEvents().some((current: CountdownEvent) => current.id === syncedEvent.id)) {
        return CalendarSyncCoordinator.deleteSyncedEvent(syncedEvent);
      }
      return true;
    } catch (error) {
      console.error(`Failed to sync added event to calendar: ${JSON.stringify(error)}`);
      await this.viewModel.mergeCalendarSyncResult(event.id, EventSource.Local, undefined, undefined, false);
      return false;
    }
  }

  private requestClose(): void {
    if (this.hasUnsavedChanges()) {
      this.showDiscardDialog();
      return;
    }

    router.back();
  }

  private showDiscardDialog(): void {
    AlertDialog.show({
      title: L.text('dialog.discard.title'),
      message: L.text('dialog.discard.message'),
      primaryButton: {
        value: L.text('action.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: L.text('action.discard'),
        fontColor: AppTheme.danger,
        action: () => {
          router.back();
        },
      },
    });
  }

  private hasUnsavedChanges(): boolean {
    return this.formSignature(this.formState) !== this.initialFormSignature;
  }

  private formSignature(state: EventFormState): string {
    return `${state.title}|${state.category}|${state.dateCalendar}|${state.dateText}|${state.notes}|` +
      `${state.hasConfirmedDate}|${state.reminderLeadTime}|${state.shouldSyncToCalendar}`;
  }

  private categoryFrom(rawCategory?: string): EventCategory {
    switch (rawCategory) {
      case EventCategory.Anniversary:
        return EventCategory.Anniversary;
      case EventCategory.Custom:
        return EventCategory.Custom;
      default:
        return EventCategory.Birthday;
    }
  }

  private openCardManager(): void {
    this.showActivationGuide = false;
    router.replaceUrl({ url: 'pages/CardCenterPage' });
  }

  private deferActivation(): void {
    new ActivationService(AppUserJourneyStore.shared()).dismissActivationCard();
    this.returnHome();
  }

  private withSyncState(
    event: CountdownEvent,
    source: EventSource,
    calendarEventID?: string,
    calendarItemID?: string,
  ): CountdownEvent {
    return {
      id: event.id,
      title: event.title,
      nextOccurrence: event.nextOccurrence,
      originalDate: event.originalDate,
      category: event.category,
      dateCalendar: event.dateCalendar,
      source,
      isIgnored: event.isIgnored ?? false,
      calendarEventID,
      calendarItemID,
      notes: event.notes,
      reminderLeadTime: event.reminderLeadTime,
    };
  }
}
