import SwiftUI

struct LessonListView: View {
    @StateObject private var viewModel = LessonListViewModel()
    var onLogout: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading lessons...")
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
                    List(viewModel.bookings) { booking in
                        NavigationLink(destination: WhiteboardView(booking: booking)) {
                            BookingRowView(booking: booking)
                        }
                    }
                }
            }
            .navigationTitle("My Lessons")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        KeychainService.delete()
                        onLogout()
                    }
                }
            }
        }
        .task {
            await viewModel.loadBookings()
        }
    }
}

struct BookingRowView: View {
    let booking: Booking

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(booking.studentName)
                    .font(.headline)
                Spacer()
                StatusBadge(status: booking.status)
            }
            Text(booking.subject)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Self.dateFormatter.string(from: booking.startTime))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String

    var color: Color {
        switch status {
        case "CONFIRMED": return .green
        case "PENDING": return .orange
        case "CANCELLED", "REJECTED": return .red
        case "COMPLETED": return .blue
        default: return .gray
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
