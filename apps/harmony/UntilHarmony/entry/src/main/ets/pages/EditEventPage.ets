import { promptAction, router } from '@kit.ArkUI';
import { CalendarSyncCoordinator } from '../calendar/CalendarSyncCoordinator';
import { EventFormView } from '../components/EventFormView';
import { CountdownEvent, EventSource, ReminderLeadTime } from '../model/CountdownEvent';
import { AppEventStore } from '../repository/AppEventStore';
import { AppTheme } from '../utils/AppTheme';
import { L } from '../utils/LocalizedText';
import {
  EventFormState,
  EventFormViewModel,
} from '../viewmodel/EventFormViewModel';
import { EventListViewModel } from '../viewmodel/EventListViewModel';
import { ReminderService } from '../services/ReminderService';

interface EventRouteParams {
  eventID?: string;
}

@Entry
@Component
struct EditEventPage {
  private viewModel: EventListViewModel = new EventListViewModel(AppEventStore.shared());
  private editingEvent: CountdownEvent | undefined = undefined;

  @State private formState: EventFormState = EventFormViewModel.emptyState();
  @State private validationMessage: string = '';
  @State private isSaving: boolean = false;
  private initialFormSignature: string = '';

  aboutToAppear(): void {
    this.loadEvent();
  }

  onBackPress(): boolean {
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
    Column() {
      this.navigationBar()

      Scroll() {
        Column({ space: 18 }) {
          EventFormView({ state: $formState, validationMessage: $validationMessage })
        }
        .width('100%')
        .padding({ left: AppTheme.pagePadding, right: AppTheme.pagePadding, bottom: 28 })
      }
      .layoutWeight(1)

      this.primarySaveButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.pageBackground)
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
        Text(L.text('edit.title'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.primaryText)
    }
    .width('100%')
    .height(80)
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
          .height(56)
          .borderRadius(20)
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

  private async loadEvent(): Promise<void> {
    const eventID = this.routeEventID();

    if (eventID === undefined) {
      this.validationMessage = L.text('detail.not_found');
      return;
    }

    await this.viewModel.load();
    const matched = this.viewModel.allEvents().find((event: CountdownEvent) => event.id === eventID);

    if (matched === undefined) {
      this.validationMessage = L.text('detail.not_found');
      return;
    }

    this.editingEvent = matched;
    this.formState = EventFormViewModel.stateFromEvent(matched);
    this.initialFormSignature = this.formSignature(this.formState);
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

    if (this.editingEvent === undefined) {
      this.showValidationError(L.text('detail.not_found'));
      return;
    }

    const event = EventFormViewModel.buildEvent(this.formState, this.editingEvent);

    if (event === undefined) {
      this.showValidationError(L.text('validation.form.invalid'));
      return;
    }

    this.isSaving = true;
    const previousEvent = this.editingEvent;
    const locallySavedEvent = this.pendingCalendarState(event, previousEvent);

    try {
      await this.viewModel.update(locallySavedEvent, false);
    } catch (error) {
      this.isSaving = false;
      this.validationMessage = error instanceof Error ? error.message : L.text('validation.calendar.sync_failed');
      promptAction.showToast({ message: this.validationMessage });
      return;
    }

    const didSync = await this.syncCalendarAfterSave(event, previousEvent);
    const didChooseReminder = event.reminderLeadTime !== ReminderLeadTime.None &&
      event.reminderLeadTime !== previousEvent.reminderLeadTime;
    if (didChooseReminder) {
      await ReminderService.ensureAuthorizationAndReschedule(this.viewModel.allEvents());
    } else {
      await ReminderService.reschedule(this.viewModel.allEvents());
    }
    this.isSaving = false;
    this.validationMessage = '';
    promptAction.showToast({
      message: didSync ? L.text('validation.saved') : L.text('validation.saved_calendar_failed'),
    });
    this.returnHome();
  }

  private routeEventID(): string | undefined {
    const params = router.getParams() as EventRouteParams;
    return params?.eventID;
  }

  private returnHome(): void {
    router.back({ url: 'pages/Index' });
  }

  private showValidationError(message: string): void {
    this.validationMessage = message;
    promptAction.showToast({ message });
  }

  private async syncCalendarAfterSave(event: CountdownEvent, previousEvent: CountdownEvent): Promise<boolean> {
    try {
      const syncedEvent = await CalendarSyncCoordinator.sync(event, previousEvent);
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
      console.error(`Failed to sync edited event to calendar: ${JSON.stringify(error)}`);
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
    return this.initialFormSignature.length > 0 &&
      this.formSignature(this.formState) !== this.initialFormSignature;
  }

  private formSignature(state: EventFormState): string {
    return `${state.title}|${state.category}|${state.dateCalendar}|${state.dateText}|${state.notes}|` +
      `${state.hasConfirmedDate}|${state.reminderLeadTime}|${state.shouldSyncToCalendar}`;
  }

  private pendingCalendarState(event: CountdownEvent, previousEvent: CountdownEvent): CountdownEvent {
    const keepsManagedCalendarLink = previousEvent.source === EventSource.AppCalendar &&
      previousEvent.calendarEventID !== undefined;
    return {
      id: event.id,
      title: event.title,
      nextOccurrence: event.nextOccurrence,
      originalDate: event.originalDate,
      category: event.category,
      dateCalendar: event.dateCalendar,
      source: keepsManagedCalendarLink ? EventSource.AppCalendar : EventSource.Local,
      isIgnored: event.isIgnored ?? false,
      calendarEventID: keepsManagedCalendarLink ? previousEvent.calendarEventID : undefined,
      calendarItemID: undefined,
      notes: event.notes,
      reminderLeadTime: event.reminderLeadTime,
    };
  }
}
