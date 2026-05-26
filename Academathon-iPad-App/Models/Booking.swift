import Foundation

struct Booking: Codable, Identifiable {
    let id: Int
    let studentName: String
    let tutorName: String
    let subject: String
    let startTime: Date
    let endTime: Date
    let status: String
    let paymentStatus: String
    let hourlyRate: Double?
    let createdAt: Date
}
