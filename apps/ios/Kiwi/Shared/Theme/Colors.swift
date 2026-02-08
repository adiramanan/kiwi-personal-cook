import SwiftUI

extension Color {
    /// Primary green - fresh, food-inspired
    static let kiwiPrimary = Color("KiwiPrimary", bundle: nil)

    /// Secondary warm orange for accents
    static let kiwiAccent = Color("KiwiAccent", bundle: nil)

    /// Destructive red
    static let kiwiDestructive = Color("KiwiDestructive", bundle: nil)

    /// Card background
    static let kiwiCardBackground = Color("KiwiCardBackground", bundle: nil)

    /// Subtle text
    static let kiwiSecondaryText = Color("KiwiSecondaryText", bundle: nil)
}

// MARK: - Fallback colors when asset catalog is not available
extension Color {
    /// Primary green fallback: #4CAF50
    static let kiwiGreen = Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255)

    /// Accent orange fallback: #FF9800
    static let kiwiOrange = Color(red: 255 / 255, green: 152 / 255, blue: 0 / 255)
}

extension ShapeStyle where Self == Color {
    static var kiwiPrimaryStyle: Color { .kiwiGreen }
    static var kiwiAccentStyle: Color { .kiwiOrange }
}
