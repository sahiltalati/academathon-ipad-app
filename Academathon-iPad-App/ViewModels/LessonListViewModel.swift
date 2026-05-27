import Foundation

@MainActor
class LessonListViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionExpired = false

    private let lessonService = LessonService()

    func loadBookings() async {
        guard let token = KeychainService.load() else {
            sessionExpired = true
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            bookings = try await lessonService.fetchBookings(token: token)
        } catch LessonError.unauthorized {
            KeychainService.delete()
            sessionExpired = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
