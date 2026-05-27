import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

enum Theme {
    // Backgrounds
    static let bg             = Color(hex: "FAFAF8")
    static let surface        = Color(hex: "F5F4F0")
    static let card           = Color(hex: "FFFFFF")
    static let border         = Color(hex: "EAE7E2")

    // Text
    static let textPrimary    = Color(hex: "1C1917")
    static let textSecondary  = Color(hex: "57534E")
    static let textTertiary   = Color(hex: "A8A29E")

    // Accent — Academathon green
    static let accent         = Color(hex: "008037")
    static let accentDark     = Color(hex: "006b2e")
    static let accentSubtle   = Color(hex: "ECFDF5")
    static let accentLight    = Color(hex: "52B788")

    // Radius
    static let radiusSm:  CGFloat = 6
    static let radiusMd:  CGFloat = 10
    static let radiusLg:  CGFloat = 14
    static let radiusXl:  CGFloat = 18
}
