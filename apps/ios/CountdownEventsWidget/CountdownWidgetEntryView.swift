import SwiftUI
import WidgetKit

struct CountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(event: entry.events.first, theme: entry.theme)
            case .systemMedium:
                MediumWidgetView(events: entry.events, theme: entry.theme)
            case .systemLarge:
                LargeWidgetView(events: entry.events, theme: entry.theme)
            case .accessoryInline:
                AccessoryInlineWidgetView(event: entry.events.first)
            case .accessoryCircular:
                AccessoryCircularWidgetView(event: entry.events.first)
            case .accessoryRectangular:
                AccessoryRectangularWidgetView(event: entry.events.first)
            default:
                SmallWidgetView(event: entry.events.first, theme: entry.theme)
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Small Widget (1 event)

private struct SmallWidgetView: View {
    let event: CountdownEvent?
    let theme: CountdownWidgetTheme

    var body: some View {
        if let event {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: event.category.symbolName)
                        .font(.system(size: 11, weight: .bold))
                    Text(event.category.displayName)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(String(localized: "widget.brand.short"))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .opacity(0.76)
                }

                Spacer(minLength: 7)

                Text(event.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
                    .privacySensitive()

                Spacer(minLength: 4)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(event.countdownBadgeText)
                        .font(.system(size: event.countdownBadgeText.count > 2 ? 31 : 38, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(widgetCountdownUnit(event))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .opacity(0.82)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }

                Text(eventDateString(event))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.74)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(13)
            .background {
                EventCardBackground(event: event, theme: theme, cornerRadius: 22)
            }
            .padding(9)
            .widgetURL(widgetEventURL(event))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(widgetAccessibilityLabel(event))
            .containerBackground(for: .widget) {
                CalendarWidgetBackground(theme: theme)
            }
        } else {
            EmptyWidgetView()
                .widgetURL(widgetAddURL)
                .containerBackground(for: .widget) {
                    CalendarWidgetBackground(theme: theme)
                }
        }
    }
}

// MARK: - Medium Widget (up to 3 events)

