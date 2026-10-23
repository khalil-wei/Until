import { i18n } from '@kit.LocalizationKit';
import {
  EventCategory,
  EventDateCalendar,
  EventSource,
  ReminderLeadTime,
} from '../model/CountdownEvent';

const ZH_STRINGS: Map<string, string> = new Map<string, string>([
  ['detail.reminder_permission_notice', '通知权限未开启，此日子的提醒无法通知你。请开启通知；若系统不再弹窗，可前往系统设置为待到允许通知。'],
  ['detail.reminder_permission_action', '开启通知'],
  ['detail.reminder_retry_failed', '暂时无法更新提醒，请稍后重试。'],
  ['ui.lunar_repeat', '按所选农历重复规则计算'],
  ['ui.home_subtitle', '每一个期待，都值得记住'],
  ['ui.days_until', '天后，与你相逢'],
  ['ui.important_day', '属于你的重要日子'],
  ['action.back', '返回'],
  ['action.close', '关闭'],
  ['app.title', '待到'],
  ['app.subtitle', '倒计时'],
  ['action.cancel', '取消'],
  ['action.save', '保存'],
  ['action.saving', '保存中...'],
  ['action.done', '完成'],
  ['action.delete', '删除'],
  ['action.edit', '编辑'],
  ['action.discard', '放弃修改'],
  ['dialog.discard.title', '放弃未保存的修改？'],
  ['dialog.discard.message', '当前修改尚未保存，返回后将无法恢复。'],
  ['dialog.delete.title', '删除此日子？'],
  ['dialog.delete.message', '删除后无法恢复；如果已同步到本机日历，也会同时删除对应日程。'],
  ['dialog.delete.local.message', '此日子只保存在待到中，删除后无法恢复。'],
  ['dialog.delete.synced.message', '删除后会同时移除待到记录和对应的本机日历日程。'],
  ['dialog.delete.imported.title', '删除此日子？'],
  ['dialog.delete.imported.message', '此日子是早期导入的本地副本，只会从待到中删除，不会修改本机日历。'],
  ['search.events', '搜索日程'],
  ['calendar_refresh.syncing', '正在刷新...'],
  ['calendar_refresh.completed', '已刷新'],
  ['calendar_refresh.failed', '刷新失败，请稍后重试'],
  ['error.delete_from_calendar', '删除失败，请检查日历权限后重试。'],
  ['filter.all', '全部'],
  ['category.birthday', '生日'],
  ['category.anniversary', '纪念日'],
  ['category.custom', '自定义'],
  ['calendar.gregorian', '公历'],
  ['calendar.lunar', '农历'],
  ['source.local', '本地事件'],
  ['source.app_calendar', '已同步到日历'],
  ['source.imported_calendar', '从系统日历导入'],
  ['source.local.short', '本'],
  ['source.app_calendar.short', '同'],
  ['source.imported_calendar.short', '历'],
  ['countdown.today', '今天'],
  ['countdown.tomorrow', '明天'],
  ['countdown.day_after_tomorrow', '后天'],
  ['countdown.expired', '已过期'],
  ['countdown.expired.short', '过期'],
  ['countdown.beyond_thousand', '遥遥有期'],
  ['countdown.day.unit', '天'],
  ['countdown.future.unit', '天后'],
  ['today.section.title', '今天'],
  ['today.section.upcoming', '即将到来'],
  ['today.section.count', '%d 个'],
  ['empty.no_days.title', '还没有待到的日子'],
  ['empty.no_days.description', '添加生日、纪念日或任何值得等待的日期'],
  ['empty.activation.title', '把重要日子放在眼前'],
  ['empty.activation.description', '先选一种日子，保存后可以添加到桌面随时查看'],
  ['empty.activation.birthday', '记录一个生日'],
  ['empty.activation.anniversary', '记录一个纪念日'],
  ['empty.activation.custom', '记录其他日子'],
  ['empty.activation.card_hint', '添加后可以放到桌面，不打开 App 也能看到倒计时'],
  ['empty.no_matching.title', '没有匹配的日子'],
  ['empty.no_matching.description', '试试其他关键词或分类'],
  ['event.add_day', '添加日子'],
  ['event.open_detail.hint', '双击查看详情'],
  ['add.title', '新建日子'],
  ['edit.title', '编辑日子'],
  ['add.section.basic', '基本信息'],
  ['add.title.placeholder', '名称'],
  ['add.section.date', '日期'],
  ['add.date.select', '选择日期'],
  ['add.date.unconfirmed', '请选择日期'],
  ['add.date.confirm', '确认日期'],
  ['add.section.notes', '备注'],
  ['add.section.more_settings', '更多设置'],
  ['add.notes.optional', '（可选）'],
  ['add.notes.placeholder', '添加备注，让这一天更有意义'],
  ['add.date_calendar', '日期历法'],
  ['add.lunar.helper', '农历日期会按所选重复规则自动换算倒计时。'],
  ['add.lunar.selection_helper', '当前选择：农历 %@，倒计时会按所选重复规则计算。'],
  ['add.sync_to_calendar', '同步到本机日历'],
  ['add.sync_footer', '开启后同步到本机日历'],
  ['add.lunar.sync_footer', '开启后同步到本机日历'],
  ['add.reminder.section', '提醒'],
  ['add.reminder.footer', '开启同步到本机日历后，将由系统日历按所选提前量提醒。'],
  ['detail.title', '详情'],
  ['detail.category', '类型'],
  ['detail.date', '日期'],
  ['detail.original_date', '原始日期'],
  ['detail.next_date', '下次发生'],
  ['detail.repeat', '重复'],
  ['detail.repeat.yearly', '每年'],
  ['detail.repeat.monthly', '每月'],
  ['detail.repeat.weekly', '每周'],
  ['detail.repeat.helper', '每月按所选历法的同一日重复，缺少该日期的月份跳过；每周从所选日期起每 7 天重复。'],
  ['detail.year', '年份'],
  ['detail.source', '来源'],
  ['detail.calendar', '日历'],
  ['detail.reminder', '提醒'],
  ['detail.basic_info', '基本信息'],
  ['detail.settings', '提醒与来源'],
  ['detail.notes', '备注'],
  ['detail.no_notes', '暂无备注'],
  ['detail.not_found', '没有找到这个日子'],
  ['reminder.none', '不提醒'],
  ['reminder.same_day', '当天提醒'],
  ['reminder.one_day', '提前 1 天'],
  ['reminder.three_days', '提前 3 天'],
  ['reminder.seven_days', '提前 7 天'],
  ['validation.title.required', '请输入事件名称'],
  ['validation.date.required', '请先选择并确认日期'],
  ['validation.date.invalid', '请选择有效日期'],
  ['validation.form.invalid', '请检查表单'],
  ['validation.calendar.permission_denied', '请先允许日历权限，才能同步到本机日历'],
  ['validation.calendar.sync_failed', '同步到本机日历失败，请检查日历权限后重试'],
  ['validation.saved', '已保存'],
  ['validation.saved_calendar_failed', '已保存到待到，但同步本机日历失败'],
  ['activation.saved_title', '“%@”已保存'],
  ['activation.saved_countdown', '距离这一天还有 %@'],
  ['activation.next_step', '再完成一步，让重要日子主动来找你'],
  ['activation.enable_any_reminder', '开启提醒'],
  ['activation.add_card', '添加到桌面'],
  ['activation.later', '暂时不用'],
  ['activation.reminder_enabled', '提醒已开启'],
  ['activation.reminder_permission_denied', '通知权限未开启，也可以选择添加桌面卡片'],
  ['activation.saved_reminder_permission_denied', '已保存；通知权限未开启，可稍后重试或添加桌面卡片'],
  ['activation.card_fallback', '请长按桌面，进入服务卡片并搜索“待到”'],
  ['activation.card.title', '让这个日子主动回来'],
  ['activation.card.description', '开启提醒后，重要日子临近时会主动通知你'],
  ['notification.title', '待到提醒'],
  ['notification.content', '%@ 快到了'],
  ['easter_egg.special.42', '答案正在路上'],
  ['easter_egg.special.365', '绕太阳一圈后见'],
  ['easter_egg.special.520', '心动有期'],
  ['easter_egg.night_letter', '这么晚了，重要的日子不会跑掉。'],
  ['easter_egg.distant.message', '所有遥遥有期，都在一天天靠近。'],
  ['easter_egg.distant.hint', '长按查看精确天数'],
  ['easter_egg.arrived', '等到了'],
  ['easter_egg.arrival.replay_hint', '长按可以再庆祝一次'],
  ['date.lunar_format', '农历 %@ · %@'],
  ['card.upcoming', '即将到来'],
  ['card.brand.short', 'UNTIL'],
  ['card.next', '最近'],
  ['card.large.title', '待到 Until'],
  ['card.large.subtitle', '把值得期待的日子放在眼前'],
  ['card.more_events', '接下来的日子'],
  ['card.event_count', '%d项'],
  ['card.empty', '暂无日程'],
  ['card.empty.subtitle', '打开 App 添加'],
  ['card.center.home_title', '桌面卡片'],
  ['card.center.home_add', '添加到桌面'],
  ['card.center.home_added', '已添加 %d 张'],
  ['card.center.title', '桌面卡片'],
  ['card.center.subtitle', '把重要日子一直放在眼前'],
  ['card.center.empty_title', '把倒计时放到桌面'],
  ['card.center.empty_description', '添加服务卡片后，不打开 App 也能看到重要日子还有多久。'],
  ['card.center.query_unavailable', '暂时无法读取桌面卡片；你仍可以进入系统页面查看或添加。'],
  ['card.center.empty_step', '在系统页面选择待到卡片和尺寸，然后添加到桌面'],
  ['card.center.size_hint', '卡片尺寸由你在系统页面选择'],
  ['card.center.content', '显示内容'],
  ['card.center.automatic', '自动显示最近日子'],
  ['card.center.automatic_detail', '日期临近时自动更新主位置'],
  ['card.center.fixed', '固定显示某个日子'],
  ['card.center.fixed_detail', '主位置始终显示你选的日子'],
  ['card.center.fixed_helper', '小卡片显示所选日子；中、大卡片将它放在主位置，其余按日期补齐。'],
  ['card.center.palette', '配色'],
  ['card.center.palette_smart', '智能'],
  ['card.center.palette_indigo', '靛蓝'],
  ['card.center.palette_dark', '深色'],
  ['card.center.installed', '已添加的卡片'],
  ['card.center.preview', '卡片预览'],
  ['card.center.add', '添加到桌面'],
  ['card.center.add_another', '添加新卡片'],
  ['card.center.save_refresh', '保存并刷新'],
  ['card.center.saved', '卡片已刷新'],
  ['card.center.refresh_pending', '设置已保存，桌面刷新暂未完成'],
  ['card.center.save_failed', '没有找到这张卡片，请重新添加'],
  ['card.center.size_small', '小卡片'],
  ['card.center.size_medium', '中卡片'],
  ['card.center.size_large', '大卡片'],
  ['card.center.form_label', '卡片 %@'],
]);

