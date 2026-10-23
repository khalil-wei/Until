import {
  EventCategory,
  EventDateCalendar,
  EventRecurrence,
  ReminderLeadTime,
} from '../model/CountdownEvent';
import { LunarCalendar } from '../services/LunarCalendar';
import { AppTheme } from '../utils/AppTheme';
import { EventPresentation } from '../utils/EventPresentation';
import { L } from '../utils/LocalizedText';
import { EventFormState, EventFormViewModel } from '../viewmodel/EventFormViewModel';

@Component
export struct EventFormView {
  @Link state: EventFormState;
  @Link validationMessage: string;
  @State private isDatePickerExpanded: boolean = false;

  build() {
    Column({ space: 28 }) {
      this.basicSection()
      this.dateSection()
      this.recurrenceSection()
      this.reminderSection()
      this.moreSettingsSection()
    }
    .width('100%')
  }

  @Builder
  private basicSection() {
    Column({ space: 16 }) {
      this.sectionEyebrow(L.text('add.section.basic'))
      Row({ space: 12 }) {
        this.titleCategoryIcon()

        TextInput({ placeholder: L.text('add.title.placeholder'), text: this.state.title })
          .height(54)
          .layoutWeight(1)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.primaryText)
          .placeholderColor(AppTheme.tertiaryText)
          .placeholderFont({
            size: 16,
            weight: FontWeight.Regular,
          })
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.setTitle(value);
          })
      }
      .width('100%')
      .height(64)
      .padding({ left: 2, right: 2, top: 4, bottom: 4 })
      .border({ width: { bottom: 1 }, color: AppTheme.separator })

      this.categoryPicker()
    }
  }

  @Builder
  private dateSection() {
    Column({ space: 12 }) {
      this.sectionEyebrow(L.text('add.section.date'))
      Row({ space: 14 }) {
        this.formIcon($r('app.media.ui_calendar'), 28)

        Column({ space: 4 }) {
          Text(L.text('add.date.select'))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.secondaryText)
          Text(this.state.hasConfirmedDate
            ? EventPresentation.compactDate(this.selectedDate(), this.state.dateCalendar)
            : L.text('add.date.unconfirmed'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
            .maxLines(3)
          if (this.state.hasConfirmedDate) {
            Text(this.dateSummaryText())
              .fontSize(12)
              .fontColor(AppTheme.tertiaryText)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('app.media.ui_chevron'))
          .width(18)
          .height(18)
          .fillColor(AppTheme.secondaryText)
          .rotate({ angle: this.isDatePickerExpanded ? -90 : 0 })
      }
      .width('100%')
      .constraintSize({ minHeight: 82 })
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .borderRadius(18)
      .backgroundColor(EventPresentation.categoryBackground(this.state.category))
      .onClick(() => {
        this.isDatePickerExpanded = !this.isDatePickerExpanded;
      })

      if (this.isDatePickerExpanded) {
        if (this.supportsDateCalendar()) {
          this.calendarPicker()
        }
        DatePicker({
          start: new Date(1900, 0, 31),
          end: new Date(2100, 11, 31),
          selected: this.selectedDate(),
        })
          .width('100%')
          .height(168)
          .lunar(this.state.dateCalendar === EventDateCalendar.Lunar)
          .onDateChange((value: Date) => {
            this.setDateText(EventFormViewModel.dateText(value), false);
          })
        Button(L.text('add.date.confirm'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .constraintSize({ minHeight: AppTheme.minimumTouchSize })
          .width('100%')
          .borderRadius(13)
          .backgroundColor(EventPresentation.categoryColor(this.state.category))
          .margin({ left: 14, right: 14, bottom: 14 })
          .onClick(() => {
            this.setDateText(this.state.dateText, true);
            this.isDatePickerExpanded = false;
          })
      }
    }
    .width('100%')
  }

  @Builder
  private recurrenceSection() {
    Column({ space: 12 }) {
      this.sectionEyebrow(L.text('detail.repeat'))
      Row({ space: 8 }) {
        this.recurrenceButton(EventRecurrence.Yearly)
        this.recurrenceButton(EventRecurrence.Monthly)
        this.recurrenceButton(EventRecurrence.Weekly)
      }
      .width('100%')
      Text(L.text('detail.repeat.helper'))
        .fontSize(12)
        .fontColor(AppTheme.secondaryText)
        .width('100%')
    }
  }

  @Builder
  private recurrenceButton(recurrence: EventRecurrence) {
    Button(L.text('detail.repeat.' + recurrence), { type: ButtonType.Normal })
      .fontSize(13)
      .fontWeight(this.state.recurrence === recurrence ? FontWeight.Bold : FontWeight.Medium)
      .constraintSize({ minHeight: AppTheme.minimumTouchSize })
      .layoutWeight(1)
      .backgroundColor(this.state.recurrence === recurrence
        ? EventPresentation.categoryBackground(this.state.category) : AppTheme.materialBackground)
      .fontColor(this.state.recurrence === recurrence
        ? EventPresentation.categoryColor(this.state.category) : AppTheme.secondaryText)
      .borderRadius(10)
      .onClick(() => {
        this.state.recurrence = recurrence;
        this.validationMessage = '';
      })
  }

  @Builder
  private reminderSection() {
    Column({ space: 14 }) {
      this.sectionEyebrow(L.text('add.reminder.section'))
      Row({ space: 12 }) {
        this.formIcon($r('app.media.ui_bell'), 28)
        Column({ space: 3 }) {
          Text(L.reminderLabel(this.state.reminderLeadTime))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          this.reminderButton(ReminderLeadTime.OneDay)
          this.reminderButton(ReminderLeadTime.SameDay)
          this.reminderButton(ReminderLeadTime.None)
        }
        .width('100%')

        Row({ space: 9 }) {
          this.reminderButton(ReminderLeadTime.ThreeDays)
          this.reminderButton(ReminderLeadTime.SevenDays)
        }
        .width('100%')
      }
      .padding({ top: 2 })
    }
  }

  @Builder
  private moreSettingsSection() {
    Column({ space: 0 }) {
      this.sectionEyebrow(L.text('add.section.more_settings'))

      Row({ space: 12 }) {
        this.formIcon($r('app.media.ui_note'), 28)
        Column({ space: 0 }) {
          Text(`${L.text('add.section.notes')}${L.text('add.notes.optional')}`)
            .constraintSize({ minHeight: 20 })
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.primaryText)
          TextInput({ placeholder: L.text('add.notes.placeholder'), text: this.state.notes })
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.secondaryText)
            .placeholderColor(AppTheme.tertiaryText)
            .placeholderFont({
              size: 14,
              weight: FontWeight.Regular,
            })
            .backgroundColor(Color.Transparent)
            .padding({ left: 0, right: 0, top: 0, bottom: 0 })
            .onChange((value: string) => {
              this.setNotes(value);
            })
        }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .constraintSize({ minHeight: 76 })
      .padding({ top: 8, bottom: 8 })

      this.divider()

      Row({ space: 12 }) {
        this.formIcon($r('app.media.ui_calendar'), 28)
        Column({ space: 0 }) {
          Text(L.text('add.sync_to_calendar'))
            .constraintSize({ minHeight: 20 })
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.primaryText)
          Text(L.text('add.sync_footer'))
            .constraintSize({ minHeight: 24 })
            .fontSize(12)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.tertiaryText)
            .maxLines(3)
        }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.state.shouldSyncToCalendar })
          .selectedColor(EventPresentation.categoryColor(this.state.category))
          .onChange((isOn: boolean) => {
            this.setShouldSyncToCalendar(isOn);
          })
      }
      .width('100%')
      .constraintSize({ minHeight: 76 })
      .padding({ top: 8, bottom: 8 })
    }
    .width('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  private categoryPicker() {
    Row({ space: 8 }) {
      this.categoryButton(EventCategory.Birthday)
      this.categoryButton(EventCategory.Anniversary)
      this.categoryButton(EventCategory.Custom)
    }
    .width('100%')
    .padding({ top: 2 })
  }

  @Builder
  private calendarPicker() {
    Row({ space: 8 }) {
      this.calendarButton(EventDateCalendar.Gregorian)
      this.calendarButton(EventDateCalendar.Lunar)
    }
    .width('100%')
    .padding(10)
  }

  @Builder
  private reminderButton(reminderLeadTime: ReminderLeadTime) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 7 }) {
        Text(L.reminderLabel(reminderLeadTime))
          .fontSize(12)
          .fontWeight(this.state.reminderLeadTime === reminderLeadTime ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.state.reminderLeadTime === reminderLeadTime
            ? EventPresentation.categoryColor(this.state.category) : AppTheme.secondaryText)
        if (this.state.reminderLeadTime === reminderLeadTime) {
          Image($r('app.media.ui_check'))
            .fillColor(EventPresentation.categoryColor(this.state.category))
            .width(18)
            .height(18)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
      .height(44)
      .layoutWeight(1)
      .backgroundColor(this.state.reminderLeadTime === reminderLeadTime
        ? EventPresentation.categoryBackground(this.state.category) : AppTheme.materialBackground)
      .border({ width: { bottom: this.state.reminderLeadTime === reminderLeadTime ? 2 : 0 },
        color: EventPresentation.categoryColor(this.state.category) })
      .borderRadius(12)
      .onClick(() => {
        this.setReminderLeadTime(reminderLeadTime);
      })
  }

  @Builder
  private categoryButton(category: EventCategory) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 8 }) {
        Image(EventPresentation.categoryIcon(category))
          .width(22)
          .height(22)
          .fillColor(EventPresentation.categoryColor(category))
        Text(L.categoryLabel(category))
          .fontSize(12)
          .fontWeight(this.state.category === category ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.state.category === category ? EventPresentation.categoryColor(category) : AppTheme.primaryText)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .constraintSize({ minHeight: 62 })
    .layoutWeight(1)
    .backgroundColor(EventPresentation.categoryBackground(category))
    .borderRadius(12)
    .border({ width: { bottom: this.state.category === category ? 2 : 0 },
      color: EventPresentation.categoryColor(category) })
    .onClick(() => {
      this.setCategory(category);
    })
  }

  @Builder
  private calendarButton(dateCalendar: EventDateCalendar) {
    Button(L.calendarLabel(dateCalendar), { type: ButtonType.Normal })
      .fontSize(13)
      .fontWeight(this.state.dateCalendar === dateCalendar ? FontWeight.Bold : FontWeight.Medium)
      .constraintSize({ minHeight: AppTheme.minimumTouchSize })
      .layoutWeight(1)
      .backgroundColor(this.state.dateCalendar === dateCalendar
        ? EventPresentation.categoryBackground(this.state.category) : AppTheme.materialBackground)
      .fontColor(this.state.dateCalendar === dateCalendar
        ? EventPresentation.categoryColor(this.state.category) : AppTheme.secondaryText)
      .borderRadius(10)
      .onClick(() => {
        this.setDateCalendar(dateCalendar);
      })
  }

  @Builder
  private formIcon(icon: Resource, size: number) {
    Image(icon)
      .width(size)
      .height(size)
      .borderRadius(9)
      .fillColor(EventPresentation.categoryColor(this.state.category))
      .backgroundColor(EventPresentation.categoryBackground(this.state.category))
      .padding(6)
  }

  @Builder
  private sectionEyebrow(title: string) {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppTheme.secondaryText)
      .letterSpacing(1)
  }

  @Builder
  private titleCategoryIcon() {
    Image(EventPresentation.categoryIcon(this.state.category))
      .width(36)
      .height(36)
      .padding(8)
      .fillColor(EventPresentation.categoryColor(this.state.category))
      .borderRadius(11)
      .backgroundColor(EventPresentation.categoryBackground(this.state.category))
  }

  @Builder
  private divider() {
    Row()
      .height(1)
      .width('100%')
      .backgroundColor(AppTheme.separator)
  }

  private selectedDate(): Date {
    return EventFormViewModel.parseDateText(this.state.dateText) ?? new Date();
  }

  private dateSummaryText(): string {
    if (!this.state.hasConfirmedDate) {
      return L.text('add.date.select');
    }

    if (this.state.dateCalendar === EventDateCalendar.Lunar) {
      return `${L.calendarLabel(this.state.dateCalendar)} · ${L.text('detail.repeat.' + this.state.recurrence)}`;
    }

    return L.calendarLabel(EventDateCalendar.Gregorian);
  }

  private dateHelperText(): string {
    if (this.state.dateCalendar === EventDateCalendar.Lunar) {
      return L.format('add.lunar.selection_helper', LunarCalendar.formattedMonthDay(this.selectedDate(), L.isZh()));
    }

    return L.calendarLabel(EventDateCalendar.Gregorian);
  }

  private supportsDateCalendar(): boolean {
    return this.state.category === EventCategory.Birthday || this.state.category === EventCategory.Anniversary;
  }

  private setTitle(title: string): void {
    this.updateState({
      title,
      category: this.state.category,
      dateCalendar: this.state.dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private setNotes(notes: string): void {
    this.updateState({
      title: this.state.title,
      category: this.state.category,
      dateCalendar: this.state.dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private setDateText(dateText: string, hasConfirmedDate: boolean): void {
    this.updateState({
      title: this.state.title,
      category: this.state.category,
      dateCalendar: this.state.dateCalendar,
      recurrence: this.state.recurrence,
      dateText,
      hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private setReminderLeadTime(reminderLeadTime: ReminderLeadTime): void {
    this.updateState({
      title: this.state.title,
      category: this.state.category,
      dateCalendar: this.state.dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private setShouldSyncToCalendar(shouldSyncToCalendar: boolean): void {
    this.updateState({
      title: this.state.title,
      category: this.state.category,
      dateCalendar: this.state.dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar,
    });
  }

  private setCategory(category: EventCategory): void {
    const dateCalendar = category === EventCategory.Birthday || category === EventCategory.Anniversary
      ? this.state.dateCalendar
      : EventDateCalendar.Gregorian;

    this.updateState({
      title: this.state.title,
      category,
      dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private setDateCalendar(dateCalendar: EventDateCalendar): void {
    this.updateState({
      title: this.state.title,
      category: this.state.category,
      dateCalendar,
      recurrence: this.state.recurrence,
      dateText: this.state.dateText,
      hasConfirmedDate: this.state.hasConfirmedDate,
      notes: this.state.notes,
      reminderLeadTime: this.state.reminderLeadTime,
      shouldSyncToCalendar: this.state.shouldSyncToCalendar,
    });
  }

  private updateState(next: EventFormState): void {
    this.validationMessage = '';
    this.state = {
      id: this.state.id,
      title: next.title,
      category: next.category,
      dateCalendar: next.dateCalendar,
      recurrence: next.recurrence,
      dateText: next.dateText,
      hasConfirmedDate: next.hasConfirmedDate,
      notes: next.notes,
      reminderLeadTime: next.reminderLeadTime,
      shouldSyncToCalendar: next.shouldSyncToCalendar,
    };
  }
}