private struct MediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let events: [CountdownEvent]
    let theme: CountdownWidgetTheme

    var body: some View {
        Group {
            if let primary = events.first {
                HStack(spacing: 11) {
                    Link(destination: widgetEventURL(primary)) {
                        WidgetHeroCard(event: primary, theme: theme)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(String(localized: "widget.brand.short"))
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(1.1)
                                .foregroundStyle(brandTeal)
                            Text(String(localized: "widget.upcoming"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(widgetSecondaryText(for: colorScheme))
                            Spacer()
                            Text(String.localizedStringWithFormat(
                                NSLocalizedString("widget.event_count", comment: "Number of events in the widget"),
                                events.prefix(3).count
                            ))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(widgetSecondaryText(for: colorScheme))
                        }
                        ForEach(events.dropFirst().prefix(2), id: \.id) { event in
                            Link(destination: widgetEventURL(event)) {
                                WidgetCompactEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                        if events.count == 1 {
                            Spacer()
                            Text(String(localized: "widget.next_important_day"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(widgetSecondaryText(for: colorScheme))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                EmptyWidgetView()
                    .widgetURL(widgetAddURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .containerBackground(for: .widget) {
            CalendarWidgetBackground(theme: theme)
        }
    }
}

private struct WidgetHeroCard: View {
    let event: CountdownEvent
    let theme: CountdownWidgetTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: event.category.symbolName)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text(String(localized: "widget.next"))
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .opacity(0.68)
            }
            Spacer(minLength: 0)
            Text(event.countdownBadgeText)
                .font(.system(size: event.countdownBadgeText.count > 2 ? 26 : 31, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(widgetCountdownUnit(event))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .opacity(0.78)
            Text(event.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .privacySensitive()
        }
        .foregroundStyle(.white)
        .padding(11)
        .frame(width: 106, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .leading)
        .background {
            EventCardBackground(event: event, theme: theme, cornerRadius: 20)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(event))
    }
}

private struct WidgetCompactEventRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let event: CountdownEvent

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: event.category.symbolName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(urgencyColor(event))
                .frame(width: 18, height: 18)
                .background(urgencyColor(event).opacity(colorScheme == .dark ? 0.20 : 0.11), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(widgetPrimaryText(for: colorScheme))
                    .lineLimit(1)
                    .privacySensitive()
                Text(eventDateString(event, includesGregorianForLunar: false))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(widgetSecondaryText(for: colorScheme))
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Text(event.countdownBadgeText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(urgencyColor(event))
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(widgetSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(widgetBorder(for: colorScheme), lineWidth: 0.6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(event))
    }
}

// MARK: - Large Widget

private struct LargeWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let events: [CountdownEvent]
    let theme: CountdownWidgetTheme

    var body: some View {
        Group {
            if let primary = events.first {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "widget.brand.name"))
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(brandTeal)
                            Text(String(localized: "widget.large.subtitle"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(widgetSecondaryText(for: colorScheme))
                        }
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(brandTeal)
                    }

                    Link(destination: widgetEventURL(primary)) {
                        LargePrimaryEventCard(event: primary, theme: theme)
                    }
                    .buttonStyle(.plain)

                    Text(String(localized: "widget.more_events"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(widgetSecondaryText(for: colorScheme))

                    VStack(spacing: 7) {
                        ForEach(events.dropFirst().prefix(3), id: \.id) { event in
                            Link(destination: widgetEventURL(event)) {
                                LargeEventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if events.count == 1 {
                        Spacer()
                        Text(String(localized: "widget.next_important_day"))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(widgetSecondaryText(for: colorScheme))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                }
            } else {
                EmptyWidgetView()
                    .widgetURL(widgetAddURL)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            CalendarWidgetBackground(theme: theme)
        }
    }
}

private struct LargePrimaryEventCard: View {
    let event: CountdownEvent
    let theme: CountdownWidgetTheme

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label(event.category.displayName, systemImage: event.category.symbolName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .opacity(0.84)
                Text(event.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .privacySensitive()
                Text(eventDateString(event))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .opacity(0.72)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text(event.countdownBadgeText)
                    .font(.system(size: event.countdownBadgeText.count > 2 ? 38 : 48, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(widgetCountdownUnit(event))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .opacity(0.80)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background {
            EventCardBackground(event: event, theme: theme, cornerRadius: 22)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(event))
    }
}

private struct LargeEventRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let event: CountdownEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.category.symbolName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(urgencyColor(event))
                .frame(width: 26, height: 26)
                .background(urgencyColor(event).opacity(colorScheme == .dark ? 0.20 : 0.11), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(widgetPrimaryText(for: colorScheme))
                    .lineLimit(1)
                    .privacySensitive()
                Text(eventDateString(event))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(widgetSecondaryText(for: colorScheme))
            }
            Spacer()
            Text(event.daysLaterLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(urgencyColor(event))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(widgetSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(widgetBorder(for: colorScheme), lineWidth: 0.6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilityLabel(event))
    }
}

// MARK: - Lock Screen Widgets

private struct AccessoryInlineWidgetView: View {
    let event: CountdownEvent?

    var body: some View {
        Group {
            if let event {
                Label("\(event.title) · \(event.daysLaterLabel)", systemImage: event.category.symbolName)
                    .widgetURL(widgetEventURL(event))
                    .accessibilityLabel(widgetAccessibilityLabel(event))
            } else {
                Label(String(localized: "widget.empty.short"), systemImage: "calendar.badge.plus")
                    .widgetURL(widgetAddURL)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct AccessoryCircularWidgetView: View {
    let event: CountdownEvent?

    var body: some View {
        Group {
            if let event {
                VStack(spacing: 0) {
                        Image(systemName: event.category.symbolName)
                            .font(.system(size: 10, weight: .bold))
                        Text(event.countdownBadgeText)
                            .font(.system(size: event.countdownBadgeText.count > 2 ? 14 : 20, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                        if event.shouldShowCountdownUnit {
                            Text(event.daysLaterUnitLabel)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                        }
                    }
                    .widgetURL(widgetEventURL(event))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(widgetAccessibilityLabel(event))
            } else {
                Image(systemName: "calendar.badge.plus")
                    .widgetURL(widgetAddURL)
                    .accessibilityLabel(String(localized: "widget.empty.accessibility"))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct AccessoryRectangularWidgetView: View {
    let event: CountdownEvent?

    var body: some View {
        Group {
            if let event {
                HStack(spacing: 8) {
                    Image(systemName: event.category.symbolName)
                        .font(.system(size: 18, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.headline)
                            .lineLimit(1)
                            .privacySensitive()
                        Text("\(eventDateString(event)) · \(event.daysLaterLabel)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .widgetURL(widgetEventURL(event))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(widgetAccessibilityLabel(event))
            } else {
                Label(String(localized: "widget.empty.open_to_add"), systemImage: "calendar.badge.plus")
                    .widgetURL(widgetAddURL)
                    .accessibilityLabel(String(localized: "widget.empty.accessibility"))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct EmptyWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(widgetSecondaryText(for: colorScheme))
            Text(String(localized: "widget.empty.title"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(widgetPrimaryText(for: colorScheme))
            Text(String(localized: "widget.empty.open_to_add"))
                .font(.caption2)
                .foregroundStyle(widgetSecondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "widget.empty.accessibility"))
    }
}

private struct EventCardBackground: View {
    let event: CountdownEvent
    let theme: CountdownWidgetTheme
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(primaryCardColor(event, theme: theme))

            LinearGradient(
                colors: [.white.opacity(0.18), .clear, .black.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 86, height: 86)
                .offset(x: 51, y: -48)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 0.8)
        }
    }
}

private struct CalendarWidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: CountdownWidgetTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(brandTeal.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(width: 142, height: 142)
                .blur(radius: 30)
                .offset(x: 80, y: -66)

            Circle()
                .fill(brandIndigo.opacity(colorScheme == .dark ? 0.10 : 0.07))
                .frame(width: 128, height: 128)
                .blur(radius: 34)
                .offset(x: -88, y: 74)
        }
    }

    private var backgroundColors: [Color] {
        if theme == .midnight {
            return [
                Color(red: 0.08, green: 0.09, blue: 0.18),
                Color(red: 0.025, green: 0.035, blue: 0.075)
            ]
        }

        if theme == .minimal {
            return colorScheme == .dark
                ? [Color(red: 0.11, green: 0.11, blue: 0.12), Color(red: 0.055, green: 0.055, blue: 0.06)]
                : [Color(red: 0.985, green: 0.985, blue: 0.99), Color(red: 0.95, green: 0.95, blue: 0.965)]
        }

        if colorScheme == .dark {
            return [
                Color(red: 0.075, green: 0.095, blue: 0.12),
                Color(red: 0.045, green: 0.06, blue: 0.08)
            ]
        }

        return [
            Color(red: 0.98, green: 0.985, blue: 1.00),
            Color(red: 0.93, green: 0.97, blue: 0.97)
        ]
    }
}

// MARK: - Helpers

private let brandTeal = Color(red: 0.03, green: 0.62, blue: 0.53)
private let brandIndigo = Color(red: 0.36, green: 0.38, blue: 0.76)

private let widgetAddURL = URL(string: "until://add")!

private func widgetEventURL(_ event: CountdownEvent) -> URL {
    URL(string: "until://event/\(event.id.uuidString)")!
}

private func primaryCardColor(_ event: CountdownEvent, theme: CountdownWidgetTheme) -> Color {
    switch theme {
    case .colorful:
        return urgencyColor(event)
    case .minimal:
        return brandIndigo
    case .midnight:
        return Color(red: 0.24, green: 0.27, blue: 0.62)
    }
}

private func widgetCountdownUnit(_ event: CountdownEvent) -> String {
    switch event.daysUntil {
    case ..<0:
        return String(localized: "widget.status.tap_to_update")
    case 0:
        return String(localized: "widget.status.happening_now")
    case 1...2:
        return String(localized: "widget.status.coming_soon")
    default:
        return event.daysLaterUnitLabel
    }
}

private func widgetAccessibilityLabel(_ event: CountdownEvent) -> String {
    String.localizedStringWithFormat(
        NSLocalizedString("widget.event.accessibility", comment: "Accessible widget event summary"),
        event.title,
        event.daysLaterLabel,
        eventDateString(event)
    )
}

private func widgetSurface(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color.white.opacity(0.075)
        : Color.white.opacity(0.72)
}

private func widgetBorder(for colorScheme: ColorScheme) -> Color {
    (colorScheme == .dark ? Color.white : Color.black)
        .opacity(colorScheme == .dark ? 0.10 : 0.055)
}

private func widgetPrimaryText(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color(red: 0.96, green: 0.96, blue: 0.96)
        : Color(red: 0.08, green: 0.08, blue: 0.08)
}

private func widgetSecondaryText(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color(red: 0.66, green: 0.66, blue: 0.69)
        : Color(red: 0.36, green: 0.36, blue: 0.38)
}

private func widgetTertiaryText(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color(red: 0.48, green: 0.48, blue: 0.50)
        : Color(red: 0.56, green: 0.56, blue: 0.58)
}

private func widgetDividerColor(for colorScheme: ColorScheme) -> Color {
    (colorScheme == .dark ? Color.white : Color.black)
        .opacity(colorScheme == .dark ? 0.12 : 0.08)
}

private func urgencyColor(_ event: CountdownEvent) -> Color {
    switch event.urgency {
    case .today: return Color(red: 0.84, green: 0.25, blue: 0.42)
    case .soon: return Color(red: 0.91, green: 0.48, blue: 0.16)
    case .upcoming: return Color(red: 0.34, green: 0.43, blue: 0.80)
    case .distant: return Color(red: 0.10, green: 0.58, blue: 0.49)
    }
}

private func eventDateString(_ event: CountdownEvent, includesGregorianForLunar: Bool = true) -> String {
    if event.dateCalendar == .lunar && !includesGregorianForLunar {
        return EventDateCalendar.formattedLunarMonthDay(from: event.nextOccurrence)
    }

    return EventDateCalendar.formattedDisplayDate(
        from: event.nextOccurrence,
        dateCalendar: event.dateCalendar
    )
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    CountdownEventsWidget()
} timeline: {
    let calendar = Calendar.current
    CountdownWidgetEntry(date: Date(), events: [
        CountdownEvent(
            title: String(localized: "preview.mom_birthday"),
            nextOccurrence: calendar.date(byAdding: .day, value: 3, to: Date())!,
            originalDate: Date(), category: .birthday),
        CountdownEvent(
            title: String(localized: "preview.wedding_anniversary"),
            nextOccurrence: calendar.date(byAdding: .day, value: 20, to: Date())!,
            originalDate: Date(), category: .anniversary),
        CountdownEvent(
            title: String(localized: "preview.team_dinner"),
            nextOccurrence: calendar.date(byAdding: .day, value: 45, to: Date())!,
            originalDate: Date(), category: .custom)
    ], theme: .colorful)
}