const EN_STRINGS: Map<string, string> = new Map<string, string>([
  ['action.back', 'Back'],
  ['action.close', 'Close'],
  ['ui.lunar_repeat', 'Uses the selected lunar recurrence'],
  ['ui.home_subtitle', 'Keep the days that matter close'],
  ['ui.days_until', 'days to go'],
  ['ui.important_day', 'A day worth remembering'],
  ['detail.reminder_permission_notice', 'Notifications are disabled for this event. Enable notifications; if no prompt appears, allow notifications for Until in system settings.'],
  ['detail.reminder_permission_action', 'Enable notifications'],
  ['detail.reminder_retry_failed', 'Unable to update reminders. Please try again.'],
  ['app.title', 'Until'],
  ['app.subtitle', 'Countdown'],
  ['action.cancel', 'Cancel'],
  ['action.save', 'Save'],
  ['action.saving', 'Saving...'],
  ['action.done', 'Done'],
  ['action.delete', 'Delete'],
  ['action.edit', 'Edit'],
  ['action.discard', 'Discard'],
  ['dialog.discard.title', 'Discard unsaved changes?'],
  ['dialog.discard.message', 'Your changes have not been saved.'],
  ['dialog.delete.title', 'Delete this day?'],
  ['dialog.delete.message', 'This cannot be undone. Synced device-calendar events will also be deleted.'],
  ['dialog.delete.local.message', 'This day exists only in Until and cannot be restored after deletion.'],
  ['dialog.delete.synced.message', 'This removes the day from Until and the linked device-calendar event.'],
  ['dialog.delete.imported.title', 'Delete this day?'],
  ['dialog.delete.imported.message', 'This is a local copy imported by an earlier version. It will only be removed from Until.'],
  ['search.events', 'Search events'],
  ['calendar_refresh.syncing', 'Refreshing...'],
  ['calendar_refresh.completed', 'Refreshed'],
  ['calendar_refresh.failed', 'Refresh failed. Try again.'],
  ['error.delete_from_calendar', 'Could not delete the event. Check Calendar permission and try again.'],
  ['filter.all', 'All'],
  ['category.birthday', 'Birthday'],
  ['category.anniversary', 'Anniversary'],
  ['category.custom', 'Custom'],
  ['calendar.gregorian', 'Gregorian'],
  ['calendar.lunar', 'Lunar'],
  ['source.local', 'Local event'],
  ['source.app_calendar', 'Synced to Calendar'],
  ['source.imported_calendar', 'Imported from Calendar'],
  ['source.local.short', 'L'],
  ['source.app_calendar.short', 'S'],
  ['source.imported_calendar.short', 'C'],
  ['countdown.today', 'Today'],
  ['countdown.tomorrow', 'Tomorrow'],
  ['countdown.day_after_tomorrow', 'Day after tomorrow'],
  ['countdown.expired', 'Expired'],
  ['countdown.expired.short', 'Expired'],
  ['countdown.beyond_thousand', '1000+'],
  ['countdown.day.unit', 'days'],
  ['countdown.future.unit', 'days'],
  ['today.section.title', 'Today'],
  ['today.section.upcoming', 'Upcoming'],
  ['today.section.count', '%d events'],
  ['empty.no_days.title', 'No days yet'],
  ['empty.no_days.description', 'Add birthdays, anniversaries, or any date worth waiting for'],
  ['empty.activation.title', 'Keep important days in sight'],
  ['empty.activation.description', 'Choose a day first, then add it to the Home Screen for an always-visible countdown'],
  ['empty.activation.birthday', 'Add a birthday'],
  ['empty.activation.anniversary', 'Add an anniversary'],
  ['empty.activation.custom', 'Add another day'],
  ['empty.activation.card_hint', 'After saving, add a Home Screen card to see the countdown without opening the app.'],
  ['empty.no_matching.title', 'No matching days'],
  ['empty.no_matching.description', 'Try another keyword or category'],
  ['event.add_day', 'Add Day'],
  ['event.open_detail.hint', 'Double tap to view details'],
  ['add.title', 'New Day'],
  ['edit.title', 'Edit Day'],
  ['add.section.basic', 'Basic Info'],
  ['add.title.placeholder', 'Name'],
  ['add.section.date', 'Date'],
  ['add.date.select', 'Select Date'],
  ['add.date.unconfirmed', 'Choose a date'],
  ['add.date.confirm', 'Confirm Date'],
  ['add.section.notes', 'Notes'],
  ['add.section.more_settings', 'More settings'],
  ['add.notes.optional', ' (optional)'],
  ['add.notes.placeholder', 'Add a note to make this day more meaningful'],
  ['add.date_calendar', 'Date Calendar'],
  ['add.lunar.helper', 'Lunar dates use the selected recurrence.'],
  ['add.lunar.selection_helper', 'Selected lunar date: %@. Countdown uses the selected recurrence.'],
  ['add.sync_to_calendar', 'Sync to Device Calendar'],
  ['add.sync_footer', 'Syncs to your device calendar'],
  ['add.lunar.sync_footer', 'Syncs to your device calendar'],
  ['add.reminder.section', 'Reminder'],
  ['add.reminder.footer', 'When synced to the device calendar, reminders are delivered by the system calendar using the selected lead time.'],
  ['detail.title', 'Details'],
  ['detail.category', 'Type'],
  ['detail.date', 'Date'],
  ['detail.original_date', 'Original date'],
  ['detail.next_date', 'Next occurrence'],
  ['detail.repeat', 'Repeat'],
  ['detail.repeat.yearly', 'Yearly'],
  ['detail.repeat.monthly', 'Monthly'],
  ['detail.repeat.weekly', 'Weekly'],
  ['detail.repeat.helper', 'Monthly skips months without the selected day. Weekly repeats every 7 days from the selected date.'],
  ['detail.year', 'Year'],
  ['detail.source', 'Source'],
  ['detail.calendar', 'Calendar'],
  ['detail.reminder', 'Reminder'],
  ['detail.basic_info', 'Event details'],
  ['detail.settings', 'Reminder & source'],
  ['detail.notes', 'Notes'],
  ['detail.no_notes', 'No notes'],
  ['detail.not_found', 'This day was not found'],
  ['reminder.none', 'No reminder'],
  ['reminder.same_day', 'Same day'],
  ['reminder.one_day', '1 day before'],
  ['reminder.three_days', '3 days before'],
  ['reminder.seven_days', '7 days before'],
  ['validation.title.required', 'Enter an event name'],
  ['validation.date.required', 'Choose and confirm a date'],
  ['validation.date.invalid', 'Select a valid date'],
  ['validation.form.invalid', 'Check the form'],
  ['validation.calendar.permission_denied', 'Allow Calendar permission before syncing to the device calendar'],
  ['validation.calendar.sync_failed', 'Could not sync to the device calendar. Check Calendar permission and try again.'],
  ['validation.saved', 'Saved'],
  ['validation.saved_calendar_failed', 'Saved in Until, but Calendar sync failed'],
  ['activation.saved_title', '“%@” is saved'],
  ['activation.saved_countdown', '%@ until this day'],
  ['activation.next_step', 'One more step lets the day come back to you'],
  ['activation.enable_any_reminder', 'Enable Reminder'],
  ['activation.add_card', 'Add to Home Screen'],
  ['activation.later', 'Not now'],
  ['activation.reminder_enabled', 'Reminder enabled'],
  ['activation.reminder_permission_denied', 'Notifications are off. You can add a Home Screen card instead.'],
  ['activation.saved_reminder_permission_denied', 'Saved. Notifications are off; try again later or add a Home Screen card.'],
  ['activation.card_fallback', 'Touch and hold the Home Screen, open Service Cards, and search for Until.'],
  ['activation.card.title', 'Let this day come back to you'],
  ['activation.card.description', 'Enable reminders to be notified as an important day approaches.'],
  ['notification.title', 'Until Reminder'],
  ['notification.content', '%@ is coming up'],
  ['easter_egg.special.42', 'The answer is on its way'],
  ['easter_egg.special.365', 'See you after one trip around the sun'],
  ['easter_egg.night_letter', 'It’s late. Your important days aren’t going anywhere.'],
  ['easter_egg.distant.message', 'Even the farthest day is getting closer.'],
  ['easter_egg.distant.hint', 'Long press to reveal the exact count'],
  ['easter_egg.arrived', 'It’s here'],
  ['easter_egg.arrival.replay_hint', 'Long press to celebrate once more'],
  ['date.lunar_format', 'Lunar %@ · %@'],
  ['card.upcoming', 'Upcoming'],
  ['card.brand.short', 'UNTIL'],
  ['card.next', 'NEXT'],
  ['card.large.title', 'Until'],
  ['card.large.subtitle', 'Keep meaningful days in sight'],
  ['card.more_events', 'Coming up next'],
  ['card.event_count', '%d items'],
  ['card.empty', 'No events'],
  ['card.empty.subtitle', 'Open app to add'],
  ['card.center.home_title', 'Home Screen Cards'],
  ['card.center.home_add', 'Add to Home Screen'],
  ['card.center.home_added', '%d cards added'],
  ['card.center.title', 'Home Screen Cards'],
  ['card.center.subtitle', 'Keep important days in sight'],
  ['card.center.empty_title', 'Put countdowns on your Home Screen'],
  ['card.center.empty_description', 'Add a service card to see important countdowns without opening the app.'],
  ['card.center.query_unavailable', 'Home Screen cards could not be read. You can still view or add them on the system screen.'],
  ['card.center.empty_step', 'Choose an Until card and size on the system screen, then add it to the Home Screen.'],
  ['card.center.size_hint', 'Choose the actual card size on the system screen.'],
  ['card.center.content', 'Content'],
  ['card.center.automatic', 'Show nearest days'],
  ['card.center.automatic_detail', 'Updates the first event as dates approach'],
  ['card.center.fixed', 'Pin a specific day'],
  ['card.center.fixed_detail', 'Keep your chosen day in the first position'],
  ['card.center.fixed_helper', 'Small cards show the selected day. Medium and large cards put it first and fill the rest by date.'],
  ['card.center.palette', 'Color Scheme'],
  ['card.center.palette_smart', 'Smart'],
  ['card.center.palette_indigo', 'Indigo'],
  ['card.center.palette_dark', 'Dark'],
  ['card.center.installed', 'Added Cards'],
  ['card.center.preview', 'Card Preview'],
  ['card.center.add', 'Add to Home Screen'],
  ['card.center.add_another', 'Add Another Card'],
  ['card.center.save_refresh', 'Save and Refresh'],
  ['card.center.saved', 'Card refreshed'],
  ['card.center.refresh_pending', 'Settings saved. Home Screen refresh is pending.'],
  ['card.center.save_failed', 'This card is unavailable. Add it again.'],
  ['card.center.size_small', 'Small card'],
  ['card.center.size_medium', 'Medium card'],
  ['card.center.size_large', 'Large card'],
  ['card.center.form_label', 'Card %@'],
]);

