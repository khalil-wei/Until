import EventKit
import SwiftUI
import UIKit

struct EventListView: View {
    @EnvironmentObject var viewModel: EventListViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Binding var deepLink: AppDeepLink?
    @AppStorage("easterEgg.lastNightLetterShownAt") private var lastNightLetterShownAt = 0.0
    @AppStorage("journey.widgetGuideCompleted") private var widgetGuideCompleted = false
    @State private var activeSheet: EventSheet?
    @State private var eventPendingCalendarDelete: CountdownEvent?
    @State private var calendarDeleteQueue: [CountdownEvent] = []
    @State private var searchText = ""
    @State private var selectedFilter: EventCategoryFilter = .all
    @State private var filterNavigationDirection = 1
    @State private var didPrewarmContextMenu = false
    @State private var eventRowFrames: [UUID: CGRect] = [:]
    @State private var shouldShowNightLetter = false

    private let eventListCoordinateSpace = "event-list-coordinate-space"

    private var filteredEvents: [CountdownEvent] {
        viewModel.events.filter { event in
            let matchesCategory = selectedFilter.category.map { event.category == $0 } ?? true
            let matchesSearch = searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var todayEvents: [CountdownEvent] {
        filteredEvents.filter { $0.daysUntil == 0 }
    }

    private var futureEvents: [CountdownEvent] {
        filteredEvents.filter { $0.daysUntil != 0 }
    }

    private var shouldShowCalendarAccessBanner: Bool {
        switch viewModel.authorizationStatus {
        case .denied, .restricted, .writeOnly:
            return true
        default:
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView(String(localized: "state.loading"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 0) {
                        statusBanners
                        EmptyStateView {
                            activeSheet = .add
                        }
                    }
                } else {
                    eventList
                }
            }
            .navigationTitle(String(localized: "app.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "event.add"))
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        activeSheet = .widgetGuide
                    } label: {
                        Label(String(localized: "widget.guide.action"), systemImage: "rectangle.grid.2x2")
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text(String(localized: "search.events")))
            .onChange(of: deepLink, initial: true) { _, _ in
                handleDeepLinkIfPossible()
            }
            .onChange(of: viewModel.events) { _, _ in
                handleDeepLinkIfPossible()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    evaluateNightLetter()
                }
            }
            .onChange(of: viewModel.events.isEmpty) { _, _ in
                evaluateNightLetter()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    AddEventView {
                        guard !widgetGuideCompleted else { return }
                        activeSheet = .widgetGuide
                    }
                        .environmentObject(viewModel)
                case .event(let event, let initialMode):
                    EventManagementSheet(
                        event: event,
                        initialMode: initialMode,
                        onIgnoreImported: {
                            viewModel.ignoreImportedEvent(event)
                            activeSheet = nil
                        },
                        onRequestCalendarDelete: {
                            activeSheet = nil
                            enqueueCalendarDeletes([event])
                        }
                    )
                    .environmentObject(viewModel)
                case .widgetGuide:
                    WidgetSetupGuide {
                        widgetGuideCompleted = true
                        activeSheet = nil
                    }
                }
            }
            .alert(String(localized: "error.title"), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(String(localized: "action.ok")) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(
                String(localized: "delete_calendar.title"),
                isPresented: Binding(
                    get: { eventPendingCalendarDelete != nil },
                    set: { if !$0 { eventPendingCalendarDelete = nil } }
                ),
                presenting: eventPendingCalendarDelete
            ) { event in
                Button(String(localized: "action.cancel"), role: .cancel) {
                    eventPendingCalendarDelete = nil
                    calendarDeleteQueue.removeAll()
                }
                if event.source == .importedCalendar {
                    Button(String(localized: "delete_calendar.remove_app_only")) {
                        viewModel.ignoreImportedEvent(event)
                        completeCalendarDeletePrompt()
                    }
                }
                Button(String(localized: "delete_calendar.confirm"), role: .destructive) {
                    viewModel.deleteCalendarBackedEvent(event)
                    completeCalendarDeletePrompt()
                }
            } message: { event in
                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString("delete_calendar.message", comment: "Warns before deleting a calendar-backed event"),
                        event.title
                    )
                )
            }
        }
    }

    private func handleDeepLinkIfPossible() {
        guard let deepLink else { return }

        switch deepLink {
        case .add:
            activeSheet = .add
            self.deepLink = nil
        case .event(let id):
            guard let event = viewModel.events.first(where: { $0.id == id }) else { return }
            activeSheet = .event(event, initialMode: .detail)
            self.deepLink = nil
        }
    }

    private var eventList: some View {
        VStack(spacing: 0) {
            statusBanners

            filterBar

            ZStack {
                eventResultsList
                    .id(selectedFilter)
                    .transition(filterTransition)
            }
            .coordinateSpace(name: eventListCoordinateSpace)
            .onPreferenceChange(EventRowFramePreferenceKey.self) { frames in
                eventRowFrames = frames
            }
            .clipped()
            .animation(.smooth(duration: 0.28), value: selectedFilter)
            .simultaneousGesture(filterSwipeGesture)
        }
        .onAppear {
            prewarmContextMenuIfNeeded()
            evaluateNightLetter()
        }
    }

    private func evaluateNightLetter(now: Date = Date()) {
        guard !shouldShowNightLetter else { return }

        let lastShownAt = lastNightLetterShownAt > 0
            ? Date(timeIntervalSince1970: lastNightLetterShownAt)
            : nil

        guard NightLetterPolicy.shouldShow(
            now: now,
            lastShownAt: lastShownAt,
            hasEvents: !viewModel.events.isEmpty
        ) else {
            return
        }

        shouldShowNightLetter = true
        lastNightLetterShownAt = now.timeIntervalSince1970
    }

    private var eventResultsList: some View {
            List {
                if filteredEvents.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "empty.no_matching_events"), systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text(String(localized: "empty.no_matching_events.description"))
                    }
                    .listRowSeparator(.hidden)
                } else {
                    if !todayEvents.isEmpty {
                        Section {
                            ForEach(todayEvents) { event in
                                editableEventRow(event)
                            }
                            .onDelete { offsets in
                                let eventsToDelete = offsets.map { todayEvents[$0] }
                                requestDelete(eventsToDelete)
                            }
                        } header: {
                            TodaySectionHeader(count: todayEvents.count)
                        }
                    }

                    if !futureEvents.isEmpty {
                        Section {
                            ForEach(futureEvents) { event in
                                editableEventRow(event)
                            }
                            .onDelete { offsets in
                                let eventsToDelete = offsets.map { futureEvents[$0] }
                                requestDelete(eventsToDelete)
                            }
                        } header: {
                            if !todayEvents.isEmpty {
                                Text(String(localized: "today.section.upcoming"))
                            }
                        }
                    }

                    if shouldShowNightLetter {
                        NightLetterView()
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 18, leading: 24, bottom: 24, trailing: 24))
                    }
                }
            }
            .listStyle(.plain)
    }

    private var filterSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 32, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                guard abs(horizontal) > 58, abs(horizontal) > abs(vertical) * 1.45 else {
                    return
                }

                guard canNavigateFilters(
                    from: value.startLocation,
                    horizontalTranslation: horizontal
                ) else {
                    return
                }

                setSelectedFilter(horizontal < 0 ? selectedFilter.next : selectedFilter.previous)
            }
    }

    private func canNavigateFilters(
        from startLocation: CGPoint,
        horizontalTranslation: CGFloat
    ) -> Bool {
        let startsOnEventRow = eventRowFrames.values.contains { frame in
            frame.insetBy(dx: -12, dy: -4).contains(startLocation)
        }

        guard startsOnEventRow else {
            return true
        }

        return horizontalTranslation > 0
    }

    private var filterTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: filterNavigationDirection >= 0 ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: filterNavigationDirection >= 0 ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    private var filterSelection: Binding<EventCategoryFilter> {
        Binding(
            get: { selectedFilter },
            set: { setSelectedFilter($0) }
        )
    }

    private func setSelectedFilter(_ newValue: EventCategoryFilter) {
        guard newValue != selectedFilter else { return }

        filterNavigationDirection = selectedFilter.navigationDirection(to: newValue)
        withAnimation(.smooth(duration: 0.28)) {
            selectedFilter = newValue
        }
    }

    private func prewarmContextMenuIfNeeded() {
        guard !didPrewarmContextMenu else { return }
        didPrewarmContextMenu = true
        EventRowContextMenuPrewarmer.prewarm()
    }

    private func editableEventRow(_ event: CountdownEvent) -> some View {
        EventRowView(event: event)
            .contentShape(Rectangle())
            .onTapGesture {
                activeSheet = .event(event, initialMode: .detail)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text(String(localized: "detail.accessibility_hint")))
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: EventRowFramePreferenceKey.self,
                        value: [event.id: proxy.frame(in: .named(eventListCoordinateSpace))]
                    )
                }
            )
            .contextMenu {
                Button {
                    activeSheet = .event(event, initialMode: .edit)
                } label: {
                    Label(EventRowContextMenuPrewarmer.editTitle, systemImage: "pencil")
                }

                if event.source == .importedCalendar {
                    Button {
                        viewModel.ignoreImportedEvent(event)
                    } label: {
                        Label(EventRowContextMenuPrewarmer.ignoreTitle, systemImage: "eye.slash")
                    }

                    Button(role: .destructive) {
                        enqueueCalendarDeletes([event])
                    } label: {
                        Label(EventRowContextMenuPrewarmer.deleteTitle, systemImage: "trash")
                    }
                } else if event.source == .appCalendar {
                    Button(role: .destructive) {
                        enqueueCalendarDeletes([event])
                    } label: {
                        Label(EventRowContextMenuPrewarmer.deleteTitle, systemImage: "trash")
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    @ViewBuilder
    private var statusBanners: some View {
        if shouldShowCalendarAccessBanner {
            calendarAccessBanner
        }

        if viewModel.canRestoreIgnoredImportedEvents {
            restoreIgnoredBanner
        }
    }

    private func requestDelete(_ eventsToDelete: [CountdownEvent]) {
        let calendarBackedEvents = eventsToDelete.filter { $0.source == .importedCalendar || $0.source == .appCalendar }
        let localEvents = eventsToDelete.filter { $0.source == .local }

        viewModel.deleteEvents(localEvents)
        enqueueCalendarDeletes(calendarBackedEvents)
    }

    private func enqueueCalendarDeletes(_ events: [CountdownEvent]) {
        guard !events.isEmpty else { return }
        calendarDeleteQueue.append(contentsOf: events)
        presentNextCalendarDeleteIfNeeded()
    }

    private func completeCalendarDeletePrompt() {
        eventPendingCalendarDelete = nil
        DispatchQueue.main.async {
            presentNextCalendarDeleteIfNeeded()
        }
    }

    private func presentNextCalendarDeleteIfNeeded() {
        guard eventPendingCalendarDelete == nil, !calendarDeleteQueue.isEmpty else { return }
        eventPendingCalendarDelete = calendarDeleteQueue.removeFirst()
    }

    private var calendarAccessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "calendar_access.title"))
                    .font(.subheadline.weight(.semibold))
                Text(String(localized: "calendar_access.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(String(localized: "settings.open")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    private var filterBar: some View {
        Picker(String(localized: "filter.title"), selection: filterSelection) {
            ForEach(EventCategoryFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var restoreIgnoredBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.secondary)

            Text(String(localized: "restore_ignored_imported.banner"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Button {
                Task {
                    await viewModel.restoreIgnoredImportedEvents()
                }
            } label: {
                Label(String(localized: "restore_ignored_imported.short_action"), systemImage: "arrow.counterclockwise")
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}

private struct EventRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

private struct EventManagementSheet: View {
    let event: CountdownEvent
    let onIgnoreImported: () -> Void
    let onRequestCalendarDelete: () -> Void

    @State private var mode: EventSheetMode

    init(
        event: CountdownEvent,
        initialMode: EventSheetMode,
        onIgnoreImported: @escaping () -> Void,
        onRequestCalendarDelete: @escaping () -> Void
    ) {
        self.event = event
        self.onIgnoreImported = onIgnoreImported
        self.onRequestCalendarDelete = onRequestCalendarDelete
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        Group {
            switch mode {
            case .detail:
                EventDetailView(
                    event: event,
                    onEdit: {
                        mode = .edit
                    },
                    onIgnoreImported: onIgnoreImported,
                    onRequestCalendarDelete: onRequestCalendarDelete
                )
            case .edit:
                AddEventView(event: event)
            }
        }
    }
}

private enum EventSheetMode {
    case detail
    case edit
}

private enum EventSheet: Identifiable {
    case add
    case event(CountdownEvent, initialMode: EventSheetMode)
    case widgetGuide

    var id: String {
        switch self {
        case .add:
            return "add"
        case .event(let event, _):
            return "event-\(event.id.uuidString)"
        case .widgetGuide:
            return "widget-guide"
        }
    }
}

private struct WidgetSetupGuide: View {
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.tint)
                Text(String(localized: "widget.guide.title"))
                    .font(.title2.bold())
                Text(String(localized: "widget.guide.description"))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Label(String(localized: "widget.guide.step_one"), systemImage: "1.circle.fill")
                    Label(String(localized: "widget.guide.step_two"), systemImage: "2.circle.fill")
                    Label(String(localized: "widget.guide.step_three"), systemImage: "3.circle.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.primary)
                Spacer()
                Button(String(localized: "widget.guide.done")) {
                    onDone()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .navigationTitle(String(localized: "widget.guide.navigation"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct EventDetailView: View {
    let event: CountdownEvent
    let onEdit: () -> Void
    let onIgnoreImported: () -> Void
    let onRequestCalendarDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDistantCountdownRevealed = false
    @State private var isArrivalCelebrating = false
    @State private var didReplayArrivalManually = false
    @State private var distantRevealGeneration = 0
    @State private var arrivalAnimationGeneration = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    detailCountdownRow

                    VStack(spacing: 0) {
                        DetailInfoRow(
                            title: String(localized: "detail.category"),
                            value: event.category.displayName,
                            systemImage: event.category.symbolName,
                            imageColor: .teal
                        )
                        Divider().padding(.leading, 16)
                        DetailDateRow(
                            title: String(localized: "detail.date"),
                            primary: formattedDatePrimary,
                            secondary: formattedDateSecondary
                        )
                        Divider().padding(.leading, 16)
                        DetailInfoRow(
                            title: String(localized: "detail.source"),
                            value: sourceLabel,
                            systemImage: sourceSymbolName,
                            imageColor: .teal
                        )
                        Divider().padding(.leading, 16)
                        DetailInfoRow(
                            title: String(localized: "detail.sync_status"),
                            value: syncStatus
                        )
                        Divider().padding(.leading, 16)
                        DetailInfoRow(
                            title: String(localized: "recurrence.title"),
                            value: event.recurrence.displayName,
                            systemImage: "repeat",
                            imageColor: .teal
                        )
                        Divider().padding(.leading, 16)
                        DetailInfoRow(
                            title: String(localized: "detail.reminder"),
                            value: event.reminderLeadTime.displayName,
                            systemImage: "bell",
                            imageColor: .orange
                        )
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if let specialNumberMessage {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(specialNumberMessage)
                                    .font(.subheadline.weight(.medium))
                                Text(event.daysLaterLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                            .foregroundStyle(.teal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "detail.notes"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

                        Text(notesText)
                            .foregroundStyle(hasNotes ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(spacing: 0) {
                        Button {
                            onEdit()
                        } label: {
                            DetailActionRow(
                                title: String(localized: "edit.action"),
                                systemImage: "pencil",
                                tint: .teal
                            )
                        }
                        .buttonStyle(.plain)

                        if event.source == .importedCalendar {
                            Divider().padding(.leading, 16)
                            Button {
                                onIgnoreImported()
                            } label: {
                                DetailActionRow(
                                    title: String(localized: "ignore_imported.action"),
                                    systemImage: "eye.slash",
                                    tint: .secondary
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if event.source == .importedCalendar || event.source == .appCalendar {
                            Divider().padding(.leading, 16)
                            Button(role: .destructive) {
                                onRequestCalendarDelete()
                            } label: {
                                DetailActionRow(
                                    title: String(localized: "delete_imported.action"),
                                    systemImage: "trash",
                                    tint: .red
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.ok")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                triggerAutomaticArrivalIfNeeded()
            }
            .overlay {
                if isDistantCountdownRevealed {
                    DistantStarConvergenceOverlay(
                        exactDays: event.daysUntil,
                        reduceMotion: reduceMotion,
                        onDismiss: dismissDistantReveal
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
        }
    }

    private var detailCountdownRow: some View {
        EventRowView(
            event: event,
            countdownTextOverride: isArrivalCelebrating ? String(localized: "easter_egg.arrived") : nil,
            revealsExactCountdown: false
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .overlay {
            ArrivalCelebrationOverlay(
                category: event.category,
                isActive: isArrivalCelebrating,
                reduceMotion: reduceMotion
            )
            .allowsHitTesting(false)
        }
        .onLongPressGesture(minimumDuration: distantRevealEligible ? 1.5 : 1.0) {
            handleCountdownLongPress()
        }
        .accessibilityHint(countdownAccessibilityHint)
    }

    private var distantRevealEligible: Bool {
        CountdownEasterEggPolicy.canRevealDistantCountdown(daysUntil: event.daysUntil)
    }

    private var arrivalEligible: Bool {
        CountdownEasterEggPolicy.canCelebrateArrival(daysUntil: event.daysUntil)
    }

    private var countdownAccessibilityHint: Text {
        if distantRevealEligible {
            return Text(String(localized: "easter_egg.distant.hint"))
        }

        if arrivalEligible && !didReplayArrivalManually {
            return Text(String(localized: "easter_egg.arrival.replay_hint"))
        }

        return Text("")
    }

    private func handleCountdownLongPress() {
        if distantRevealEligible {
            revealDistantCountdown()
        } else if arrivalEligible && !didReplayArrivalManually {
            didReplayArrivalManually = true
            startArrivalCelebration()
        }
    }

    private func revealDistantCountdown() {
        distantRevealGeneration += 1
        let generation = distantRevealGeneration

        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.35)) {
            isDistantCountdownRevealed = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_600_000_000)
            guard generation == distantRevealGeneration else { return }
            dismissDistantReveal()
        }
    }

    private func dismissDistantReveal() {
        distantRevealGeneration += 1
        withAnimation(.easeOut(duration: 0.25)) {
            isDistantCountdownRevealed = false
        }
    }

    private func triggerAutomaticArrivalIfNeeded(now: Date = Date()) {
        guard arrivalEligible else { return }

        let token = CountdownEasterEggPolicy.arrivalDayToken(eventID: event.id, date: now)
        let key = "easterEgg.arrivalCelebrated.\(event.id.uuidString)"
        guard UserDefaults.standard.string(forKey: key) != token else { return }

        UserDefaults.standard.set(token, forKey: key)
        startArrivalCelebration()
    }

    private func startArrivalCelebration() {
        arrivalAnimationGeneration += 1
        let generation = arrivalAnimationGeneration

        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.72)) {
            isArrivalCelebrating = true
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard generation == arrivalAnimationGeneration else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                isArrivalCelebrating = false
            }
        }
    }

    private var hasNotes: Bool {
        event.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var specialNumberMessage: String? {
        let isChinese = Bundle.main.preferredLocalizations.first?.lowercased().hasPrefix("zh") == true

        switch CountdownSpecialNumber.match(daysUntil: event.daysUntil, isChinese: isChinese) {
        case .answer:
            return String(localized: "easter_egg.special.42")
        case .orbit:
            return String(localized: "easter_egg.special.365")
        case .heart:
            return String(localized: "easter_egg.special.520")
        case nil:
            return nil
        }
    }

    private var notesText: String {
        guard hasNotes, let notes = event.notes else {
            return String(localized: "detail.no_notes")
        }
        return notes
    }

    private var sourceSymbolName: String {
        switch event.source {
        case .local: return "iphone"
        case .appCalendar: return "calendar.badge.checkmark"
        case .importedCalendar: return "calendar"
        }
    }

    private var sourceLabel: String {
        switch event.source {
        case .local: return String(localized: "source.local")
        case .appCalendar: return String(localized: "source.app_calendar")
        case .importedCalendar: return String(localized: "source.imported_calendar")
        }
    }

    private var syncStatus: String {
        switch event.source {
        case .local:
            return String(localized: "detail.sync.local")
        case .appCalendar:
            return String(localized: "detail.sync.synced")
        case .importedCalendar:
            return String(localized: "detail.sync.imported")
        }
    }

    private var formattedDatePrimary: String {
        EventDateCalendar.formattedMonthDay(
            from: event.nextOccurrence,
            dateCalendar: event.dateCalendar
        )
    }

    private var formattedDateSecondary: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate(event.dateCalendar == .lunar ? "yMMMd" : "y")
        return formatter.string(from: event.nextOccurrence)
    }
}

private struct DetailInfoRow: View {
    let title: String
    let value: String
    var systemImage: String?
    var imageColor: Color = .secondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 92, alignment: .leading)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(imageColor)
                        .frame(width: 22)
                }

                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(minHeight: 54)
    }
}

private struct DetailActionRow: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 22)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

private struct DetailDateRow: View {
    let title: String
    let primary: String
    let secondary: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 92, alignment: .leading)

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.teal)
                    .frame(width: 22)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(primary)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: 62)
    }
}

private struct NightLetterView: View {
    var body: some View {
        Label(String(localized: "easter_egg.night_letter"), systemImage: "moon.stars")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .accessibilityLabel(String(localized: "easter_egg.night_letter"))
    }
}

private struct DistantStarConvergenceOverlay: View {
    let exactDays: Int
    let reduceMotion: Bool
    let onDismiss: () -> Void

    @State private var starsConverged = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.11, blue: 0.14),
                        Color(red: 0.055, green: 0.19, blue: 0.19),
                        Color(red: 0.035, green: 0.09, blue: 0.13)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(0..<32, id: \.self) { index in
                    Image(systemName: starSymbol(for: index))
                        .font(.system(size: starSize(for: index), weight: .medium))
                        .foregroundStyle(starColor(for: index))
                        .position(
                            x: starX(for: index, in: proxy.size),
                            y: starY(for: index, in: proxy.size)
                        )
                        .opacity(starsConverged ? 0.24 : 0.82)
                        .scaleEffect(starsConverged ? 0.58 : 1)
                        .animation(
                            reduceMotion
                                ? .easeInOut(duration: 0.2)
                                : .easeInOut(duration: 1.75).delay(Double(index % 8) * 0.035),
                            value: starsConverged
                        )
                }

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(exactDays)")
                            .font(.system(size: 58, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(String(localized: "countdown.day.unit"))
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Text(String(localized: "easter_egg.distant.message"))
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.82))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .opacity(starsConverged ? 1 : 0)
                .scaleEffect(starsConverged && !reduceMotion ? 1 : (reduceMotion ? 1 : 0.92))
                .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.5).delay(reduceMotion ? 0 : 1.15), value: starsConverged)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
            .onAppear {
                if reduceMotion {
                    starsConverged = true
                } else {
                    DispatchQueue.main.async {
                        starsConverged = true
                    }
                }
            }
        }
        .background(Color(red: 0.035, green: 0.11, blue: 0.14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text("\(exactDays) \(String(localized: "countdown.day.unit"))。\(String(localized: "easter_egg.distant.message"))")
        )
    }

    private func starX(for index: Int, in size: CGSize) -> CGFloat {
        if starsConverged && !reduceMotion {
            let angle = Double(index) / 32 * Double.pi * 2
            let radius = CGFloat(36 + (index % 5) * 13)
            return size.width / 2 + CGFloat(cos(angle)) * radius
        }

        return size.width * CGFloat(((index * 37) % 94) + 3) / 100
    }

    private func starY(for index: Int, in size: CGSize) -> CGFloat {
        if starsConverged && !reduceMotion {
            let angle = Double(index) / 32 * Double.pi * 2
            let radius = CGFloat(30 + (index % 6) * 12)
            return size.height / 2 + CGFloat(sin(angle)) * radius
        }

        return size.height * CGFloat(((index * 53) % 92) + 4) / 100
    }

    private func starSymbol(for index: Int) -> String {
        switch index % 3 {
        case 0: return "sparkle"
        case 1: return "star.fill"
        default: return "circle.fill"
        }
    }

    private func starSize(for index: Int) -> CGFloat {
        CGFloat(5 + (index % 5) * 2)
    }

    private func starColor(for index: Int) -> Color {
        switch index % 3 {
        case 0: return Color(red: 0.64, green: 0.87, blue: 0.82)
        case 1: return Color(red: 0.72, green: 0.79, blue: 0.92)
        default: return Color(red: 0.92, green: 0.82, blue: 0.67)
        }
    }
}

private struct ArrivalCelebrationOverlay: View {
    let category: EventCategory
    let isActive: Bool
    let reduceMotion: Bool

    private let particleOffsets: [CGSize] = [
        CGSize(width: -104, height: -34),
        CGSize(width: -68, height: 38),
        CGSize(width: -24, height: -48),
        CGSize(width: 28, height: 42),
        CGSize(width: 72, height: -38),
        CGSize(width: 108, height: 28)
    ]

    var body: some View {
        ZStack {
            ForEach(particleOffsets.indices, id: \.self) { index in
                Image(systemName: particleSymbol)
                    .font(.system(size: index.isMultiple(of: 2) ? 14 : 11, weight: .semibold))
                    .foregroundStyle(particleColor.opacity(0.85))
                    .scaleEffect(isActive ? 1 : 0.35)
                    .opacity(isActive ? 1 : 0)
                    .offset(isActive && !reduceMotion ? particleOffsets[index] : .zero)
                    .animation(
                        .easeOut(duration: reduceMotion ? 0.2 : 0.9).delay(reduceMotion ? 0 : Double(index) * 0.04),
                        value: isActive
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private var particleSymbol: String {
        switch category {
        case .birthday: return "balloon.fill"
        case .anniversary: return "heart.fill"
        case .custom: return "star.fill"
        }
    }

    private var particleColor: Color {
        switch category {
        case .birthday: return .orange
        case .anniversary: return .pink
        case .custom: return .teal
        }
    }
}

private struct TodaySectionHeader: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(.orange)
            Text(String(localized: "today.section.title"))
            Spacer()
            Text(
                String.localizedStringWithFormat(
                    NSLocalizedString("today.section.count", comment: "Number of events happening today"),
                    count
                )
            )
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }
}

private enum EventRowContextMenuPrewarmer {
    static let editTitle = String(localized: "edit.action")
    static let ignoreTitle = String(localized: "ignore_imported.action")
    static let deleteTitle = String(localized: "delete_imported.action")

    @MainActor
    static func prewarm() {
        let editImage = UIImage(systemName: "pencil")
        let ignoreImage = UIImage(systemName: "eye.slash")
        let deleteImage = UIImage(systemName: "trash")

        let actions = [
            UIAction(title: editTitle, image: editImage) { _ in },
            UIAction(title: ignoreTitle, image: ignoreImage) { _ in },
            UIAction(title: deleteTitle, image: deleteImage, attributes: .destructive) { _ in }
        ]

        _ = UIMenu(children: actions)
    }
}

private enum EventCategoryFilter: Hashable, Identifiable, CaseIterable {
    case all
    case birthday
    case anniversary
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .all: return String(localized: "filter.all")
        case .birthday: return EventCategory.birthday.displayName
        case .anniversary: return EventCategory.anniversary.displayName
        case .custom: return EventCategory.custom.displayName
        }
    }

    var category: EventCategory? {
        switch self {
        case .all: return nil
        case .birthday: return .birthday
        case .anniversary: return .anniversary
        case .custom: return .custom
        }
    }

    var previous: Self {
        guard let index = Self.allCases.firstIndex(of: self), index > Self.allCases.startIndex else {
            return self
        }

        return Self.allCases[Self.allCases.index(before: index)]
    }

    var next: Self {
        guard
            let index = Self.allCases.firstIndex(of: self),
            index < Self.allCases.index(before: Self.allCases.endIndex)
        else {
            return self
        }

        return Self.allCases[Self.allCases.index(after: index)]
    }

    func navigationDirection(to newValue: Self) -> Int {
        guard
            let oldIndex = Self.allCases.firstIndex(of: self),
            let newIndex = Self.allCases.firstIndex(of: newValue)
        else {
            return 1
        }

        return newIndex >= oldIndex ? 1 : -1
    }
}

struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text(String(localized: "empty.no_days.title"))
                .font(.title3.bold())

            Text(String(localized: "empty.no_days.description"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(String(localized: "event.add_day")) {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
