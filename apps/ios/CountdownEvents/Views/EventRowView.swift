import SwiftUI

struct EventRowView: View {
    let event: CountdownEvent
    let countdownTextOverride: String?
    let revealsExactCountdown: Bool

    init(
        event: CountdownEvent,
        countdownTextOverride: String? = nil,
        revealsExactCountdown: Bool = false
    ) {
        self.event = event
        self.countdownTextOverride = countdownTextOverride
        self.revealsExactCountdown = revealsExactCountdown
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: event.category.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(urgencyColor)
            }

            // Title + date
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: sourceSymbolName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(sourceColor)
                        .accessibilityLabel(sourceAccessibilityLabel)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Countdown badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(displayedCountdownText)
                    .font(.system(size: countdownFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(urgencyColor)
                    .minimumScaleFactor(0.7)
                if shouldShowCountdownUnit {
                    Text(event.daysLaterUnitLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minWidth: 62, alignment: .trailing)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(urgencyColor.opacity(0.08))
            }
        }
        .padding(.vertical, 4)
    }

    private var displayedCountdownText: String {
        if let countdownTextOverride {
            return countdownTextOverride
        }

        if revealsExactCountdown {
            return "\(event.daysUntil)"
        }

        return event.countdownBadgeText
    }

    private var shouldShowCountdownUnit: Bool {
        guard countdownTextOverride == nil else { return false }
        return revealsExactCountdown ? event.daysUntil > 2 : event.shouldShowCountdownUnit
    }

    private var countdownFontSize: CGFloat {
        if displayedCountdownText.count >= 4 && displayedCountdownText.rangeOfCharacter(from: .decimalDigits) == nil {
            return 14
        }

        if displayedCountdownText.count > 5 {
            return 18
        }

        return 28
    }

    private var urgencyColor: Color {
        switch event.urgency {
        case .today: return Color(red: 0.70, green: 0.24, blue: 0.35)
        case .soon: return Color(red: 0.72, green: 0.43, blue: 0.16)
        case .upcoming: return Color(red: 0.26, green: 0.52, blue: 0.56)
        case .distant: return Color(red: 0.34, green: 0.55, blue: 0.38)
        }
    }

    private var sourceSymbolName: String {
        switch event.source {
        case .local:
            return "iphone"
        case .appCalendar:
            return "calendar.badge.checkmark"
        case .importedCalendar:
            return "calendar"
        }
    }

    private var sourceColor: Color {
        switch event.source {
        case .local:
            return .secondary
        case .appCalendar:
            return Color(red: 0.26, green: 0.52, blue: 0.56)
        case .importedCalendar:
            return Color(red: 0.72, green: 0.43, blue: 0.16)
        }
    }

    private var sourceAccessibilityLabel: Text {
        switch event.source {
        case .local:
            return Text(String(localized: "source.local"))
        case .appCalendar:
            return Text(String(localized: "source.app_calendar"))
        case .importedCalendar:
            return Text(String(localized: "source.imported_calendar"))
        }
    }

    private var formattedDate: String {
        EventDateCalendar.formattedDisplayDate(
            from: event.nextOccurrence,
            dateCalendar: event.dateCalendar
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let sample = CountdownEvent(
        title: String(localized: "preview.mom_birthday"),
        nextOccurrence: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
        originalDate: Date(),
        category: .birthday
    )
    EventRowView(event: sample)
        .padding()
}