export class L {
  static isZh(): boolean {
    return L.language().toLocaleLowerCase().startsWith('zh');
  }

  static text(key: string): string {
    const localized = (L.isZh() ? ZH_STRINGS : EN_STRINGS).get(key);
    const fallback = ZH_STRINGS.get(key);
    return localized ?? fallback ?? key;
  }

  static format(key: string, value: string): string {
    return L.text(key).replace('%@', value);
  }

  static formatCounts(key: string, first: number, second: number): string {
    return L.text(key).replace('%d', `${first}`).replace('%d', `${second}`);
  }

  static cardCount(count: number): string {
    return L.text('card.event_count').replace('%d', `${count}`);
  }

  static installedCardCount(count: number): string {
    return L.text('card.center.home_added').replace('%d', `${count}`);
  }

  static count(count: number): string {
    if (L.isZh()) {
      return `${count} 个`;
    }

    return count === 1 ? '1 event' : `${count} events`;
  }

  static categoryLabel(category: EventCategory): string {
    switch (category) {
      case EventCategory.Birthday:
        return L.text('category.birthday');
      case EventCategory.Anniversary:
        return L.text('category.anniversary');
      case EventCategory.Custom:
        return L.text('category.custom');
    }
  }

  static categorySymbol(category: EventCategory): string {
    switch (category) {
      case EventCategory.Birthday:
        return '🎂';
      case EventCategory.Anniversary:
        return '💝';
      case EventCategory.Custom:
        return '✨';
    }
  }

