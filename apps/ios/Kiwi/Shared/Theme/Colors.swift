import SwiftUI

extension Color {
    static let kiwiPrimary = Color("KiwiPrimary", bundle: .main)
    static let kiwiAccent = Color("KiwiAccent", bundle: .main)

    // Fallbacks when asset catalog colors aren't configured yet
    static let kiwiGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
    static let kiwiOrange = Color(red: 255/255, green: 152/255, blue: 0/255)
    static let kiwiDestructive = Color.red
}

extension ShapeStyle where Self == Color {
    static var kiwiGreen: Color { .kiwiGreen }
    static var kiwiOrange: Color { .kiwiOrange }
}
