import {
  EventCategory,
  EventDateCalendar,
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
    Column({ space: 14 }) {
      this.basicSection()
      this.dateSection()
      this.reminderSection()
      this.moreSettingsSection()
    }
    .width('100%')
  }

  @Builder
  private basicSection() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        this.titleCategoryIcon()

        TextInput({ placeholder: L.text('add.title.placeholder'), text: this.state.title })
          .height(58)
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
      .height(82)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .borderRadius(AppTheme.cardRadius)
      .backgroundColor(AppTheme.cardBackground)

      this.categoryPicker()
    }
  }

  @Builder
  private dateSection() {
    Column() {
      Row({ space: 14 }) {
        this.formIcon($r('app.media.form_calendar'), AppTheme.brandSoft, 42)

        Column({ space: 4 }) {
          Text(L.text('add.section.date'))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.secondaryText)
          Text(this.state.hasConfirmedDate
            ? EventPresentation.displayDate(this.selectedDate(), this.state.dateCalendar)
            : L.text('add.date.unconfirmed'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
            .maxLines(1)
          if (this.state.hasConfirmedDate) {
            Text(this.dateSummaryText())
              .fontSize(11)
              .fontColor(AppTheme.tertiaryText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.isDatePickerExpanded ? '\u2303' : '\u203A')
          .fontSize(28)
          .fontColor(AppTheme.secondaryText)
      }
      .width('100%')
      .height(88)
      .padding({ left: 16, right: 18 })
      .onClick(() => {
        this.isDatePickerExpanded = !this.isDatePickerExpanded;
      })

      if (this.isDatePickerExpanded) {
        this.divider()
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
          .height(42)
          .width('100%')
          .borderRadius(13)
          .backgroundColor(AppTheme.brand)
          .margin({ left: 14, right: 14, bottom: 14 })
          .onClick(() => {
            this.setDateText(this.state.dateText, true);
            this.isDatePickerExpanded = false;
          })
      }
    }
    .width('100%')
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
  }

  @Builder
  private reminderSection() {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        this.formIcon($r('app.media.form_bell'), AppTheme.brandSoft, 42)
        Column({ space: 3 }) {
          Text(L.text('add.reminder.section'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.primaryText)
          Text(L.reminderLabel(this.state.reminderLeadTime))
            .fontSize(12)
            .fontColor(AppTheme.secondaryText)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Column({ space: 9 }) {
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
    .padding(14)
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
  }

  @Builder
  private moreSettingsSection() {
    Column({ space: 0 }) {
      Text(L.text('add.section.more_settings'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.primaryText)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 8 })

      Row({ space: 12 }) {
        this.formIcon($r('app.media.form_note'), AppTheme.brandSoft, 36)
        Column({ space: 0 }) {
          Text(`${L.text('add.section.notes')}${L.text('add.notes.optional')}`)
            .height(20)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.primaryText)
          TextInput({ placeholder: L.text('add.notes.placeholder'), text: this.state.notes })
            .height(18)
            .fontSize(11)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.secondaryText)
            .placeholderColor(AppTheme.tertiaryText)
            .placeholderFont({
              size: 11,
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
      .height(60)

      this.divider()

      Row({ space: 12 }) {
        this.formIcon($r('app.media.form_sync_calendar'), AppTheme.brandSoft, 36)
        Column({ space: 0 }) {
          Text(L.text('add.sync_to_calendar'))
            .height(20)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.primaryText)
          Text(L.text('add.sync_footer'))
            .height(18)
            .fontSize(11)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.tertiaryText)
            .maxLines(1)
        }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.state.shouldSyncToCalendar })
          .selectedColor(AppTheme.brand)
          .onChange((isOn: boolean) => {
            this.setShouldSyncToCalendar(isOn);
          })
      }
      .width('100%')
      .height(60)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 8 })
    .borderRadius(AppTheme.cardRadius)
    .backgroundColor(AppTheme.cardBackground)
  }

  @Builder
  private categoryPicker() {
    Row({ space: 8 }) {
      this.categoryButton(EventCategory.Birthday)
      this.categoryButton(EventCategory.Anniversary)
      this.categoryButton(EventCategory.Custom)
    }
    .width('100%')
    .padding(5)
    .borderRadius(18)
    .backgroundColor(AppTheme.materialBackground)
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
    Button() {
      Row({ space: 7 }) {
        Text(L.reminderLabel(reminderLeadTime))
          .fontSize(12)
          .fontWeight(this.state.reminderLeadTime === reminderLeadTime ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.state.reminderLeadTime === reminderLeadTime ? Color.White : AppTheme.secondaryText)
        if (this.state.reminderLeadTime === reminderLeadTime) {
          Image($r('app.media.form_selected_check'))
            .width(18)
            .height(18)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
      .height(44)
      .layoutWeight(1)
      .backgroundColor(this.state.reminderLeadTime === reminderLeadTime ? AppTheme.brand : AppTheme.materialBackground)
      .borderRadius(15)
      .onClick(() => {
        this.setReminderLeadTime(reminderLeadTime);
      })
  }

  @Builder
  private categoryButton(category: EventCategory) {
    Button() {
      Column({ space: 3 }) {
        Text(EventPresentation.categorySymbol(category))
          .fontSize(22)
          .width(28)
          .height(25)
          .textAlign(TextAlign.Center)
          .opacity(this.state.category === category ? 1 : 0.72)
        Text(L.categoryLabel(category))
          .fontSize(12)
          .fontWeight(this.state.category === category ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.state.category === category ? this.categoryColor(category) : AppTheme.secondaryText)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .height(54)
    .layoutWeight(1)
    .backgroundColor(this.state.category === category ? this.categorySoftColor(category) : Color.Transparent)
    .borderRadius(14)
    .onClick(() => {
      this.setCategory(category);
    })
  }

  @Builder
  private calendarButton(dateCalendar: EventDateCalendar) {
    Button(L.calendarLabel(dateCalendar))
      .fontSize(13)
      .fontWeight(this.state.dateCalendar === dateCalendar ? FontWeight.Bold : FontWeight.Medium)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.state.dateCalendar === dateCalendar ? AppTheme.brandSoft : AppTheme.materialBackground)
      .fontColor(this.state.dateCalendar === dateCalendar ? AppTheme.brand : AppTheme.secondaryText)
      .borderRadius(10)
      .onClick(() => {
        this.setDateCalendar(dateCalendar);
      })
  }

  @Builder
  private formIcon(icon: Resource, background: ResourceColor, size: number) {
    Image(icon)
      .width(size)
      .height(size)
      .borderRadius(size / 2)
      .backgroundColor(background)
      .padding(size >= 46 ? 12 : 10)
  }

  @Builder
  private titleCategoryIcon() {
    Text(EventPresentation.categorySymbol(this.state.category))
      .fontSize(24)
      .width(44)
      .height(44)
      .textAlign(TextAlign.Center)
      .borderRadius(22)
      .backgroundColor(this.categorySoftColor(this.state.category))
  }

  @Builder
  private divider() {
    Row()
      .height(1)
      .width('100%')
      .backgroundColor(AppTheme.separator)
  }

  private categoryColor(category: EventCategory): ResourceColor {
    switch (category) {
      case EventCategory.Birthday:
        return '#E88971';
      case EventCategory.Anniversary:
        return '#C44761';
      case EventCategory.Custom:
        return AppTheme.brand;
    }
  }

  private categorySoftColor(category: EventCategory): ResourceColor {
    switch (category) {
      case EventCategory.Birthday:
        return AppTheme.warningSoft;
      case EventCategory.Anniversary:
        return AppTheme.dangerSoft;
      case EventCategory.Custom:
        return AppTheme.brandSoft;
    }
  }

  private selectedDate(): Date {
    return EventFormViewModel.parseDateText(this.state.dateText) ?? new Date();
  }

  private dateSummaryText(): string {
    if (!this.state.hasConfirmedDate) {
      return L.text('add.date.select');
    }

    if (this.state.dateCalendar === EventDateCalendar.Lunar) {
      return this.dateHelperText();
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
      dateText: next.dateText,
      hasConfirmedDate: next.hasConfirmedDate,
      notes: next.notes,
      reminderLeadTime: next.reminderLeadTime,
      shouldSyncToCalendar: next.shouldSyncToCalendar,
    };
  }
}
