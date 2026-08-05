import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var viewModel: EventListViewModel
    @Environment(\.dismiss) private var dismiss

    private let eventToEdit: CountdownEvent?
    private let onSaved: () -> Void

    @State private var title = ""
    @State private var date = Date()
    @State private var category: EventCategory = .birthday
    @State private var dateCalendar: EventDateCalendar = .gregorian
    @State private var notes = ""
    @State private var reminderLeadTime: ReminderLeadTime = .none
    @State private var isSaving = false
    @State private var syncToCalendar = true

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canSyncToCalendar: Bool {
        viewModel.authorizationStatus == .fullAccess &&
            dateCalendar == .gregorian &&
            eventToEdit?.source != .importedCalendar
    }
    private var isEditing: Bool { eventToEdit != nil }

    init(event: CountdownEvent? = nil, onSaved: @escaping () -> Void = {}) {
        let initialCategory = event?.category ?? .birthday
        eventToEdit = event
        self.onSaved = onSaved
        _title = State(initialValue: event?.title ?? "")
        _date = State(initialValue: event?.originalDate ?? Date())
        _category = State(initialValue: initialCategory)
        _dateCalendar = State(initialValue: initialCategory.supportsDateCalendar ? event?.dateCalendar ?? .gregorian : .gregorian)
        _notes = State(initialValue: event?.notes ?? "")
        _reminderLeadTime = State(initialValue: event?.reminderLeadTime ?? .none)
        _syncToCalendar = State(initialValue: event?.source == .importedCalendar ? false : event?.calendarEventID != nil || event == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "add.section.basic")) {
                    TextField(String(localized: "add.title.placeholder"), text: $title)
                        .submitLabel(.done)

                    Picker(String(localized: "add.category"), selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.symbolName)
                                .tag(cat)
                        }
                    }

                    if category.supportsDateCalendar {
                        Picker(String(localized: "add.date_calendar"), selection: $dateCalendar) {
                            ForEach(EventDateCalendar.allCases, id: \.self) { calendar in
                                Text(calendar.displayName).tag(calendar)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section(String(localized: "add.section.date")) {
                    DatePicker(
                        String(localized: "add.date.select"),
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.calendar, dateCalendar.foundationCalendar)
                    .environment(\.locale, Locale.autoupdatingCurrent)
                    .id(dateCalendar)

                    if dateCalendar == .lunar {
                        Text(lunarSelectionHelper)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String(localized: "add.section.notes")) {
                    TextField(String(localized: "add.notes.placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Picker(String(localized: "reminder.lead_time"), selection: $reminderLeadTime) {
                        ForEach(ReminderLeadTime.allCases) { leadTime in
                            Text(leadTime.displayName).tag(leadTime)
                        }
                    }
                } header: {
                    Text(String(localized: "reminder.section"))
                } footer: {
                    Text(String(localized: "reminder.footer"))
                        .font(.footnote)
                }

                Section {
                    Toggle(String(localized: "add.sync_to_calendar"), isOn: $syncToCalendar)
                        .disabled(!canSyncToCalendar)
                } footer: {
                    if eventToEdit?.source == .importedCalendar {
                        Text(String(localized: "add.imported_sync_footer"))
                            .font(.footnote)
                    } else if dateCalendar == .lunar {
                        Text(String(localized: "add.lunar.sync_footer"))
                            .font(.footnote)
                    } else if canSyncToCalendar {
                        Text(String(localized: "add.sync_footer"))
                            .font(.footnote)
                    } else {
                        Text(String(localized: "add.no_calendar_access_footer"))
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(isEditing ? String(localized: "edit.title") : String(localized: "add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(String(localized: "action.save")) { save() }
                            .disabled(!canSave)
                            .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: category) { _, newCategory in
                if !newCategory.supportsDateCalendar {
                    dateCalendar = .gregorian
                }
            }
            .onChange(of: dateCalendar) { _, newCalendar in
                if newCalendar == .lunar {
                    syncToCalendar = false
                }
            }
        }
    }

    private var lunarSelectionHelper: String {
        String.localizedStringWithFormat(
            NSLocalizedString("add.lunar.selection_helper", comment: "Shows the currently selected lunar date"),
            EventDateCalendar.formattedLunarMonthDay(from: date)
        )
    }

    private func save() {
        isSaving = true
        let eventCountBeforeSave = viewModel.events.count
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesOrNil = trimmedNotes.isEmpty ? nil : trimmedNotes

        Task {
            if let eventToEdit {
                await viewModel.updateEvent(
                    eventToEdit,
                    title: trimmedTitle,
                    date: date,
                    category: category,
                    dateCalendar: dateCalendar,
                    syncToCalendar: syncToCalendar,
                    notes: notesOrNil,
                    reminderLeadTime: reminderLeadTime
                )
            } else if syncToCalendar && canSyncToCalendar {
                await viewModel.addEvent(
                    title: trimmedTitle,
                    date: date,
                    category: category,
                    dateCalendar: dateCalendar,
                    notes: notesOrNil,
                    reminderLeadTime: reminderLeadTime
                )
            } else {
                viewModel.addLocalEvent(
                    title: trimmedTitle,
                    date: date,
                    category: category,
                    dateCalendar: dateCalendar,
                    notes: notesOrNil,
                    reminderLeadTime: reminderLeadTime
                )
            }
            isSaving = false
            dismiss()
            if !isEditing && viewModel.events.count > eventCountBeforeSave {
                DispatchQueue.main.async(execute: onSaved)
            }
        }
    }
}

private extension EventCategory {
    var supportsDateCalendar: Bool {
        self == .birthday || self == .anniversary
    }
}

#Preview {
    AddEventView()
        .environmentObject(EventListViewModel())
}
