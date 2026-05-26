import Foundation

@MainActor
class LessonListViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let lessonService = LessonService()

    func loadBookings() async {
        guard let token = KeychainService.load() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bookings = try await lessonService.fetchBookings(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