  static calendarLabel(calendar: EventDateCalendar): string {
    switch (calendar) {
      case EventDateCalendar.Gregorian:
        return L.text('calendar.gregorian');
      case EventDateCalendar.Lunar:
        return L.text('calendar.lunar');
    }
  }

  static sourceLabel(source: EventSource): string {
    switch (source) {
      case EventSource.Local:
        return L.text('source.local');
      case EventSource.AppCalendar:
        return L.text('source.app_calendar');
      case EventSource.ImportedCalendar:
        return L.text('source.imported_calendar');
    }
  }

  static sourceSymbol(source: EventSource): string {
    switch (source) {
      case EventSource.Local:
        return '●';
      case EventSource.AppCalendar:
        return '✓';
      case EventSource.ImportedCalendar:
        return '↗';
    }
  }

  static reminderLabel(leadTime: ReminderLeadTime): string {
    switch (leadTime) {
      case ReminderLeadTime.None:
        return L.text('reminder.none');
      case ReminderLeadTime.SameDay:
        return L.text('reminder.same_day');
      case ReminderLeadTime.OneDay:
        return L.text('reminder.one_day');
      case ReminderLeadTime.ThreeDays:
        return L.text('reminder.three_days');
      case ReminderLeadTime.SevenDays:
        return L.text('reminder.seven_days');
    }
  }

  private static language(): string {
    try {
      const preferred = i18n.System.getFirstPreferredLanguage();
      if (preferred.length > 0) {
        return preferred;
      }
    } catch (error) {
    }

    try {
      return i18n.System.getSystemLanguage();
    } catch (error) {
      return 'zh-Hans';
    }
  }
}
