import SwiftUI

struct LessonListView: View {
    @StateObject private var viewModel = LessonListViewModel()
    var onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading lessons...")
                            .tint(Theme.accent)
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Couldn't load lessons",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else if viewModel.bookings.isEmpty {
                        ContentUnavailableView(
                            "No lessons",
                            systemImage: "calendar.badge.minus",
                            description: Text("You have no bookings yet.")
                        )
                    } else {
                        List {
                            Section {
                                SummaryHeaderView(bookings: viewModel.bookings)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }

                            Section {
                                ForEach(viewModel.bookings) { booking in
                                    NavigationLink(destination: WhiteboardView(booking: booking)) {
                                        BookingCardView(booking: booking)
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("My Lessons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        KeychainService.delete()
                        onLogout()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .task {
            await viewModel.loadBookings()
        }
        .onChange(of: viewModel.sessionExpired) { _, expired in
            if expired { onLogout() }
        }
    }
}

// MARK: - Summary Header

struct SummaryHeaderView: View {
    let bookings: [Booking]

    var upcomingCount: Int {
        bookings.filter { ["CONFIRMED", "SCHEDULED", "PENDING"].contains($0.status) }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            SummaryChip(value: "\(bookings.count)", label: "Total Lessons", color: Theme.accent)
            SummaryChip(value: "\(upcomingCount)", label: "Upcoming", color: Theme.accentLight)
        }
    }
}

struct SummaryChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Booking Card

struct BookingCardView: View {
    let booking: Booking

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(StatusBadge.color(for: booking.status))
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(booking.tutorName ?? "Unknown Tutor")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(booking.subject ?? "No subject")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: booking.status)
                }

                Divider()
                    .background(Theme.border)

                HStack {
                    Label(Self.dateFormatter.string(from: booking.startTime), systemImage: "calendar")
                    Spacer()
                    Label(Self.timeFormatter.string(from: booking.startTime), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            }
            .padding(14)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLg)
                .stroke(Theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    static func color(for status: String) -> Color {
        switch status {
        case "CONFIRMED", "SCHEDULED": return Theme.accent
        case "PENDING": return Color(hex: "D97706")
        case "CANCELLED", "REJECTED": return Color(hex: "DC2626")
        case "COMPLETED": return Theme.textSecondary
        default: return Theme.textTertiary
        }
    }

    var color: Color { Self.color(for: status) }

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
    }
}
